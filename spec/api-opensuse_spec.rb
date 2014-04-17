# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'installs cinder api packages' do
      expect(chef_run).to upgrade_package 'openstack-cinder-api'
    end

    it 'installs mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysql'
    end

    it 'installs postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysql'
    end

    it 'starts cinder api on boot' do
      expect(chef_run).to enable_service 'openstack-cinder-api'
    end

    expect_creates_cinder_conf(
      'service[cinder-api]', 'openstack-cinder', 'openstack-cinder')
  end
end
