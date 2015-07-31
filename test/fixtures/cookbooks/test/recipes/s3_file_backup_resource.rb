# Cookbook Name::
# Recipe::
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# ONLY FOR TESTING S3_FILE_BACKUP RESOURCE

s3_file_backup 'my_backup' do
  s3_region 'us-east-1'
  s3_bucket 'my_bucket'
  s3_access_key_id 'my_access_key_id'
  s3_secret_access_key 'my_secret_access_key'
  backup_groups 'default' => ['/some/file'], 'a_prefix' => ['/yet_another/file']
  groups ['group1', 'group2']
  action :create
  cron day: '*', hour: '10,14,16'
end
