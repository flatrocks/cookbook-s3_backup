# s3_backup Cookbook

This recipe provides resources to run simple cron-scheduled
backups to Amazon S3 storage.

The default recipe doesn't do anything.
There are two resources that do all the work:
* s3_file_backup
* s3_mysql_backup

## Support

Initially this cookbook had been tested on Ubuntu 14.04,
though it's likely to work on other distributions.
(Contributions for extended support are definitely welcome.)
This cookbook relies on the linux/Unix ```tar``` and ```cron``` utilities,
and it is unlikely it will be useful on Windows.

## Resources

### Common attributes

The __s3_file_backup__  and __s3_mysql_backup__ resources share most of the same attributes.
Common attributes are described here, by category.

__User:__
* __user__ - kind_of: String, required: true.  (name attribute)
Name of the system user that implements the backup.
* __groups__ - kind_of: Array, default: [].
Group membership for user.  This allows the user to access files that will be backed up.

__S3:__
* __s3_region__ - kind_of: String, required: true.
The S3 region where the bucket's located.
* __s3_bucket__ - kind_of: String, required: true.
The S3 bucket to back up into.
* __s3_access_key_id__ - kind_of: String, required: true.
The S3 access_key_id.
* __s3_secret_access_key__ - kind_of: String, required: true.
The S3 secret_access_key.
* __s3_time_prefix__ - kind_of: String,, default: '%d-%b-%Y'.
The s3_time_prefix is processed using the Ruby Time.strftime() function
and prepended to each saved object name.
The usual usage is to provide a date prefix for a daily backup.
For example, on May 20th, 2015, the default will resolve to: "20-May-2015".
See Ruby Time.strftime() docs for more examples.

__Backup groups:__
* __backup_groups__ - kind_of: Hash, default: Hash.new.
This is where you define what assets you want backed up.

Each key is the name of a "backup group".
The backup group name will be used as an s3_key path segment, after the resolved s3_time_prefix and before the asset name.
The exception is that the "default" backup group will skip adding this additional s3_key segment.

Each value is an array of assets to back up.
The meaning and format of the array items differs
for file backups and mysql backups.
See notes in each section for details.

__Logging:__
* __log_ident__ - kind_of: String,, default: 's3_file_backup.
This is the "ident" string used when logging to the system log,
as shown in this example log entry: ```May 20 16:42:49 Morse.local s3_file_backup[28778]: S3 file backup complete```.
* __log_success_message__ - kind_of: [String, NilClass], default: nil.
The log message created after a successful backup.

By default, backup errors will be logged to the system log, but successful backups are not logged.
You can disable system logging completely by setting log_ident to an empty string.
When error logging is enabled, you can also enable success logging
by setting a non-empty string value for the log_success_message.

Cron:__
* __cron__ - kind_of: Hash, default: Hash.new.
The elements of this has are passed directly to the standard cron resource
to run backups.
Of course you should not try to set the ```command``` value.
Setting this attribute to an empty Hash will disable cron for the backup.

### The s3_file_backup resource

#### Description

The s3_file_backup resource creates resources to run an automatic cron backup
of selected fiels and directories, storing the results in an Amazon S3 bucket.

Each file or directory is compiled and compressed using the ```tar``` command
with the "z" compression option.
File names for each saved object will be the base file name or directory name,
with ".tgz" appended to make it clear how the files have been compressed.
Then each object is saved to S3 storage as directed by the resource configuration.

#### Actions

* __create__ - (default) creates the resource
* __delete__ - creates the resource

#### Attributes

All of the attributes listed in "Common attributes" apply to this resource.
The following additional attributes are specific to s3_file_backup.

__Backup_groups:__
Each item in a backup group's array of assets is a file path to a file or directory
to back up.  The path can be relative or absolute.

#### Full example

``` ruby
s3_file_backup 'my_backup' do
  s3_region 'us-east-1'
  s3_bucket 'my_bucket'
  s3_access_key_id 'my_access_key_id'
  s3_secret_access_key 'my_secret_access_key'
  backup_groups default: ['/some/file'], x: '/another/file'
  groups ['group1', 'group2']
  action :create
  cron day: '*', hour: '10,14,16'
end
```

This backup should create three S3 objects in the s3 bucket 'my_bucket'
under the specified S3 account.  Assuming today's date is May 20th, 2015,
the objects will be named:
* ```20-May-2015/file.tgz```  _(no extra name segment for default group)_
* ```20-May-2015/x/file.tgz```  _(extra 'x' segment in s3 object name, from the backup group name)_

This example points out the value of using multiple backup_groups:
it allows for organizing and saving items that might otherwise have the same s3 object names.
### The s3_mysql_backup resource

