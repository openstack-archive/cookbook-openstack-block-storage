#
# Cookbook Name:: cinder
# Recipe:: setup
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

include_recipe "cinder::common"

class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = endpoint "identity-admin"
keystone_service_role = node["cinder"]["keystone_service_chef_role"]
keystone = get_settings_by_role keystone_service_role, "keystone"
api_endpoint = endpoint "volume-api"

execute "cinder-manage db sync" do
  command "cinder-manage db sync"
  action :run
  not_if "cinder-manage db version && test $(cinder-manage db version) -gt 0"
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
  endpoint_adminurl api_endpoint.to_s
  endpoint_internalurl api_endpoint.to_s
  endpoint_publicurl api_endpoint.to_s
  action :create_service
end

keystone_register "Register Cinder Volume Endpoint" do
  auth_host identity_admin_endpoint.host
  auth_port identity_admin_endpoint.port
  auth_protocol identity_admin_endpoint.scheme
  api_ver identity_admin_endpoint.path
  auth_token keystone["admin_token"]
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  endpoint_region node["cinder"]["region"]
  endpoint_adminurl api_endpoint.to_s
  endpoint_internalurl api_endpoint.to_s
  endpoint_publicurl api_endpoint.to_s
  action :create_endpoint
end
