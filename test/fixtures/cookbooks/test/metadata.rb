name             'test'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures test'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 's3_backup'
depends 'mysql', '~> 6.0'
depends 'mysql2_chef_gem', '~> 1.0'
