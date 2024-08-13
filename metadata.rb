name              'osl-matrix'
maintainer        'Oregon State University'
maintainer_email  'chef@osuosl.org'
license           'All Rights Reserved'
description       'Creates and manages a matrix synapse service for the Open Source Lab'
issues_url        'https://github.com/osuosl-cookbooks/osl-matrix/issues'
source_url        'https://github.com/osuosl-cookbooks/osl-matrix'
chef_version      '>= 17.0'
version           '1.1.2'

supports          'almalinux', '~> 8.0'

depends           'osl-docker'
depends           'osl-firewall'
depends           'osl-nginx'
depends           'osl-postgresql'
