# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: identity_registration
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

require 'uri'

class ::Chef::Recipe # rubocop:disable Documentation
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity-admin'
bootstrap_token = get_password 'token', 'openstack_identity_bootstrap_token'
auth_uri = ::URI.decode identity_admin_endpoint.to_s
admin_cinder_api_endpoint = admin_endpoint 'block-storage-api'
internal_cinder_api_endpoint = internal_endpoint 'block-storage-api'
public_cinder_api_endpoint = public_endpoint 'block-storage-api'
service_pass = get_password 'service', 'openstack-block-storage'
region = node['openstack']['block-storage']['region']
service_tenant_name = node['openstack']['block-storage']['service_tenant_name']
service_user = node['openstack']['block-storage']['service_user']
service_role = node['openstack']['block-storage']['service_role']
service_name = node['openstack']['block-storage']['service_name']
service_type = node['openstack']['block-storage']['service_type']

openstack_identity_register 'Register Service Tenant' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  tenant_description 'Service Tenant'

  action :create_tenant
end

openstack_identity_register 'Register Cinder V2 Volume Service' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name service_name
  service_type service_type
  service_description 'Cinder Volume Service V2'
  endpoint_region region
  endpoint_adminurl ::URI.decode admin_cinder_api_endpoint.to_s
  endpoint_internalurl ::URI.decode internal_cinder_api_endpoint.to_s
  endpoint_publicurl ::URI.decode public_cinder_api_endpoint.to_s
  action :create_service
end

openstack_identity_register 'Register Cinder V2 Volume Endpoint' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  service_name service_name
  service_type service_type
  service_description 'Cinder Volume Service V2'
  endpoint_region region
  endpoint_adminurl ::URI.decode admin_cinder_api_endpoint.to_s
  endpoint_internalurl ::URI.decode internal_cinder_api_endpoint.to_s
  endpoint_publicurl ::URI.decode public_cinder_api_endpoint.to_s
  action :create_endpoint
end

openstack_identity_register 'Register Cinder Service User' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  user_pass service_pass
  user_enabled true # Not required as this is the default
  action :create_user
end

openstack_identity_register 'Grant service Role to Cinder Service User for Cinder Service Tenant' do
  auth_uri auth_uri
  bootstrap_token bootstrap_token
  tenant_name service_tenant_name
  user_name service_user
  role_name service_role
  action :grant_role
end