#### Description

The s3_mysql_backup resource creates resources to run an automatic cron backup
of selected MyQL databases and tables, storing the results in an Amazon S3 bucket.

The mysqldump utility is used to dump an sql text file, and
the dump file is compressed using the ```tar``` command with the "z" compression option.
File name for each saved object will be the database name,
with ".sql.tgz" appended to indicate the file format and how the file has been compressed.
Then each object is saved to S3 storage as directed by the resource configuration.

You can backup entire databases, or you can select one or more tables.
(This mirrors the functionality of the mysqldump command.)

#### Actions

* __create__ - (default) creates the resource
* __delete__ - creates the resource

#### Attributes

All of the attributes listed in "Common attributes" apply to this resource.
The following additional attributes are specific to s3_file_backup.

__mysql:__
* __mysql_connection__ - kind_of: Hash, required: true.
These Hash elements are passed directly to the mysql_database_user
resource in the standard database cookbook.
Please refer to that cookbooks's documentation for details.
* __mysql_user__ kind_of: String, required: true.
* __mysql_password__ kind_of: String, default: nil

__Backup_groups:__
Each item in a backup group's array of assets is a string defining a full or partial database to backup.
* If just a database name is included, (e.g _"database1"_,) then the complete database is backed up.
* If a database name is followed bt one or more table names, (e.g _"database1 table1 table3"_,)
then only the selected tables are included in the backup.
* If a database name ends in an asterisk, (e.g _"database*"_,) then the asset list is expanded to
include all accessible databases taht begin with the prefix (in this case, _"database"_).
Using this option will apply any table list to each database in the expanded list.

#### Full example

``` ruby
s3_mysql_backup 'my_backup' do
  s3_region 'us-east-1'
  s3_bucket 'my_bucket'
  s3_access_key_id 'my_access_key_id'
  s3_secret_access_key 'my_secret_access_key'
  mysql_connection host: '127.0.0.1', user: 'root', password: 'somepw'
  mysql_user 'user1'
  mysql_password 'some_password'
  groups ['group1', 'group2']
  backup_groups default: ['db1', 'db2 table1 table2'], x: ['dbx*']
  cron day: '*', hour: '10,14,16'
  action :create
end
```

This backup should create several S3 objects in the s3 bucket 'my_bucket'
under the specified S3 account.  Assuming today's date is May 20th, 2015,
the objects will be named:
* ```20-May-2015/db1.sql.tgz```  _(contains the entire database dump of db1)_
* ```20-May-2015/db2.sql.tgz```  _(contains only table1 and table2 from db2)_
And an object for each database with name that begins with "dbx," for example,"
* ```20-May-2015/x/dbx1.sql.tgz```

## Notes

### Using cron

These backup resources are designed to play well with cron.

On success, there's no output generated,
but if there's a problem, the stdout and stderr are dumped
so (if you have cron "mailto" set up) you should see it all in an email.

The backup cron jobs are run under the resource's user account.
Depending on your setup, you may need to add the "mail" group
to the resources' "groups" attribute to allow mail delivery.

### S3 requirements

You have to create the S3 bucket manually; this cookbook assumes the cookbook exists.

The credentials provided to the resource as access_key_id and secret_access_key must
have at least s3:ListBucket and s3:PutObject authority for the specified bucket.
__It's recommended that AIM credentials are used and granted the minimum authority to do backups.
Don't put your AWS root credentials out on a server!__

This example policy describes the minimum access required
for an IAM user to back up to a specifc S3 bucket.
Note that this may not be up to date with the current AWS API and you may need to
take additional steps to secure your backups.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::<bucket_name_here>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::<bucket_name_here>/*"
            ]
        }
    ]
}
```
Note that the Resource for the first block is just the bucket name,
but for the second block, it ends with "/*" indicating that it applies to the
contents of the bucket.

If it meets your needs, you can use the same AWS credentials for multiple
resources, for example you may want to back up both files and MySQL data
from a server to a single S3 bucket.  In a case like that it's probably best to use the same
S3 credentials for both resources.

### S3 lifecycle

Deleting old backups or keeping only a minimum number is beyond the scope of this cookbook.
Fortunately Amazon S3 Lifecycle Management provides a simple and effective way
to set retention limits at the storage level.

### Testing

The Chef resources have a reasonable test suite, however note that the ruby scripts that
run the actual backups have been hand-tested due to the complexity of
setting up all the associated resources.
(Of course it's possible to run unit tests,
but that's not much help when the primary issues come
from interaction with Amazon S3, mysql, cron, and other stuff you'd stub out anyway.
If anyone has ideas on how to
improve this I am all ears.)