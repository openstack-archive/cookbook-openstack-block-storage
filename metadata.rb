name             "openstack-block-storage"
maintainer       "AT&T Services, Inc."
maintainer_email "cookbooks@lists.tfoundry.com"
license          "Apache 2.0"
description      "The OpenStack Advanced Volume Management service Cinder."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "7.0.0"

recipe           "openstack-block-storage::api", "Installs the cinder-api, sets up the cinder database, and cinder service/user/endpoints in keystone"
recipe           "openstack-block-storage::db", "Creates the Cinder database"
recipe           "openstack-block-storage::keystone_registration", "Registers cinder service/user/endpoints in keystone"
recipe           "openstack-block-storage::scheduler", "Installs the cinder-scheduler service"
recipe           "openstack-block-storage::volume", "Installs the cinder-volume service and sets up the iscsi helper"

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

depends          "apt"
depends          "database"
depends          "openstack-image"
depends          "openstack-identity", ">= 2012.2.1"
depends          "mysql"
depends          "openssh"
depends          "openstack-common", ">= 0.1.7"
depends          "rabbitmq"
depends          "selinux"
