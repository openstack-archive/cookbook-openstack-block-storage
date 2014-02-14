# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  before { block_storage_stubs }
  describe 'suse' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-block-storage::api'
    end

    it 'installs cinder api packages' do
      expect(@chef_run).to upgrade_package 'openstack-cinder-api'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'python-mysql'
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      node.set['cpu']['total'] = 1
      chef_run.converge 'openstack-block-storage::api'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysql'
    end

    it 'starts cinder api on boot' do
      expect(@chef_run).to enable_service 'openstack-cinder-api'
    end

    expect_creates_policy_json(
      'service[cinder-api]', 'openstack-cinder', 'openstack-cinder')
    expect_creates_cinder_conf(
      'service[cinder-api]', 'openstack-cinder', 'openstack-cinder')
  end
end
