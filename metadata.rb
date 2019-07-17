name             'openstack-block-storage'
maintainer       'Chef OpenStack'
maintainer_email 'openstack-dev@lists.openstack.org'
license          'Apache-2.0'
description      'The OpenStack Advanced Volume Management service Cinder.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '17.2.0'

%w(ubuntu redhat centos).each do |os|
  supports os
end

depends 'openstack-common', '>= 17.0.0'
depends 'openstack-identity', '>= 17.0.0'
depends 'openstack-image', '>= 17.0.0'
depends 'openstackclient'

depends 'lvm'
depends 'selinux'

issues_url 'https://launchpad.net/openstack-chef' if respond_to?(:issues_url)
source_url 'https://github.com/openstack/cookbook-openstack-block-storage' if respond_to?(:source_url)
chef_version '>= 12.5' if respond_to?(:chef_version)
