# frozen_string_literal: true

server('ec2-54-168-58-23.ap-northeast-1.compute.amazonaws.com', user: 'deploy', roles: %w[app db web])

set(:deploy_to, '/home/deploy/staging.tgdf.tw')
