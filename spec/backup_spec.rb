#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::backup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    describe 'enable cinder backup service' do
      it do
        expect(chef_run).to upgrade_package %w(python3-cinder cinder-backup)
      end

      it 'starts cinder backup' do
        expect(chef_run).to start_service 'cinder-backup'
      end

      it 'starts cinder backup on boot' do
        expect(chef_run).to enable_service 'cinder-backup'
      end

      it 'subscribes to the template change' do
        expect(chef_run.service('cinder-backup')).to subscribe_to('template[/etc/cinder/cinder.conf]')
      end

      it 'upgrades mysql python3 package' do
        expect(chef_run).to upgrade_package 'python3-mysqldb'
      end
    end
  end
end
