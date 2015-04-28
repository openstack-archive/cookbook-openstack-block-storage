# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades the openstack-cinder package' do
      expect(chef_run).to upgrade_package 'openstack-cinder'
    end
  end
end
