name             'openstack-block-storage'
maintainer       'Chef OpenStack'
maintainer_email 'openstack-discuss@lists.openstack.org'
license          'Apache-2.0'
description      'The OpenStack Advanced Volume Management service Cinder.'
version          '20.0.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'apache2', '~> 8.6'
depends 'lvm'
depends 'openstackclient'
depends 'openstack-common', '>= 20.0.0'
depends 'openstack-identity', '>= 20.0.0'
depends 'openstack-image', '>= 20.0.0'

issues_url 'https://launchpad.net/openstack-chef'
source_url 'https://opendev.org/openstack/cookbook-openstack-block-storage'
chef_version '>= 16.0'
