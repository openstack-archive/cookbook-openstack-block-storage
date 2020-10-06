#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'
    include_examples 'creates_cinder_conf', 'service[cinder-volume]', 'cinder', 'cinder'

    it do
      expect(chef_run).to upgrade_package %w(python3-cinder cinder-volume qemu-utils thin-provisioning-tools)
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service 'cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service 'cinder-volume'
    end

    it 'starts iscsi target on boot' do
      expect(chef_run).to enable_service 'iscsitarget'
    end

    it 'upgrades mysql python3 packages by default' do
      expect(chef_run).to upgrade_package 'python3-mysqldb'
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package 'targetcli-fb'
    end
  end
end
