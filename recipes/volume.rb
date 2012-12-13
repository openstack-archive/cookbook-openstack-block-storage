#
# Cookbook Name:: cinder
# Recipe:: volume
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012, AT&T, Inc.
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
  include ::Opscode::OpenSSL::Password
end

platform_options = node["cinder"]["platform"]

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

db_role = node["cinder"]["cinder_db_chef_role"]
db_info = config_by_role db_role, "cinder"

db_user = node["cinder"]["db"]["username"]
db_pass = db_info["db"]["password"]
sql_connection = db_uri("volume", db_user, db_pass)

rabbit_server_role = node["cinder"]["rabbit_server_chef_role"]
rabbit_info = config_by_role rabbit_server_role, "queue"

glance_api_role = node["cinder"]["glance_api_chef_role"]
glance = config_by_role glance_api_role, "glance"
glance_api_endpoint = endpoint "image-api"

if node["developer_mode"]
  execute "creating cinder disk image" do
    image_file = node["cinder"]["volume"]["lvm"]["image_file"]
    image_size = node["cinder"]["volume"]["lvm"]["image_size"]
    user = node["cinder"]["group"]
    group = node["cinder"]["user"]
    command <<-EOF
      truncate -s #{image_size} #{image_file}
      chown #{user}:#{group} #{image_file}
    EOF

    not_if { ::File.exists? node["cinder"]["volume"]["lvm"]["image"] }
  end

  execute "creating cinder LVM volume group" do
    image_file = node["cinder"]["volume"]["lvm"]["image_file"]
    volume_group = node["cinder"]["volume"]["volume_group"]

    command "vgcreate #{volume_group} $(losetup --show -f #{image_file})"

    not_if "vgdisplay #{volume_group}"
  end
end

service "cinder-volume" do
  service_name platform_options["cinder_volume_service"]
  supports :status => true, :restart => true

  action [ :enable, :start ]
end

template "/etc/cinder/cinder.conf" do
  source "cinder.conf.erb"
  group  node["cinder"]["group"]
  owner  node["cinder"]["user"]
  mode   00644
  variables(
    :sql_connection => sql_connection,
    :rabbit_host => rabbit_info["host"],
    :rabbit_port => rabbit_info["port"],
    :glance_host => glance_api_endpoint.host,
    :glance_port => glance_api_endpoint.port
  )

  notifies :restart, resources(:service => "cinder-volume")
end

service "iscsitarget" do
  service_name platform_options["cinder_iscsitarget_service"]
  supports :status => true, :restart => true

  action :enable
end

template "/etc/tgt/targets.conf" do
  source "targets.conf.erb"
  mode   00600

  notifies :restart, resources(:service => "iscsitarget"), :immediately
end
