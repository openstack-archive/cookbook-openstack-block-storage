# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: api
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Opscode, Inc.
# Copyright 2013-2014, SUSE Linux Gmbh.
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
end

include_recipe 'openstack-block-storage::cinder-common'

bind_service = node['openstack']['bind_service']['all']['block-storage']
platform_options = node['openstack']['block-storage']['platform']

platform_options['cinder_api_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

db_type = node['openstack']['db']['block_storage']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
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
    mode 0o0644
  end
end

# remove the cinder-wsgi.conf automatically generated from package
apache_config 'cinder-wsgi' do
  enable false
end

web_app 'cinder-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'cinder-wsgi'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry '/usr/bin/cinder-wsgi'
  log_dir node['apache']['log_dir']
  run_dir node['apache']['run_dir']
  user node['openstack']['block-storage']['user']
  group node['openstack']['block-storage']['group']
  use_ssl node['openstack']['block-storage']['ssl']['enabled']
  cert_file node['openstack']['block-storage']['ssl']['certfile']
  chain_file node['openstack']['block-storage']['ssl']['chainfile']
  key_file node['openstack']['block-storage']['ssl']['keyfile']
  ca_certs_path node['openstack']['block-storage']['ssl']['ca_certs_path']
  cert_required node['openstack']['block-storage']['ssl']['cert_required']
  protocol node['openstack']['block-storage']['ssl']['protocol']
  ciphers node['openstack']['block-storage']['ssl']['ciphers']
end

# Hack until Apache cookbook has lwrp's for proper use of notify restart
# apache2 after keystone if completely configured. Whenever a cinder
# config is updated, have it notify the resource which clears the lock
# so the service can be restarted.
# TODO(ramereth): This should be removed once this cookbook is updated
# to use the newer apache2 cookbook which uses proper resources.
edit_resource(:template, "#{node['apache']['dir']}/sites-available/cinder-api.conf") do
  notifies :run, 'execute[Clear cinder-api apache restart]', :immediately
end

execute 'cinder-api apache restart' do
  command "touch #{Chef::Config[:file_cache_path]}/cinder-api-apache-restarted"
  creates "#{Chef::Config[:file_cache_path]}/cinder-api-apache-restarted"
  notifies :restart, 'service[apache2]', :immediately
end
