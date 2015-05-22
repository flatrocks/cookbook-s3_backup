# Cookbook Name::
# Recipe::
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# required service

mysql2_chef_gem 'default' # denote default version for this platform

connection = {username: 'root', password: 'root_pw', socket: '/var/run/mysql-default/mysqld.sock'}

mysql_service 'default' do
  socket connection[:socket]
  initial_root_password connection[:password]
  action [:create, :start]
end

mysql_database 'db1' do
  connection connection
  action :create
end
mysql_database 'db2' do
  connection connection
  action :create
end
# must use "db.table" form due to bug in database cookbook that fails to set database
mysql_database 'create db1.table1' do
  connection connection
  sql "CREATE TABLE IF NOT EXISTS db2.table1 (id INT);"
  action [:query]
end
mysql_database 'create db1.table2' do
  connection connection
  sql "CREATE TABLE IF NOT EXISTS db2.table2 (id INT);"
  action [:query]
end

soon = Time.now + 90 # set the cron for +90 seconds... may not be enough on slow converge
soon_cron = {day: "#{soon.day}", hour: "#{soon.hour}", minute: "#{soon.min}"}
s3_mysql_backup 'my_mysql_backup' do
  mysql_connection connection
  mysql_user 'user1'
  mysql_password 'user1_pw'
  s3_region node['test_s3_region']
  s3_bucket node['test_s3_bucket']
  s3_access_key_id node['test_s3_access_key_id']
  s3_secret_access_key node['test_s3_secret_access_key']
  assets [
    {'item' => 'db1'},
    {'item' => 'db2 table2', 'prefix' => 'another'}
  ]
  groups ['group1', 'group2']
  cron soon_cron
  log_success_message "mysql test works!"
  action :create
end
