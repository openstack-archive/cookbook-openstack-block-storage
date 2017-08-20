# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('MySQL-python')
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package('python-psycopg2')
      expect(chef_run).not_to upgrade_package('MySQL-python')
    end

    it 'upgrades qemu-img-ev package' do
      expect(chef_run).to upgrade_package('qemu-img-ev')
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package('targetcli')
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service('openstack-cinder-volume')
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service('openstack-cinder-volume')
    end

    context 'ISCSI' do
      it 'starts iscsi target on boot' do
        expect(chef_run).to enable_service('target')
      end
    end
  end
end
