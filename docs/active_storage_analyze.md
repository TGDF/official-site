# ActiveStorage Blob Analysis

This document describes the deferred blob analysis setup for ActiveStorage.

## Overview

ActiveStorage automatically analyzes uploaded files to extract metadata (width, height for images). This runs as a background job immediately after upload, which can cause CPU contention on low-resource ECS Fargate tasks.

**Solution:** Disable automatic analysis and run it manually via rake task during low-traffic periods.

### Current Configuration

```ruby
# config/environments/beta.rb & production.rb
config.active_storage.analyzers = []
```

This disables the automatic `AnalyzeJob` that normally runs after each upload.

### Rake Task

```ruby
# lib/tasks/active_storage.rake
bin/rails active_storage:analyze_pending
```

Processes unanalyzed blobs one-by-one to avoid CPU spikes.

## Manual Usage

### Local Development

```bash
bin/rails active_storage:analyze_pending
```

### ECS Execute Command

```bash
aws ecs execute-command \
  --cluster <cluster-name> \
  --task <task-id> \
  --container web \
  --interactive \
  --command 'bin/rails active_storage:analyze_pending'
```

## EventBridge Scheduled Setup (Optional)

For automatic hourly analysis, configure AWS EventBridge to run the rake task.

### Step 1: Create IAM Role

Create a role that allows EventBridge to run ECS tasks. Use separate roles per environment for security.

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "events.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
```

**Permissions Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecs:RunTask"],
      "Resource": ["arn:aws:ecs:<region>:<account-id>:task-definition/<task-family>:*"]
    },
    {
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": [
        "arn:aws:iam::<account-id>:role/<ecs-task-execution-role>",
        "arn:aws:iam::<account-id>:role/<ecs-task-role>"
      ],
      "Condition": {
        "StringLike": {"iam:PassedToService": "ecs-tasks.amazonaws.com"}
      }
    }
  ]
}
```

**Create Role:**
```bash
aws iam create-role \
  --role-name <env>-eventbridge-ecs-role \
  --assume-role-policy-document file://trust-policy.json

aws iam put-role-policy \
  --role-name <env>-eventbridge-ecs-role \
  --policy-name ecs-run-task \
  --policy-document file://permissions-policy.json
```

### Step 2: Create EventBridge Rule

```bash
# Create hourly schedule
aws events put-rule \
  --name <env>-analyze-blobs \
  --schedule-expression "rate(1 hour)" \
  --state ENABLED

# Add ECS target
aws events put-targets \
  --rule <env>-analyze-blobs \
  --targets '[{
    "Id": "analyze-blobs-task",
    "Arn": "arn:aws:ecs:<region>:<account-id>:cluster/<cluster-name>",
    "RoleArn": "arn:aws:iam::<account-id>:role/<env>-eventbridge-ecs-role",
    "EcsParameters": {
      "TaskDefinitionArn": "arn:aws:ecs:<region>:<account-id>:task-definition/<task-family>",
      "TaskCount": 1,
      "LaunchType": "FARGATE",
      "NetworkConfiguration": {
        "awsvpcConfiguration": {
          "Subnets": ["<subnet-id>"],
          "SecurityGroups": ["<security-group-id>"],
          "AssignPublicIp": "ENABLED"
        }
      }
    },
    "Input": "{\"containerOverrides\":[{\"name\":\"web\",\"command\":[\"bin/rails\",\"active_storage:analyze_pending\"]}]}"
  }]'
```

### Step 3: Verify

Check scheduled rule:
```bash
aws events list-rules --name-prefix <env>-analyze
aws events list-targets-by-rule --rule <env>-analyze-blobs
```

Check task execution:
```bash
aws ecs list-tasks --cluster <cluster-name> --started-by events-rule/<env>-analyze-blobs
```

## Verification

1. Upload an image
2. Check blob metadata (should be empty initially):
   ```ruby
   ActiveStorage::Blob.last.metadata
   # => {}
   ```
3. Run analysis task
4. Check metadata again:
   ```ruby
   ActiveStorage::Blob.last.metadata
   # => {"identified"=>true, "width"=>800, "height"=>600, "analyzed"=>true}
   ```

## Troubleshooting

### Blobs not being analyzed

Check for unanalyzed blobs:
```ruby
ActiveStorage::Blob.where.not("metadata ? 'analyzed'").count
```

### Task fails to start

- Verify IAM role has correct permissions
- Check security group allows outbound traffic to S3
- Ensure task definition exists and is active

### Analysis errors

Check task logs in CloudWatch for specific error messages. Common issues:
- Missing libvips for image processing
- S3 access denied (check task role permissions)

## Rollback

To restore automatic analysis, remove the `analyzers = []` configuration:

```ruby
# Remove this line from beta.rb and production.rb
config.active_storage.analyzers = []
```
