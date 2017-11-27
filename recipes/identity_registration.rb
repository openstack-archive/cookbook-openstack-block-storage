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

# Register Volume Service
openstack_service service_name do
  type service_type
  connection_params connection_params
end

interfaces.each do |interface, res|
  # Register Volume Endpoints
  openstack_endpoint service_type do
    service_name service_name
    interface interface.to_s
    url res[:url].to_s
    region region
    connection_params connection_params
  end
end

# Workaround to enable Volume support in Horizon
# this may break in future releases of chef-client
openstack_service 'cinderv3' do
  type 'volumev3'
  connection_params connection_params
end

interfaces.each do |interface, res|
  openstack_endpoint 'volumev3' do
    service_name 'cinderv3'
    interface interface.to_s
    url res[:url].to_s.gsub('/v2', '/v3')
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
  domain_name service_domain_name
  role_name service_role
  password service_pass
  connection_params connection_params
  action [:create, :grant_role]
end
