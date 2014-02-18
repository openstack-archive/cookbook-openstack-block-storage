# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  before { block_storage_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      @chef_run.converge 'openstack-block-storage::scheduler'
    end

    it 'installs cinder scheduler packages' do
      expect(@chef_run).to upgrade_package 'openstack-cinder-scheduler'
    end

    it 'does not upgrade stevedore' do
      chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      chef_run.converge 'openstack-block-storage::scheduler'

      expect(chef_run).not_to upgrade_python_pip 'stevedore'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'python-mysql'
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      chef_run.converge 'openstack-block-storage::scheduler'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysql'
    end

    it 'starts cinder scheduler' do
      expect(@chef_run).to start_service 'openstack-cinder-scheduler'
    end

    it 'starts cinder scheduler on boot' do
      expect(@chef_run).to enable_service 'openstack-cinder-scheduler'
    end
  end
end
