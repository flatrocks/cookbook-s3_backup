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

def expand_starred_items(items)
  all_databases = run_system_command("mysql -r -s -N -e 'SHOW DATABASES'").split("\n")
  expanded_items = []
  items.each do |item|
    if item.split.first.end_with? '*'
      prefix = item.split.first.chomp('*')
      expanded_items += all_databases.select {|db| db.start_with? prefix}.map {|db| item.split[1..-1].unshift(db).join(' ')}
    else
      expanded_items << item
    end
  end
  expanded_items
end

begin
  config = YAML.load_file('config.yml')
  s3, log, backup_groups = config['s3'], config['log'], config['backup_groups']
  timestamp_prefix = Time.now.strftime(s3['time_prefix'])

  backup_groups.each do |group_prefix, items|
    group_prefix = '' if group_prefix == 'default'
    expand_starred_items(items).each do |item|
      path = "temp/#{item.split.first}.sql"
      File.delete path if File.exists? path
      run_system_command "mysqldump #{item} > #{path}"
      dirname, basename = File.dirname(path), File.basename(path)

      File.delete TEMP_TGZ_FILE if File.exists? TEMP_TGZ_FILE
      run_system_command "tar --directory=#{dirname} -cz --file=#{TEMP_TGZ_FILE} #{basename}"

      s3_client = Aws::S3::Client.new(access_key_id: s3['access_key_id'], secret_access_key: s3['secret_access_key'], region: s3['region'])
      s3_key = File.join(timestamp_prefix, group_prefix, basename).gsub(/^\//, '') + ".tgz"
      Aws::S3::Object.new(s3['bucket'], s3_key, client: s3_client).upload_file(TEMP_TGZ_FILE)
    end
  end

  Syslog.open(log['ident']).log Syslog::LOG_NOTICE, log['success_message'] if log['ident'] && log['success_message']
rescue Exception => e
  Syslog.open(log['ident']).log Syslog::LOG_ERR, e.message if log['ident']
ensure
  Dir['temp/*'].each {|file| File.delete file}
end

