class Chef
  class Provider
    class S3Backup
      class MysqlBackup < Chef::Provider::S3Backup::Base

        def action_create
          super

          mysql_database_user new_resource.user do
            connection new_resource.mysql_connection
            username new_resource.mysql_user
            password new_resource.mysql_password
          end
          mysql_database_user "#{new_resource.user} on *" do
            connection new_resource.mysql_connection
            username new_resource.mysql_user
            password new_resource.mysql_password
            privileges ['LOCK TABLES']
            action :grant
          end
          new_resource.assets.each do |asset|
            database = asset['item'].split.first
            mysql_database_user "#{new_resource.user} on #{database}" do
              connection new_resource.mysql_connection
              username new_resource.mysql_user
              password new_resource.mysql_password
              database_name database
              privileges [:select]
              action :grant
            end
          end

          template ::File.join(user_home, ".my.cnf") do
            source 'my.cnf.erb'
            user new_resource.user
            group new_resource.user
            mode "400"
            variables host: new_resource.mysql_connection[:host],
              username: new_resource.mysql_user,
              password: new_resource.mysql_password,
              port: new_resource.mysql_connection[:port],
              socket: new_resource.mysql_connection[:socket]
            action :create
          end

          cookbook_file ::File.join(user_home, "s3_mysql_backup.rb") do
            user new_resource.user
            group new_resource.user
            mode "500"
            action :create
          end

          cron "cron for #{new_resource.name} s3 mysql backup" do
            user new_resource.user
            command "ruby s3_mysql_backup.rb"
            new_resource.cron.each {|k,v| self.send(k, v) unless v.nil?}
            ignore_failure new_resource.cron.empty?
            action new_resource.cron.empty? ? :delete : :create
          end
        end

        def action_delete
          super

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

          cookbook_file ::File.join(user_home, "s3_mysql_backup.rb") do
            action :delete
          end

          template ::File.join(user_home, "config.yml") do
            action :delete
          end

          no_cron = new_resource.cron.nil? || new_resource.cron.empty?
          cron "cron for #{new_resource.name}" do
            user new_resource.user
            command "ruby s3_mysql_backup.rb"
            ignore_failure true
            action delete
          end
        end

      end # class FileBackup
    end
  end
end