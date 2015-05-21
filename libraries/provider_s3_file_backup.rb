class Chef
  class Provider
    class S3Backup
      class FileBackup < Chef::Provider::S3Backup::Base

        def action_create
          super

          cookbook_file ::File.join(user_home, "s3_file_backup.rb") do
            user new_resource.user
            group new_resource.user
            mode "500"
            action :create
          end

          cron "cron for #{new_resource.name} s3 file backup" do
            user new_resource.user
            command "ruby s3_file_backup.rb"
            new_resource.cron.each {|k,v| self.send(k, v) unless v.nil?}
            ignore_failure new_resource.cron.empty?
            action new_resource.cron.empty? ? :delete : :create
          end
        end

        def action_delete
          super

          cookbook_file ::File.join(user_home, "s3_file_backup.rb") do
            action :delete
          end

          cron "cron for #{new_resource.name}" do
            user new_resource.user
            command "ruby s3_file_backup.rb"
            ignore_failure true
            action delete
          end
        end

      end
    end
  end
end