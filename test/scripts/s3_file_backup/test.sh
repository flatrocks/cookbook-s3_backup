# setup
rm -rf temp
mkdir temp
cp ../../../files/default/s3_file_backup.rb .
cp  /Volumes/RNRSecure/sandbox/s3_file_backup/config.yml .

# Run the test
echo 'Start at' $(date +%T)
ruby s3_file_backup.rb
echo 'End at' $(date +%T)

# cleanup
rm s3_file_backup.rb
rm config.yml

tail -n 1 /var/log/System.log # This is for Mac.  It's 'syslog' on linux
