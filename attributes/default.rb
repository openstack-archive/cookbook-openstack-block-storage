#
# Cookbook Name:: cinder
# Attributes:: default
#
# Copyright 2012, DreamHost
# Copyright 2012, Rackspace US, Inc.
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

########################################################################
# Toggles - These can be overridden at the environment level
default["developer_mode"] = false  # we want secure passwords by default
########################################################################

default["openstack"]["cinder"]["services"]["volume"]["scheme"] = "http"
default["openstack"]["cinder"]["services"]["volume"]["network"] = "public"
default["openstack"]["cinder"]["services"]["volume"]["port"] = 8776
default["openstack"]["cinder"]["services"]["volume"]["path"] = "/v1"

default["cinder"]["services"]["volume"]["scheme"] = "http"
default["cinder"]["services"]["volume"]["network"] = "public"
default["cinder"]["services"]["volume"]["port"] = 8776
default["cinder"]["services"]["volume"]["path"] = "/v1"

default["openstack"]["cinder"]["db"]["name"] = "cinder"
default["openstack"]["cinder"]["db"]["username"] = "cinder"

# TODO: These may need to be glance-registry specific.. and looked up by glance-api
default["openstack"]["cinder"]["service_tenant_name"] = "service"
default["openstack"]["cinder"]["service_user"] = "cinder"
default["openstack"]["cinder"]["service_role"] = "admin"

# logging attribute
default["openstack"]["cinder"]["syslog"]["use"] = false
default["openstack"]["cinder"]["syslog"]["facility"] = "LOG_LOCAL2"
default["openstack"]["cinder"]["syslog"]["config_facility"] = "local2"

# platform-specific settings
case platform
when "fedora", "redhat", "centos"
  default["openstack"]["cinder"]["platform"] = {
    "mysql_python_packages" => [ "MySQL-python" ],
    "cinder_packages" => [ "openstack-cinder", "openstack-swift" ],
    "package_overrides" => ""
  }
when "ubuntu"
  default["openstack"]["cinder"]["platform"] = {
    "mysql_python_packages" => [ "python-mysqldb" ],
    "cinder_packages" => [ "cinder-scheduler", "python-swift", "python-keystoneclient", "cinder-volume", "cinder-api" ],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'",
    "cinder_api_service" => "cinder-api",
    "cinder_scheduler_service" => "cinder-scheduler",
    "cinder_volume_service" => "cinder-volume"
  }
end
