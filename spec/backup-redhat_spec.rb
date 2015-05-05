# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::backup' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    describe 'enable cinder backup service' do
      before do
        node.set['openstack']['block-storage']['backup']['enabled'] = true
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

      it 'upgrades db2 python packages if explicitly told' do
        node.set['openstack']['db']['block-storage']['service_type'] = 'db2'

        ['python-ibm-db', 'python-ibm-db-sa'].each do |pkg|
          expect(chef_run).to upgrade_package pkg
        end
      end

      it 'upgrades postgresql python packages if explicitly told' do
        node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

        expect(chef_run).to upgrade_package 'python-psycopg2'
        expect(chef_run).not_to upgrade_package 'MySQL-python'
      end
    end
  end
end
