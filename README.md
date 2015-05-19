# s3_backup Cookbook

This recipe sets up resources to run a regular, automatic amazon s3 backup.
The default recipe doesn't do anything.

There are two resources:
* s3_file_backup
* s3_mysql_backup

## Resources

### Common functionality and configuration

Obviously s3_file_backup and s3_mysql_backup have a lot in common.
The only notable differences are in specifying what content gets backed up.

Each resource must have:
* A system user to own and run the backup script
* Cron settings to know when to run the backup
* Credentials to access an Amazon S3 bucket

Common to both resources:

* s3 credentials
* cron - hash  cdefault ni if missing no cron job
* system user
* mail group

### s3 file_backup

* assets - type of array, list of file paths to back up

each path backed up

There is one resource, the s3_backup_agent.

#### Actions

There is only one action _create_.
The _create_ action:
* creates a system user
* creates a mysql database user with required privilieges to back up the selected mysql assets
* generates a .my.cnf file so the system user can have default mysql database access
* generates a config.yml for the system user to provide s3 access credentials and list what should be backed up
* generates a ruby script to run the backups
* creates a cron job to run the ruby script on a defined schedule

#### Attributes

All configuration data is passed in to the resource as resource attributes.
That avoids adding them to the node attributes collection
(which would save them into thge node object, generally a bad idea for sensitive data like s3 access keys.)

*
*


#### s3 requirements

The credentials provided to the resource as key and secret key must
have at least s3:ListBucket and s3:PutObject for the specified bucket.
It's recommended that AIM credentials are used with the minimum authority.


## amazon S3

### IAM policy with minimum requirements to write backup files to a bucket

This policy creates a limited-access AIM user that can access only access the
specified s3 bucket.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::<bucket_name_here>"
      ],
      "Condition":{
        "StringLike":{
           "s3:prefix":"-/*"
        }
      }
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

Two issues:

1. you cannot turn off listing altogether or you cannot write.
2. if the site is compromised, malicious users can overwrite the data files.

Solution options:

1. grant permissions to list the bucket, but only for "-/*" and that will
      a) be hard to guess that it works, and
      b) won't list anything anyway
      See the Condition noted above.
2. name the files with a large random component, like
      "03022014--asset_name--ELtvYpmZBGR19mdomuSjWrafj8fuVcikDaX-_onCMMX3YUimd7P1EAOgPOvM2VxR"
      so that once a file is written (and since you can't list the bucket,) there is no plausible
      way to find and overwrite the bucket.
      Using this code to get random string:
        base64.urlsafe_b64encode(os.urandom(48))

Is it worth all that?
Probably not.  If anyone gains access to the aws keys, they are limited to this server's data.
Risks are:
  - Well they probably already ahve the data that's on the server, so no use in getting the backups
  - Only risk is lsing the server AND all the backups, if we do not have data in another location
Options to be safe from that:
  - We could just keep backing up to BigBrother
      - risk is that that machine is quite less secure and reliable than the web resources
  - We could do something like run a copy to copy s3 files to another bucket
      - another bucket could...

### BOTO
Basic python commands to write using BOTO:

```python
import boto
from boto.s3.key import Key
# make a connection
s3_connection = boto.connect_s3('AKIAI3MKVVFJW7TYSCTA', '+SSWzW9eLATy1LcfybVlRqu3C5TMWrLHUDww2UkL')
# select a bucket
bucket = s3_connection.get_bucket('triresources.com.cheftest')
# and create a key with content
key = Key(bucket)
key.key = 'foobar'
key.set_contents_from_string('This is a test of S3')
```

### s3 lifecycle

To create a *save all for 7 days, save 1st of the month for a year* lifecycle policy, we'll need all these rules:

    prefix    rule
    --------- --------
    01        365 days
    02        7 days
    03        7 days
    03        7 days
    05        7 days
    06        7 days
    07        7 days
    08        7 days
    09        7 days
    1         7 days
    2         7 days
    3         7 days

For now just muddle through doing this from the aws s3 console.
