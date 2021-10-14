#
# Cookbook:: openstack-block-storage
# Recipe:: cinder-common
#
# Copyright:: 2019-2021, Oregon State Univerity
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
# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
end

if node['openstack']['block-storage']['syslog']['use']
  include_recipe 'openstack-common::logging'
end

platform_options = node['openstack']['block-storage']['platform']

package platform_options['cinder_common_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

db_user = node['openstack']['db']['block_storage']['username']
db_pass = get_password 'db', 'cinder'
node.default['openstack']['block-storage']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('block_storage', db_user, db_pass)

if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['block-storage']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('block_storage', db_user, db_pass, true)
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['block-storage']['conf_secrets']['DEFAULT']['transport_url'] =
    rabbit_transport_url 'block_storage'
end

glance_api_endpoint = internal_endpoint 'image_api'
cinder_api_bind = node['openstack']['bind_service']['all']['block-storage']
cinder_api_bind_address = bind_address cinder_api_bind
identity_endpoint = internal_endpoint 'identity'
node.default['openstack']['block-storage']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-block-storage'

if node['openstack']['block-storage']['conf']['nova']['auth_type'] == 'password'
  node.default['openstack']['block-storage']['conf_secrets']
  .[]('nova')['password'] =
    get_password 'service', 'openstack-compute'
end

auth_url = identity_endpoint.to_s

directory '/etc/cinder' do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode '750'
  action :create
end

node.default['openstack']['block-storage']['conf'].tap do |conf|
  conf['DEFAULT']['my_ip'] = cinder_api_bind_address
  conf['DEFAULT']['glance_api_servers'] = glance_api_endpoint.to_s
  conf['DEFAULT']['osapi_volume_listen'] = cinder_api_bind_address
  conf['DEFAULT']['osapi_volume_listen_port'] = cinder_api_bind['port']
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['nova']['auth_url'] = auth_url
end

# Todo(jr): Make this configurable depending on backend to be used
# This needs to be explicitly configured since Ocata
node.default['openstack']['block-storage']['conf'].tap do |conf|
  conf['DEFAULT']['enabled_backends'] = 'lvm'
  conf['lvm']['volume_driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
  conf['lvm']['volume_group'] = 'cinder-volumes'
  conf['lvm']['iscsi_protocol'] = 'iscsi'
  conf['lvm']['iscsi_helper'] = 'tgtadm'
end

# merge all config options and secrets to be used in the cinder.conf.erb
cinder_conf_options = merge_config_options 'block-storage'

# service['apache2'] is defined in the apache2_default_install resource
# but other resources are currently unable to reference it.  To work
# around this issue, define the following helper in your cookbook:
service 'apache2' do
  extend Apache2::Cookbook::Helpers
  service_name lazy { apache_platform_service_name }
  supports restart: true, status: true, reload: true
  action :nothing
end

template '/etc/cinder/cinder.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode '640'
  sensitive true
  variables(
    service_config: cinder_conf_options
  )
  notifies :restart, 'service[apache2]'
end

# delete all secrets saved in the attribute
# node['openstack']['block-storage']['conf_secrets'] after creating the cinder.conf
ruby_block "delete all attributes in node['openstack']['block-storage']['conf_secrets']" do
  block do
    node.rm(:openstack, :'block-storage', :conf_secrets)
  end
end

directory node['openstack']['block-storage']['conf']['oslo_concurrency']['lock_path'] do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  recursive true
  mode '755'
end

if node['openstack']['block-storage']['use_rootwrap']
  template '/etc/cinder/rootwrap.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner 'root'
    group 'root'
    mode '644'
    variables(
      service_config: node['openstack']['block-storage']['rootwrap']['conf']
    )
  end
end
