maintainer       "DreamHost, Inc."
maintainer_email "carl.perry@dreamhost.com"
license          "Apache 2.0"
description      "The OpenStack Advanced Volume Management service Cinder."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "5.0.0"

%w{ ubuntu fedora }.each do |os|
  supports os
end

%w{ database mysql openstack-utils openstack-common osops-utils }.each do |dep|
  depends dep
end
