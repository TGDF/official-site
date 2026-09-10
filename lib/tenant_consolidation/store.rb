# frozen_string_literal: true

module TenantConsolidation
  # Where one run's files live — the dump, and the id map the import writes beside it.
  # A run is a directory: a local path, or `s3://<bucket>/consolidation/<group>/<time>`
  # in the application's own bucket, so the location a task prints can be pasted
  # straight into `aws s3 cp --recursive` to bring the run home.
  #
  # The S3 side is held to `consolidation/`: `uploads/` is what Phase 5.5 deletes, and
  # the rest of the bucket is ActiveStorage's. Objects are written private — the
  # buckets carry no policy and no public-access block, so an object is public exactly
  # when its own ACL says so.
  module Store
    S3_PREFIX = "consolidation/"

    class Invalid < StandardError; end

    module_function

    def open(location, s3_client: nil)
      if location.start_with?("s3://")
        S3.new(location, client: s3_client)
      else
        Local.new(location)
      end
    end

    # A fresh run location for `group`: in the bucket when the application stores its
    # files on S3, under tmp/ otherwise (development and test).
    def new_run(group, at: Time.current)
      stamp = at.utc.strftime("%Y%m%dT%H%M%SZ")
      if Settings.s3.enabled
        "s3://#{Settings.s3.bucket}/#{S3_PREFIX}#{group}/#{stamp}"
      else
        Rails.root.join("tmp", "consolidation", group, stamp).to_s
      end
    end

    class Local
      def initialize(path)
        @path = Pathname(path)
      end

      def write(name, content)
        @path.mkpath
        @path.join(name).write(content)
      end

      def read(name)
        @path.join(name).read
      end

      def to_s = @path.to_s
    end

    class S3
      def initialize(location, client: nil)
        @bucket, @prefix = location.delete_prefix("s3://").split("/", 2)
        @prefix = @prefix.to_s.delete_suffix("/")
        unless @bucket == Settings.s3.bucket
          raise Invalid, "#{location} is not in the application's bucket (#{Settings.s3.bucket})"
        end
        raise Invalid, "#{location} is outside #{S3_PREFIX}" unless "#{@prefix}/".start_with?(S3_PREFIX)

        @client = client || default_client
      end

      def write(name, content)
        @client.put_object(bucket: @bucket, key: key(name), body: content,
                           acl: "private", content_type: "application/json")
      end

      def read(name)
        @client.get_object(bucket: @bucket, key: key(name)).body.read
      end

      def to_s = "s3://#{@bucket}/#{@prefix}"

      private

      def key(name) = "#{@prefix}/#{name}"

      def default_client
        require "aws-sdk-s3"
        Aws::S3::Client.new(
          access_key_id: Settings.s3.access_key_id,
          secret_access_key: Settings.s3.secret_access_key,
          region: Settings.s3.region
        )
      end
    end
  end
end
