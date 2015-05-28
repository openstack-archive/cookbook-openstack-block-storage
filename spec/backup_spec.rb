# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::backup' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    describe 'enable cinder backup service' do
      before do
        node.set['openstack']['block-storage']['backup']['enabled'] = true
      end
      it 'upgrades cinder backup package' do
        expect(chef_run).to upgrade_package 'cinder-backup'
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

      it 'upgrades mysql python package' do
        expect(chef_run).to upgrade_package 'python-mysqldb'
      end

      it 'upgrades postgresql python packages if explicitly told' do
        node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

        expect(chef_run).to upgrade_package 'python-psycopg2'
        expect(chef_run).not_to upgrade_package 'python-mysqldb'
      end
    end

    describe 'disable cinder backup service' do
      before do
        node.set['openstack']['block-storage']['backup']['enabled'] = false
      end
      it 'not to upgrades cinder backup package' do
        expect(chef_run).not_to upgrade_package 'cinder-backup'
      end

      it 'not to starts cinder backup' do
        expect(chef_run).not_to start_service 'cinder-backup'
      end

      it 'not to starts cinder backup on boot' do
        expect(chef_run).not_to enable_service 'cinder-backup'
      end

      it 'not to subscribes to the template change' do
        expect(chef_run.service('cinder-backup')).not_to subscribe_to('template[/etc/cinder/cinder.conf]')
      end

      it 'not to upgrades mysql python package' do
        expect(chef_run).not_to upgrade_package 'python-mysqldb'
      end

      it 'not to upgrades postgresql python packages if explicitly told' do
        node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

        expect(chef_run).not_to upgrade_package 'python-psycopg2'
        expect(chef_run).not_to upgrade_package 'python-mysqldb'
      end
    end
  end
end
