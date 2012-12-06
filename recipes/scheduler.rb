#
# Cookbook Name:: cinder
# Recipe:: scheduler
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

platform_options = node["cinder"]["platform"]

platform_options["cinder_scheduler_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

service "cinder-scheduler" do
  service_name platform_options["cinder_scheduler_service"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
end
