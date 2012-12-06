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

include_recipe "cinder::common"

class ::Chef::Recipe
  include ::Openstack
end

platform_options = node["cinder"]["platform"]

platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  action :enable
end

identity_admin_endpoint = endpoint "identity-admin"
identity_endpoint = endpoint "identity-api"

template "/etc/cinder/api-paste.ini" do
  source "api-paste.ini.erb"
  group node["cinder"]["group"]
  owner node["cinder"]["user"]
  mode 00644
  variables(
    "identity_endpoint" => identity_endpoint,
    "identity_admin_endpoint" => identity_admin_endpoint,
  )
  notifies :restart, resources(:service => "cinder-api"), :immediately
end
