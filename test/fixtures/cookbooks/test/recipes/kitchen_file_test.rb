# Cookbook Name::
# Recipe::
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# for test kitchen run to check out the whole shebang


# create some file assets
directory '/some' do
  mode '777'
  action :create
end
file '/some/file' do
  mode '777'
  content 'some test'
  action :create
end

directory '/another' do
  mode '777'
  action :create
end
file '/another/file' do
  mode '777'
  content 'another test'
  action :create
end

soon = Time.now + 60
soon_cron = {day: "#{soon.day}", hour: "#{soon.hour}", minute: "#{soon.min}"}
s3_file_backup 'my_file_backup' do
  s3_region node['test_s3_region']
  s3_bucket node['test_s3_bucket']
  s3_access_key_id node['test_s3_access_key_id']
  s3_secret_access_key node['test_s3_secret_access_key']
  assets [
    {'item' => '/some/file'},
    {'item' => '/another/file', 'prefix' => 'another'}
  ]
  groups ['group1', 'group2']
  cron soon_cron
  log_success_message "file test works!"
  action :create
end
