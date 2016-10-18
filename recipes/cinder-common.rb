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

unless node['openstack']['block-storage']['conf']['DEFAULT']['rpc_backend'].nil?
  user = node['openstack']['mq']['block-storage']['rabbit']['userid']
  node.default['openstack']['block-storage']['conf_secrets']
    .[]('oslo_messaging_rabbit')['rabbit_userid'] = user
  node.default['openstack']['block-storage']['conf_secrets']
    .[]('oslo_messaging_rabbit')['rabbit_password'] =
    get_password 'user', user
end

glance_api_endpoint = internal_endpoint 'image_api'
cinder_api_bind = node['openstack']['bind_service']['all']['block-storage']
cinder_api_bind_address = bind_address cinder_api_bind
identity_endpoint = public_endpoint 'identity'
node.default['openstack']['block-storage']['conf_secrets']
  .[]('keystone_authtoken')['password'] =
  get_password 'service', 'openstack-block-storage'
auth_url = auth_uri_transform(identity_endpoint.to_s, node['openstack']['api']['auth']['version'])

directory '/etc/cinder' do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 00750
  action :create
end

node.default['openstack']['block-storage']['conf'].tap do |conf|
  conf['DEFAULT']['glance_host'] = glance_api_endpoint.host
  conf['DEFAULT']['glance_port'] = glance_api_endpoint.port
  conf['DEFAULT']['my_ip'] = cinder_api_bind_address
  conf['DEFAULT']['glance_api_servers'] = "#{glance_api_endpoint.scheme}://#{glance_api_endpoint.host}:#{glance_api_endpoint.port}"
  conf['DEFAULT']['osapi_volume_listen'] = cinder_api_bind_address
  conf['DEFAULT']['osapi_volume_listen_port'] = cinder_api_bind.port
  conf['keystone_authtoken']['auth_url'] = auth_url
end

# merge all config options and secrets to be used in the nova.conf.erb
cinder_conf_options = merge_config_options 'block-storage'

template '/etc/cinder/cinder.conf' do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 00640
  variables(
    service_config: cinder_conf_options
  )
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
  mode 00755
end

if node['openstack']['block-storage']['use_rootwrap']
  template '/etc/cinder/rootwrap.conf' do
    source 'openstack-service.conf.erb'
    cookbook 'openstack-common'
    owner 'root'
    group 'root'
    mode 00644
    variables(
      service_config: node['openstack']['block-storage']['rootwrap']['conf']
    )
  end
end
