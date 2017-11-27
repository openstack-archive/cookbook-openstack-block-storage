# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: volume_driver_lvm
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

platform_options = node['openstack']['block-storage']['platform']
platform_options['cinder_lvm_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

# TODO: (jklare) this whole section should be refactored and probably include an
# external cookbook for managing lvm stuff

vg_name = node['openstack']['block-storage']['conf']['DEFAULT']['volume_group']
case node['openstack']['block-storage']['volume']['create_volume_group_type']
when 'file'
  volume_size = node['openstack']['block-storage']['volume']['volume_group_size']
  seek_count = volume_size.to_i * 1024
  vg_file = "#{node['openstack']['block-storage']['conf']['DEFAULT']['state_path']}/#{vg_name}.img"

  # create volume group
  execute 'Create Cinder loopback file' do
    command "dd if=/dev/zero of=#{vg_file} bs=1M seek=#{seek_count} count=0; vgcreate #{vg_name} $(losetup --show -f #{vg_file})"
    action :run
    not_if "pvs | grep -c #{vg_name}"
  end
when 'block_devices'
  block_devices = node['openstack']['block-storage']['volume']['block_devices']

  lvm_physical_volume block_devices do
    action :create
    not_if "pvs | grep -c #{block_devices}"
  end

  lvm_volume_group vg_name do
    physical_volumes [block_devices]
    wipe_signatures true
    not_if "vgs #{vg_name}"
  end
end
