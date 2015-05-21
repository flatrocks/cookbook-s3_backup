# Cookbook Name::
# Recipe::
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# ONLY FOR TESTING S3_FILE_BACKUP RESOURCE

s3_mysql_backup 'my_backup' do
  s3_region 'us-east-1'
  s3_bucket 'my_bucket'
  s3_access_key_id 'my_access_key_id'
  s3_secret_access_key 'my_secret_access_key'
  assets [
    {'item' => 'db1'},
    {'item' => 'db2 table1 table2'}
  ]
  mysql_connection host: '127.0.0.1', user: 'root', password: 'somepw'
  mysql_user 'user1'
  mysql_password 'some_password'
  groups ['group1', 'group2']
  action :create
  cron day: '*', hour: '10,14,16'
end
