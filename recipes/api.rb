#
# Cookbook Name:: cinder
# Recipe:: api
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

require "uri"

class ::Chef::Recipe
  include ::Openstack
  include ::Opscode::OpenSSL::Password
end

# Allow for using a well known service password
if node["developer_mode"]
  node.set_unless["cinder"]["service_pass"] = "cinder"
else
  node.set_unless["cinder"]["service_pass"] = secure_password
end

platform_options = node["cinder"]["platform"]

service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true

  action :enable
end

execute "cinder-manage db sync" do
  command "cinder-manage db sync"
  not_if "cinder-manage db version && test $(cinder-manage db version) -gt 0"

  action :nothing
end

db_role = node["cinder"]["cinder_db_chef_role"]
db_info = config_by_role db_role, "cinder"

db_user = node["cinder"]["db"]["username"]
db_pass = db_info["db"]["password"]
sql_connection = db_uri("volume", db_user, db_pass)

rabbit_server_role = node["cinder"]["rabbit_server_chef_role"]
rabbit_info = get_settings_by_role rabbit_server_role, "queue"

glance_api_role = node["cinder"]["glance_api_chef_role"]
glance = get_settings_by_role glance_api_role, "glance"
glance_api_endpoint = endpoint "image-api"

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

  notifies :restart, resources(:service => "cinder-api"), :delayed
end

identity_admin_endpoint = endpoint "identity-admin"
identity_endpoint = endpoint "identity-api"

template "/etc/cinder/api-paste.ini" do
  source "api-paste.ini.erb"
  group  node["cinder"]["group"]
  owner  node["cinder"]["user"]
  mode   00644
  variables(
    "identity_endpoint" => identity_endpoint,
    "identity_admin_endpoint" => identity_admin_endpoint
  )

  notifies :restart, resources(:service => "cinder-api"), :immediately
end

keystone_register "Register Cinder Volume Service" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  endpoint_region node["cinder"]["region"]
  endpoint_adminurl ::URI.decode api_endpoint.to_s
  endpoint_internalurl ::URI.decode api_endpoint.to_s
  endpoint_publicurl ::URI.decode api_endpoint.to_s

  action :create_service
end

keystone_register "Register Cinder Volume Endpoint" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  endpoint_region node["cinder"]["region"]
  endpoint_adminurl ::URI.decode api_endpoint.to_s
  endpoint_internalurl ::URI.decode api_endpoint.to_s
  endpoint_publicurl ::URI.decode api_endpoint.to_s

  action :create_endpoint
end

keystone_register "Register Cinder Service User" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  user_pass node["cinder"]["service_pass"]
  user_enabled "true" # Not required as this is the default
  action :create_user
end

keystone_register "Grant service Role to Cinder Service User for Cinder Service Tenant" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port.to_s
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  role_name node["cinder"]["service_role"]
  action :grant_role
end
