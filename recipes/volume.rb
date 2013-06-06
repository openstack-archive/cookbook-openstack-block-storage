#
# Cookbook Name:: openstack-block-storage
# Recipe:: volume
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe
  include ::Openstack
end

include_recipe "openstack-block-storage::cinder-common"

platform_options = node["openstack"]["block-storage"]["platform"]

platform_options["cinder_volume_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

platform_options["cinder_iscsitarget_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]

    action :upgrade
  end
end

volume_driver = node["openstack"]["block-storage"]["volume"]["driver"]
if volume_driver == "cinder.volume.drivers.netapp.NetAppISCSIDriver"
  node.override["openstack"]["block-storage"]["netapp"]["dfm_password"] = service_password "netapp"
elsif volume_driver == 'cinder.volume.drivers.RBDDriver'
  node.override["openstack"]["block-storage"]["rbd_secret_uuid"] = service_password "rbd"
end

service "cinder-volume" do
  service_name platform_options["cinder_volume_service"]
  supports :status => true, :restart => true

  action [ :enable, :start ]
  subscribes :restart, "template[/etc/cinder/cinder.conf]"
end

service "iscsitarget" do
  service_name platform_options["cinder_iscsitarget_service"]
  supports :status => true, :restart => true

  action :enable
end

template "/etc/tgt/targets.conf" do
  source "targets.conf.erb"
  mode   00600

  notifies :restart, "service[iscsitarget]", :immediately
end
