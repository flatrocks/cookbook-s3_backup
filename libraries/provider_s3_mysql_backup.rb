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
            cookbook 's3_backup'
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
            cookbook 's3_backup'
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

          mysql_database_user new_resource.user do
            action :drop
          end

          template ::File.join(user_home, ".my.cnf") do
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

          super
        end

      end
    end
  end
end