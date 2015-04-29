# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades cinder scheduler package' do
      expect(chef_run).to upgrade_package 'openstack-cinder-scheduler'
    end

    it 'starts cinder scheduler' do
      expect(chef_run).to start_service 'openstack-cinder-scheduler'
    end

    it 'starts cinder scheduler on boot' do
      expect(chef_run).to enable_service 'openstack-cinder-scheduler'
    end

    it 'does not upgrade stevedore' do
      expect(chef_run).not_to upgrade_python_pip 'stevedore'
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package 'python-mysql'
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysql'
    end
  end
end
