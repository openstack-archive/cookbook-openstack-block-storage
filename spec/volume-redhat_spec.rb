#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('MySQL-python')
    end

    it 'upgrades qemu-img-ev package' do
      expect(chef_run).to upgrade_package('qemu-img-ev')
    end

    it do
      expect(chef_run).to upgrade_package %w(targetcli dbus-python)
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service('openstack-cinder-volume')
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service('openstack-cinder-volume')
    end

    context 'ISCSI' do
      it 'starts iscsi target on boot' do
        expect(chef_run).to enable_service('iscsitarget')
      end
    end
  end
end
