s3_asset_backup CHANGELOG
=========================

This file is used to list changes made in each version of the s3_asset_backup cookbook.

0.1.0
-----
- [your_name] - Initial release of s3_asset_backup

0.2.0
-----
- Significant mods to the configuration of asstes to be backed up.
- Added option to backup multiple databases using a name prefix ending in '*'

0.2.1
-----
- Removed use_inline_resources from provider base class because it somehow prevents the generation of actual base-defined resources when the node is built.

0.2.2
-----
- Fixed greivous error where the config.yml file was written with % as wildcard but the script file expected *.

0.2.3
-----
- Fixed syslog logging.  Replaced the success_message resource attribute with a good fixed message, and rewrote the mysql script to work ok when there are duplicated databases and tables.

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
