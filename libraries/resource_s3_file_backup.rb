require File.join(File.dirname(__FILE__), 'provider_s3_file_backup')

class Chef
  class Resource
    class S3FileBackup < Chef::Resource::S3BackupBase

      def initialize(name, run_context = nil)
        super
        @resource_name = :s3_file_backup
        @provider = Chef::Provider::S3Backup::FileBackup

      end
    end
  end
end

