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
end

identity_admin_endpoint = endpoint "identity-admin"
bootstrap_token = secret "secrets", "keystone_bootstrap_token"
auth_uri = ::URI.decode identity_admin_endpoint.to_s
cinder_api_endpoint = endpoint "volume-api"
service_pass = service_password "cinder"

keystone_register "Register Cinder Volume Service" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  endpoint_region node["cinder"]["region"]
  endpoint_adminurl ::URI.decode cinder_api_endpoint.to_s
  endpoint_internalurl ::URI.decode cinder_api_endpoint.to_s
  endpoint_publicurl ::URI.decode cinder_api_endpoint.to_s

  action :create_service
end

keystone_register "Register Cinder Volume Endpoint" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  endpoint_region node["cinder"]["region"]
  endpoint_adminurl ::URI.decode cinder_api_endpoint.to_s
  endpoint_internalurl ::URI.decode cinder_api_endpoint.to_s
  endpoint_publicurl ::URI.decode cinder_api_endpoint.to_s

  action :create_endpoint
end

keystone_register "Register Cinder Service User" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  user_pass service_pass
  user_enabled "true" # Not required as this is the default
  action :create_user
end

keystone_register "Grant service Role to Cinder Service User for Cinder Service Tenant" do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  role_name node["cinder"]["service_role"]
  action :grant_role
end
