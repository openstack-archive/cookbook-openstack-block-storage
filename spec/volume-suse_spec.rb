# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  before { block_storage_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-block-storage::volume'
    end

    it 'installs cinder volume packages' do
      expect(@chef_run).to upgrade_package 'openstack-cinder-volume'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'python-mysql'
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      node = chef_run.node
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      node.set['cpu']['total'] = 1
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysql'
    end

    it 'installs cinder iscsi packages' do
      expect(@chef_run).to upgrade_package 'tgt'
    end

    it 'starts cinder volume' do
      expect(@chef_run).to start_service 'openstack-cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expected = 'openstack-cinder-volume'
      expect(@chef_run).to enable_service expected
    end

    it 'starts iscsi target on boot' do
      expect(@chef_run).to enable_service 'tgtd'
    end

    it 'installs nfs packages' do
      chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
      end
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).to upgrade_package 'nfs-utils'
      expect(chef_run).not_to upgrade_package 'nfs-utils-lib'
    end

    it 'has suse include' do
      file = '/etc/tgt/targets.conf'

      expect(@chef_run).to render_file(file).with_content('include /var/lib/cinder/volumes/*')
      expect(@chef_run).not_to render_file(file).with_content('include /etc/tgt/conf.d/*.conf')
    end
  end
end
