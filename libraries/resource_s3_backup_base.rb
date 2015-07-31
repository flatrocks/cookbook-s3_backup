class Chef
  class Resource
    class S3BackupBase < Chef::Resource

      def initialize(name, run_context = nil)
        super
        @action = :create
        @allowed_actions.push(:create, :delete)
        @user = name

        def user(arg = nil)
          set_or_return :user, arg, kind_of: String, required: true
        end
        def groups(arg = nil)
          set_or_return :groups, arg, kind_of: Array, default: []
        end

        def s3_region(arg = nil)
          set_or_return :s3_region, arg, kind_of: String, required: true
        end
        def s3_bucket(arg = nil)
          set_or_return :s3_bucket, arg, kind_of: String, required: true
        end
        def s3_access_key_id(arg = nil)
          set_or_return :s3_access_key_id, arg, kind_of: String, required: true
        end
        def s3_secret_access_key(arg = nil)
          set_or_return :s3_secret_access_key, arg, kind_of: String, required: true
        end
        def s3_time_prefix(arg = nil)
          set_or_return :s3_time_prefix, arg, kind_of: String, default: '%d-%b-%Y'
        end

        def log_ident(arg = nil)
          set_or_return :log_ident, arg, kind_of: [String, NilClass], required: false, default: resource_name.to_s
        end
        def log_success_message(arg = nil)
          set_or_return :log_success_message, arg, kind_of: [String, NilClass], default: nil
        end

        def cron(arg = nil)
          set_or_return :cron, arg, kind_of: Hash, default: Hash.new
        end

        def backup_groups(arg = nil)
          set_or_return :assets, arg, kind_of: Hash, default: Hash.new
        end
      end

    end
  end
end

