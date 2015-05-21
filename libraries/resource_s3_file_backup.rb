require File.join(File.dirname(__FILE__), 'provider_s3_file_backup')

class Chef
  class Resource
    class S3FileBackup < Chef::Resource

      def initialize(name, run_context = nil)
        super
        @resource_name = :s3_file_backup
        @provider = Chef::Provider::S3Backup::FileBackup
        @action = :create
        @allowed_actions.push(:create, :delete)
        @user = name


        def user(arg = nil)
          set_or_return :user, arg, kind_of: String, required: true
        end
        def groups(arg = nil)
          set_or_return :groups, arg, kind_of: Array, default: []
        end

        def tar_flatten_path(arg = true)
          set_or_return :tar_flatten_path, arg, kind_of: [TrueClass, FalseClass], default: true
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
        def s3_key_prefix_format(arg = nil)
          set_or_return :s3_key_prefix_format, arg, kind_of: String, default: '%d-%b-%Y'
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

        def assets(arg = nil)
          set_or_return :assets, arg, kind_of: Array, default: []
        end

      end
    end
  end
end

