#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::backup' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    describe 'enable cinder backup service' do
      before do
        node.override['openstack']['block-storage']['backup']['enabled'] = true
      end

      it 'starts cinder backup' do
        expect(chef_run).to start_service 'openstack-cinder-backup'
      end

      it 'starts cinder backup on boot' do
        expect(chef_run).to enable_service 'openstack-cinder-backup'
      end

      it 'upgrades mysql python package' do
        expect(chef_run).to upgrade_package 'MySQL-python'
      end
    end
  end
end
