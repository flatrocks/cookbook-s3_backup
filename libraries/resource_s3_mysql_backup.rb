require File.join(File.dirname(__FILE__), 'provider_s3_mysql_backup')

class Chef
  class Resource
    class S3MysqlBackup < Chef::Resource::S3BackupBase

      def initialize(name, run_context = nil)
        super
        @mysql_user = name

        @resource_name = :s3_mysql_backup
        @provider = Chef::Provider::S3Backup::MysqlBackup

        def mysql_connection(arg = nil)
          set_or_return :mysql_connection, arg, kind_of: Hash, required: true
        end
        def mysql_user(arg = nil)
          set_or_return :mysql_user, arg, kind_of: String, required: true
        end
        def mysql_password(arg = nil)
          set_or_return :mysql_password, arg, kind_of: String, default: nil
        end
      end

    end
  end
end

