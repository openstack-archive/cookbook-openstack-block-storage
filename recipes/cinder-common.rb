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
#

class ::Chef::Recipe # rubocop:disable Documentation
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
sql_connection = db_uri('block-storage', db_user, db_pass)
if node['openstack']['endpoints']['db']['enabled_slave']
  slave_connection = db_uri('block-storage', db_user, db_pass, true)
end

mq_service_type = node['openstack']['mq']['block-storage']['service_type']

if mq_service_type == 'rabbitmq'
  if node['openstack']['mq']['block-storage']['rabbit']['ha']
    rabbit_hosts = rabbit_servers
  end
  mq_password = get_password 'user', node['openstack']['mq']['block-storage']['rabbit']['userid']
elsif mq_service_type == 'qpid'
  mq_password = get_password 'user', node['openstack']['mq']['block-storage']['qpid']['username']
end

case node['openstack']['block-storage']['volume']['driver']
when 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
  if node['openstack']['block-storage']['storwize']['san_private_key'].to_s.empty?
    storwize_pass = get_password 'user', node['openstack']['block-storage']['storwize']['san_login']
  end
when 'cinder.volume.drivers.solidfire.SolidFire'
  solidfire_pass = get_password 'user', node['openstack']['block-storage']['solidfire']['san_login']
when 'cinder.volume.drivers.ibm.flashsystem.FlashSystemDriver'
  flashsystem_pass = get_password 'user', node['openstack']['block-storage']['flashsystem']['san_login']
when 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
  ibmnas_pass = get_password 'user', node['openstack']['block-storage']['ibmnas']['nas_login']
when 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver'
  vmware_host_pass = get_password 'token', node['openstack']['block-storage']['vmware']['secret_name']
end

glance_api_endpoint = internal_endpoint 'image-api'
cinder_api_bind = endpoint 'block-storage-api-bind'

directory '/etc/cinder' do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 00750
  action :create
end

multi_backend_sections = {}
multi_backend = node['openstack']['block-storage']['volume']['multi_backend']
if multi_backend.nil?
  enabled_drivers = [node['openstack']['block-storage']['volume']['driver']]
else
  enabled_drivers = []
  multi_backend.each do |drv, options|
    optlines = []
    options.each do |optkey, optvalue|
      optlines.push "#{optkey} = #{optvalue}"
      enabled_drivers.push optvalue if optkey == 'volume_driver'
    end
    multi_backend_sections[drv] = optlines
  end
end

identity_endpoint = internal_endpoint 'identity-internal'
identity_admin_endpoint = admin_endpoint 'identity-admin'
service_pass = get_password 'service', 'openstack-block-storage'

auth_uri = auth_uri_transform(identity_endpoint.to_s, node['openstack']['block-storage']['api']['auth']['version'])
identity_uri = identity_uri_transform(identity_admin_endpoint)

template '/etc/cinder/cinder.conf' do
  source 'cinder.conf.erb'
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 00640
  variables(
    sql_connection: sql_connection,
    slave_connection: slave_connection,
    mq_service_type: mq_service_type,
    mq_password: mq_password,
    rabbit_hosts: rabbit_hosts,
    glance_scheme: glance_api_endpoint.scheme,
    glance_host: glance_api_endpoint.host,
    glance_port: glance_api_endpoint.port,
    ibmnas_pass: ibmnas_pass,
    solidfire_pass: solidfire_pass,
    flashsystem_pass: flashsystem_pass,
    storwize_pass: storwize_pass,
    volume_api_bind_address: cinder_api_bind.host,
    volume_api_bind_port: cinder_api_bind.port,
    vmware_host_pass: vmware_host_pass,
    enabled_drivers: enabled_drivers,
    multi_backend_sections: multi_backend_sections,
    auth_uri: auth_uri,
    identity_uri: identity_uri,
    service_pass: service_pass
  )
end

directory node['openstack']['block-storage']['lock_path'] do
  group node['openstack']['block-storage']['group']
  owner node['openstack']['block-storage']['user']
  mode 00755
end

template '/etc/cinder/rootwrap.conf' do
  source 'rootwrap.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
end
