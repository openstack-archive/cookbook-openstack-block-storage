name             'openstack-block-storage'
maintainer       'Chef OpenStack'
maintainer_email 'openstack-discuss@lists.openstack.org'
license          'Apache-2.0'
description      'The OpenStack Advanced Volume Management service Cinder.'
version          '18.0.0'

recipe 'api', 'Installs the cinder-api and sets up the cinder database'
recipe 'backup', 'Installs the cinder-backup service'
recipe 'cinder-common', 'Defines the common pieces of repeated code from the other recipes'
recipe 'identity_registration', 'Defines the cinder service/user/endpoints in keystone'
recipe 'scheduler', 'Installs the cinder-scheduler service'
recipe 'volume_driver_lvm', 'Configures lvm as the cinder storage backend'
recipe 'volume', 'Installs the cinder-volume service'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.0'
depends 'lvm'
depends 'openstackclient'
depends 'openstack-common', '>= 18.0.0'
depends 'openstack-identity', '>= 18.0.0'
depends 'openstack-image', '>= 18.0.0'

issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-block-storage'
chef_version '>= 14.0'
