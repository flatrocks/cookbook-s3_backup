require 'aws-sdk'
require 'open3'
require 'syslog'
require 'yaml'

TEMP_TGZ_FILE = 'temp/tgz'

def run_system_command(command)
  stdout, stderr, exit_status = Open3.capture3(command)
  unless exit_status.success?
    puts [stdout, stderr].join("\n")
    raise "Command failed: #{command}"
  end
  stdout
end

mysql_user, mysql_pw, restore_prefix = ARGV
unless mysql_user && mysql_pw
  puts "Restore selected selected sql dump file from S3 storage."
  puts "usage:  ruby #{__FILE__} mysql_user mysql_password <restore_prefix, default = current backup prefix>"
  exit
end
restore_prefix ||= Time.now.strftime(s3['time_prefix'])

config = YAML.load_file('config.yml')
s3 = config['s3']
objects_saved = 0
s3_client = Aws::S3::Client.new(access_key_id: s3['access_key_id'], secret_access_key: s3['secret_access_key'], region: s3['region'])
selected_backup_files = Aws::S3::Bucket.new(s3['bucket'], client: s3_client).objects(prefix: restore_prefix)

puts "Ready to restore #{selected_backup_files.size} sql files from bucket #{s3['bucket']} with prefix '#{restore_prefix}'."
puts "[Enter] to start."
gets

selected_backup_files.each do |backup_file|
  tarfile = backup_file.key.split('/').last
  sqlfile = tarfile.split('.tgz').first
  dbname = sqlfile.split('.sql').first
  backup_file.get({response_target: tarfile})
  run_system_command "tar -xvzf " + tarfile
  run_system_command "mysql -u #{mysql_user} -p#{mysql_password} -e 'drop database if exists `#{dbname}`'"
  run_system_command "mysql -u #{mysql_user} -p#{mysql_password} -e 'create database `#{dbname}`'"
  run_system_command "cat sqlfile | mysql --database=#{dbname}"
  puts "Loaded #{sqlfile} (#{File.new(sqlfile).size} bytes) to database '#{dbname}'"
  File.delete tarfile
  File.delete sqlfile
end
