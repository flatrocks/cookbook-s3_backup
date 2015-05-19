require 'aws-sdk'
require 'open3'
require 'syslog'
require 'yaml'

def run_system_command(command)
  stdout, stderr, exit_status = Open3.capture3(command)
  unless exit_status.success?
    puts stdout unless stdout.empty?
    puts stderr unless stderr.empty?
    raise "Command failed: #{command}"
  end
  stdout
end

begin
  config = YAML.load_file('config.yml')
  tar, s3, log, assets = config['tar'], config['s3'], config['log'], config['assets']

  s3_key_prefix = Time.now.strftime(s3['key_prefix_format'])
  s3_client = Aws::S3::Client.new(access_key_id: s3['access_key_id'], secret_access_key: s3['secret_access_key'], region: s3['region'])

  Dir['temp/*'].each {|file| File.delete file}

  assets.each do |key, path|
    temp_file, s3_key = "temp/#{key}", "#{s3_key_prefix}/#{key}"
    if tar['flatten_path']
      run_system_command "tar --directory=#{File.dirname(path)} -cz --file=#{temp_file} #{File.basename(path)}"
    else
      run_system_command "tar -cz --file=#{temp_file} #{path}"
    end
    Aws::S3::Object.new(s3['bucket'], s3_key, client: s3_client).upload_file(temp_file)
    File.delete temp_file
  end

rescue Exception => e
  Syslog.open(log['ident']).log Syslog::LOG_ERR, e.message if log['ident']
  exit
end

Syslog.open(log['ident']).log Syslog::LOG_NOTICE, log['success_message'] if log['ident'] && log['success_message']
