# s3_asset_backup CHANGELOG


This file is used to list changes made in each version of the s3_asset_backup cookbook.

0.3.0
-----
- Fixed tests, updated databasse dependency

0.2.4
-----
- Changed default backup prefix to '%Y-%m-%d' (e.g. "2015-11-04") because it makes more sense.

0.2.3
-----
- Fixed syslog logging.  Replaced the success_message resource attribute with a good fixed message, and rewrote the mysql script to work ok when there are duplicated databases and tables.

0.2.2
-----
- Fixed greivous error where the config.yml file was written with % as wildcard but the script file expected *.

## 0.2.0
- Significant mods to the configuration of asstes to be backed up.
- Added option to backup multiple databases using a name prefix ending in '*'

## 0.1.0
- [your_name] - Initial release of s3_asset_backup

