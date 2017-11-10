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
# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
end

identity_admin_endpoint = admin_endpoint 'identity'
auth_url = ::URI.decode identity_admin_endpoint.to_s

interfaces = {
  public: { url: public_endpoint('block-storage') },
  internal: { url: internal_endpoint('block-storage') },
  admin: { url: admin_endpoint('block-storage') },
}
service_pass = get_password 'service', 'openstack-block-storage'
region = node['openstack']['block-storage']['region']
service_project_name = node['openstack']['block-storage']['conf']['keystone_authtoken']['project_name']
service_user = node['openstack']['block-storage']['service_user']
admin_user = node['openstack']['identity']['admin_user']
admin_pass = get_password 'user', node['openstack']['identity']['admin_user']
admin_project = node['openstack']['identity']['admin_project']
admin_domain = node['openstack']['identity']['admin_domain_name']
service_domain_name = node['openstack']['block-storage']['conf']['keystone_authtoken']['user_domain_name']
service_role = node['openstack']['block-storage']['service_role']
service_name = node['openstack']['block-storage']['service_name']
service_type = node['openstack']['block-storage']['service_type']

connection_params = {
  openstack_auth_url:     "#{auth_url}/auth/tokens",
  openstack_username:     admin_user,
  openstack_api_key:      admin_pass,
  openstack_project_name: admin_project,
  openstack_domain_name:    admin_domain,
}

# Register VolumeV2 Service
openstack_service service_name do
  type service_type
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register VolumeV2 Endpoints
  openstack_endpoint service_type do
    service_name service_name
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Register Service Project
openstack_project service_project_name do
  connection_params connection_params
end

# Register Service User
openstack_user service_user do
  project_name service_project_name
  password service_pass
  connection_params connection_params
end

## Grant Service role to Service User for Service Tenant ##
openstack_user service_user do
  role_name service_role
  project_name service_project_name
  connection_params connection_params
  action :grant_role
end

openstack_user service_user do
  domain_name service_domain_name
  role_name service_role
  connection_params connection_params
  action :grant_domain
end
