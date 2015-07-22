# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage
# Recipe:: volume
#
# Copyright 2012, Rackspace US, Inc.
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013, Opscode, Inc.
# Copyright 2013-2014, SUSE Linux Gmbh.
# Copyright 2013, IBM, Corp.
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

# Chef
class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-block-storage::cinder-common'

platform_options = node['openstack']['block-storage']['platform']

platform_options['cinder_volume_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

db_type = node['openstack']['db']['block-storage']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
end

platform_options['cinder_iscsitarget_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

case node['openstack']['block-storage']['volume']['driver']
when 'cinder.volume.drivers.netapp.iscsi.NetAppISCSIDriver'
  node.override['openstack']['block-storage']['netapp']['dfm_password'] = get_password 'service', 'netapp'

when 'cinder.volume.drivers.rbd.RBDDriver'
  include_recipe 'ceph'

  cinder_pool = node['openstack']['block-storage']['rbd']['cinder']['pool']
  nova_pool = node['openstack']['block-storage']['rbd']['nova']['pool']
  glance_pool =  node['openstack']['block-storage']['rbd']['glance']['pool']

  caps = { 'mon' => 'allow r',
           'osd' => "allow class-read object_prefix rbd_children, allow rwx pool=#{cinder_pool}, allow rwx pool=#{nova_pool}, allow rx pool=#{glance_pool}" }

  ceph_client node['openstack']['block-storage']['rbd']['user'] do
    name node['openstack']['block-storage']['rbd']['user']
    caps caps
    keyname "client.#{node['openstack']['block-storage']['rbd']['user']}"
    filename "/etc/ceph/ceph.client.#{node['openstack']['block-storage']['rbd']['user']}.keyring"
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']

    action :add
    notifies :restart, 'service[cinder-volume]'
  end

when 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
  node.override['openstack']['block-storage']['netapp']['netapp_server_password'] = get_password 'service', 'netapp-filer'

  directory node['openstack']['block-storage']['nfs']['mount_point_base'] do
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    action :create
  end

  template node['openstack']['block-storage']['nfs']['shares_config'] do
    source 'shares.conf.erb'
    mode '0600'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    variables(
      host: node['openstack']['block-storage']['netapp']['netapp_server_hostname'],
      export: node['openstack']['block-storage']['netapp']['export']
    )
    notifies :restart, 'service[cinder-volume]'
  end

  platform_options['cinder_nfs_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

when 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
  san_private_key = node['openstack']['block-storage']['storwize']['san_private_key']
  san_private_key_url = node['openstack']['block-storage']['storwize']['san_private_key_url']

  if san_private_key && san_private_key_url
    remote_file san_private_key do
      source san_private_key_url
      mode '0400'
      owner node['openstack']['block-storage']['user']
      group node['openstack']['block-storage']['group']
    end
  end

  platform_options['cinder_svc_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

when 'cinder.volume.drivers.ibm.flashsystem.FlashSystemDriver'
  platform_options['cinder_flashsystem_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

when 'cinder.volume.drivers.ibm.gpfs.GPFSDriver'
  directory node['openstack']['block-storage']['gpfs']['gpfs_mount_point_base'] do
    mode '0755'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    recursive true
  end
  multi_backend = node['openstack']['block-storage']['volume']['multi_backend']
  unless multi_backend.nil?
    multi_backend.each do |_drv, options|
      options.select { |optkey, _optvalue| optkey == 'gpfs_mount_point_base' }.each do |_optkey, optvalue|
        directory optvalue do
          mode '0755'
          owner node['openstack']['block-storage']['user']
          group node['openstack']['block-storage']['group']
          recursive true
        end
      end
    end
  end

when 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
  directory node['openstack']['block-storage']['ibmnas']['mount_point_base'] do
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    mode '0755'
    recursive true
    action :create
  end

  platform_options['cinder_nfs_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  template node['openstack']['block-storage']['ibmnas']['shares_config'] do
    source 'nfs_shares.conf.erb'
    mode '0600'
    owner node['openstack']['block-storage']['user']
    group node['openstack']['block-storage']['group']
    variables(
      host: node['openstack']['block-storage']['ibmnas']['nas_access_ip'],
      export: node['openstack']['block-storage']['ibmnas']['export']
    )
    notifies :restart, 'service[cinder-volume]'
  end

when 'cinder.volume.drivers.lvm.LVMVolumeDriver'

  platform_options['cinder_lvm_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  if node['openstack']['block-storage']['volume']['create_volume_group']
    vg_name = node['openstack']['block-storage']['volume']['volume_group']

    case node['openstack']['block-storage']['volume']['create_volume_group_type']
    when 'file'
      volume_size = node['openstack']['block-storage']['volume']['volume_group_size']
      seek_count = volume_size.to_i * 1024
      vg_file = "#{node['openstack']['block-storage']['volume']['state_path']}/#{vg_name}.img"

      # create volume group
      execute 'Create Cinder volume group' do
        command "dd if=/dev/zero of=#{vg_file} bs=1M seek=#{seek_count} count=0; vgcreate #{vg_name} $(losetup --show -f #{vg_file})"
        action :run
        not_if "vgs #{vg_name}"
      end

      template '/etc/init.d/cinder-group-active' do
        source 'cinder-group-active.erb'
        mode '755'
        variables(
          volume_name: vg_name,
          volume_file: vg_file
        )
        notifies :start, 'service[cinder-group-active]', :immediately
      end

      service 'cinder-group-active' do
        service_name 'cinder-group-active'

        action [:enable, :start]
      end

    when 'block_devices'

      block_devices = node['openstack']['block-storage']['volume']['block_devices']
      execute 'Create Cinder volume group with block devices' do
        command "pvcreate #{block_devices}; vgcreate #{vg_name} #{block_devices}"
        action :run
        not_if "vgs #{vg_name}"
      end
    end
  end

when 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
  platform_options['cinder_emc_packages'].each do |pkg|
    package pkg do
      options platform_options['package_overrides']
      action :upgrade
    end
  end

  ecom_password = get_password('user', node['openstack']['block-storage']['emc']['EcomUserName'])

  template node['openstack']['block-storage']['emc']['cinder_emc_config_file'] do
    source 'cinder_emc_config.xml.erb'
    variables(
      ecom_password: ecom_password
    )
    mode 00644
    notifies :restart, 'service[iscsitarget]', :immediately
  end
end

service 'cinder-volume' do
  service_name platform_options['cinder_volume_service']
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[/etc/cinder/cinder.conf]'
end

service 'iscsitarget' do
  service_name platform_options['cinder_iscsitarget_service']
  supports status: true, restart: true
  action :enable
end

# RHEL7 doesn't need targets.conf file
template '/etc/tgt/targets.conf' do
  source 'targets.conf.erb'
  mode 00600
  notifies :restart, 'service[iscsitarget]', :immediately
  not_if { node['platform_family'] == 'rhel' && node['platform_version'].to_i == 7 }
end
