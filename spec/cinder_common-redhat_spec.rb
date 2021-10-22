#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'block-storage-stubs'

      it 'upgrades the openstack-cinder package' do
        expect(chef_run).to upgrade_package 'openstack-cinder'
      end
    end
  end
end
