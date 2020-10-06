#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'
    include_examples 'creates_cinder_conf', 'service[cinder-scheduler]', 'cinder', 'cinder'

    it do
      expect(chef_run).to upgrade_package %w(python3-cinder cinder-scheduler)
    end

    it 'starts cinder scheduler' do
      expect(chef_run).to start_service 'cinder-scheduler'
    end

    it 'starts cinder scheduler on boot' do
      expect(chef_run).to enable_service 'cinder-scheduler'
    end

    it 'upgrades mysql python3 package' do
      expect(chef_run).to upgrade_package 'python3-mysqldb'
    end
  end
end
