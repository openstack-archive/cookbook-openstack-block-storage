# encoding: UTF-8
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

platform_options['cinder_common_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

db_user = node['openstack']['db']['block-storage']['username']
db_pass = get_password 'db', 'cinder'
node.default['openstack']['block-storage']['conf_secrets']
  .[]('database')['connection'] =
  db_uri('block-storage', db_user, db_pass)

if node['openstack']['endpoints']['db']['enabled_slave']
  node.default['openstack']['block-storage']['conf_secrets']
    .[]('database')['slave_connection'] =
    db_uri('block-storage', db_user, db_pass, true)
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['block-storage']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'block-storage'
end

glance_api_endpoint = internal_endpoint 'image_api'
cinder_api_bind = node['openstack']['bind_service']['all']['block-storage']
cinder_api_bind_address = bind_address cinder_api_bind
identity_endpoint = internal_endpoint 'identity'
identity_admin_endpoint = admin_endpoint 'identity'
node.default['openstack']['block-storage']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-block-storage'
auth_uri = identity_endpoint.to_s
auth_url = identity_admin_endpoint.to_s

directory '/etc/cinder' do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 0o0750
  action :create
end

node.default['openstack']['block-storage']['conf'].tap do |conf|
  conf['DEFAULT']['my_ip'] = cinder_api_bind_address
  conf['DEFAULT']['glance_api_servers'] = glance_api_endpoint.to_s
  conf['DEFAULT']['osapi_volume_listen'] = cinder_api_bind_address
  conf['DEFAULT']['osapi_volume_listen_port'] = cinder_api_bind['port']
  conf['keystone_authtoken']['auth_uri'] = auth_uri
  conf['keystone_authtoken']['auth_url'] = auth_url
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

service 'cinder-apache2' do
  case node['platform_family']
  when 'debian'
    service_name 'apache2'
  when 'rhel'
    service_name 'httpd'
  end
  action :nothing
end

template '/etc/cinder/cinder.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 0o0640
  variables(
    service_config: cinder_conf_options
  )
  notifies :restart, 'service[cinder-apache2]'
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
  mode 0o0755
end

if node['openstack']['block-storage']['use_rootwrap']
  template '/etc/cinder/rootwrap.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner 'root'
    group 'root'
    mode 0o0644
    variables(
      service_config: node['openstack']['block-storage']['rootwrap']['conf']
    )
  end
end
