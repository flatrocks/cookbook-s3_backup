class Chef
  class Provider
    class S3Backup
      class FileBackup < Chef::Provider::LWRPBase

        use_inline_resources if defined?(use_inline_resources)

        def whyrun_supported?
          true
        end

        action :create do

          recipe_eval do
            run_context.include_recipe 'ruby'
          end
          gem_package 'aws-sdk' # Required by script for s3 access

          user_home = "/home/#{new_resource.user}"
          user new_resource.user do
            home user_home
            action :create
          end

          new_resource.groups.each do |group|
            group "group #{group} appending user #{new_resource.user}" do
              group_name group
              append true
              members [new_resource.user]
              action :create
            end
          end

          directory ::File.join(user_home, "temp") do
            user new_resource.user
            group new_resource.user
            mode "700"
            action :create
          end

          cookbook_file ::File.join(user_home, "s3_file_backup.rb") do
            user new_resource.user
            group new_resource.user
            mode "500"
            action :create
          end

          config_yml_content = {
            'tar' => {
              'flatten_path' => new_resource.tar_flatten_path
            },
            's3' => {
              'region' => new_resource.s3_region,
              'access_key_id' => new_resource.s3_access_key_id,
              'secret_access_key' => new_resource.s3_secret_access_key,
              'bucket' => new_resource.s3_bucket,
              'key_prefix_format' => new_resource.s3_key_prefix_format
            },
            'log' => {
              'ident' => new_resource.log_ident,
              'success_message' => new_resource.log_success_message
            },
            'assets' => new_resource.assets
          }.to_yaml
          file ::File.join(user_home, "config.yml") do
            user new_resource.user
            group new_resource.user
            mode "400"
            content config_yml_content
            action :create
          end

          cron "cron for #{new_resource.name}" do
            user new_resource.user
            command "ruby s3_file_backup.rb"
            new_resource.cron.each {|k,v| self.send(k, v) unless v.nil?}
            ignore_failure new_resource.cron.empty?
            action new_resource.cron.empty? ? :delete : :create
          end
        end

        action :delete do

          user_home = "/home/#{new_resource.user}"
          user new_resource.user do
            home user_home
            action :delete
          end

          new_resource.groups.each do |group|
            group "group #{group} appending user #{new_resource.user}" do
              group_name group
              append true
              excluded_members [new_resource.user]
              ignore_failure true
              action :modify
            end
          end

          directory ::File.join(user_home, "temp") do
            action :delete
          end

          cookbook_file ::File.join(user_home, "s3_file_backup.rb") do
            action :delete
          end

          template ::File.join(user_home, "config.yml") do
            action :delete
          end

          no_cron = new_resource.cron.nil? || new_resource.cron.empty?
          cron "cron for #{new_resource.name}" do
            user new_resource.user
            command "ruby s3_file_backup.rb"
            ignore_failure true
            action delete
          end
        end

      end # class FileBackup
    end
  end
end