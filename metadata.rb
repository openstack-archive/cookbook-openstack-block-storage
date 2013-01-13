name             "cinder"
maintainer       "AT&T, Inc."
maintainer_email "jaypipes@gmail.com"
license          "Apache 2.0"
description      "The OpenStack Advanced Volume Management service Cinder."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2012.2.0"

recipe           "cinder::api", "Installs the cinder-api, sets up the cinder database, and cinder service/user/endpoints in keystone"
recipe           "cinder::db", "Creates the Cinder database"
recipe           "cinder::scheduler", "Installs the cinder-scheduler service"
recipe           "cinder::volume", "Installs the cinder-volume service and sets up the iscsi helper"

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends          "apt"
depends          "database"
depends          "glance"
depends          "keystone"
depends          "mysql"
depends          "openssh"
depends          "openstack-common", ">= 0.1.7"
depends          "rabbitmq"
depends          "selinux"
