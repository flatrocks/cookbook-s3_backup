class Chef
  class Provider
    class S3Backup
      class Base < Chef::Provider::LWRPBase

        # DO NOT use_inline_resources if defined?(use_inline_resources) in the base class
        # Even thougn the chefspec tests pass, somehow this prevents the resources from actually being generated.
        # OK to use_inline_resources in each of the subclasses.

        def whyrun_supported?
          true
        end

        def user_home
          "/home/#{new_resource.user}"
        end

        def action_create
          recipe_eval do
            run_context.include_recipe 'ruby'
          end
          gem_package 'aws-sdk' # Required by script for s3 access

          user new_resource.user do
            home user_home
            manage_home true
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

          config_yml_content = {
            's3' => {
              'region' => new_resource.s3_region,
              'access_key_id' => new_resource.s3_access_key_id,
              'secret_access_key' => new_resource.s3_secret_access_key,
              'bucket' => new_resource.s3_bucket,
              'time_prefix' => new_resource.s3_time_prefix
            },
            'log' => {
              'ident' => new_resource.log_ident
            },
            'backup_groups' => new_resource.backup_groups
          }.to_yaml
          file ::File.join(user_home, "config.yml") do
            user new_resource.user
            group new_resource.user
            mode "400"
            content config_yml_content
            action :create
          end

        end

        def action_delete
          user_home = "/home/#{new_resource.user}"
          user new_resource.user do
            home user_home
            action :remove
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

          template ::File.join(user_home, "config.yml") do
            action :delete
          end
        end

      end
    end
  end
end