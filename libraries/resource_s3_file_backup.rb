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
        @groups = []
        @tar_flatten_path = true
        @s3_key_prefix_format = '%d-%b-%Y'
        @log_ident = 's3_file_backup'
        @log_success_message = nil
        @cron = Hash.new
        @assets = Hash.new

        def user(arg = nil)
          set_or_return(
            :user,
            arg,
            kind_of: String,
            required: true
          )
        end
        def groups(arg = nil)
          set_or_return(
            :groups,
            arg,
            kind_of: Array,
            required: true
          )
        end

        def tar_flatten_path(arg = true)
          set_or_return(
            :tar_flatten_path,
            arg,
            kind_of: [TrueClass, FalseClass],
            required: false
          )
        end

        def s3_region(arg = nil)
          set_or_return(
            :s3_region,
            arg,
            kind_of: String,
            required: true
          )
        end
        def s3_bucket(arg = nil)
          set_or_return(
            :s3_bucket,
            arg,
            kind_of: String,
            required: true
          )
        end
        def s3_access_key_id(arg = nil)
          set_or_return(
            :s3_access_key_id,
            arg,
            kind_of: String,
            required: true
          )
        end
        def s3_secret_access_key(arg = nil)
          set_or_return(
            :s3_secret_access_key,
            arg,
            kind_of: String,
            required: true
          )
        end
        def s3_key_prefix_format(arg = nil)
          set_or_return(
            :s3_key_prefix_format,
            arg,
            kind_of: String,
            required: false
          )
        end

        def log_ident(arg = nil)
          set_or_return(
            :log_ident,
            arg,
            kind_of: [String, NilClass],
            required: false
          )
        end
        def log_success_message(arg = nil)
          set_or_return(
            :log_success_message,
            arg,
            kind_of: [String, NilClass],
            required: false
          )
        end

        def cron(arg = nil)
          set_or_return(
            :cron,
            arg,
            kind_of: Hash,
            required: false
          )
        end

        def assets(arg = nil)
          set_or_return(
            :assets,
            arg,
            kind_of: Hash,
            required: false
          )
        end

      end
    end
  end
end

