#
# Cookbook:: openstack-block-storage
# Recipe:: api
#
# Copyright:: 2012-2021, Rackspace US, Inc.
# Copyright:: 2012-2021, AT&T Services, Inc.
# Copyright:: 2013-2021, Chef Software, Inc.
# Copyright:: 2013-2021, SUSE Linux Gmbh.
# Copyright:: 2019-2021, Oregon State University
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
# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
  include Apache2::Cookbook::Helpers
end

include_recipe 'openstack-block-storage::cinder-common'

bind_service = node['openstack']['bind_service']['all']['block-storage']
platform_options = node['openstack']['block-storage']['platform']

# create file to prevent installation of non-working configuration
file '/etc/apache2/conf-available/cinder-wsgi.conf' do
  owner 'root'
  group 'www-data'
  mode '0640'
  action :create
  content '# Chef openstack-block-storage: file to block config from package'
  only_if { platform_family? 'debian' }
end

package platform_options['cinder_api_packages'] do
  options platform_options['package_overrides']
  action :upgrade
end

db_type = node['openstack']['db']['block_storage']['service_type']
package node['openstack']['db']['python_packages'][db_type] do
  action :upgrade
end

execute 'cinder-manage db sync' do
  user node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
end

if node['openstack']['block-storage']['policyfile_url']
  remote_file '/etc/cinder/policy.json' do
    source node['openstack']['block-storage']['policyfile_url']
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    mode '644'
  end
end

# Finds and appends the listen port to the apache2_install[openstack]
# resource which is defined in openstack-identity::server-apache.
apache_resource = find_resource(:apache2_install, 'openstack')

if apache_resource
  apache_resource.listen = [apache_resource.listen, "#{bind_service['host']}:#{bind_service['port']}"].flatten
else
  apache2_install 'openstack' do
    listen "#{bind_service['host']}:#{bind_service['port']}"
  end
end

apache2_mod_wsgi 'openstack'
apache2_module 'ssl' if node['openstack']['block-storage']['ssl']['enabled']

# remove the cinder-wsgi.conf automatically generated from package
apache2_conf 'cinder-wsgi' do
  action :disable
end

template "#{apache_dir}/sites-available/cinder-api.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'cinder-wsgi',
    server_host: bind_service['host'],
    server_port: bind_service['port'],
    server_entry: '/usr/bin/cinder-wsgi',
    log_dir: default_log_dir,
    run_dir: lock_dir,
    user: node['openstack']['block-storage']['user'],
    group: node['openstack']['block-storage']['group']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site 'cinder-api' do
  notifies :restart, 'service[apache2]', :immediately
end
