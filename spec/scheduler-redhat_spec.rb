#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'block-storage-stubs'

      it 'upgrades cinder scheduler package' do
        expect(chef_run).to upgrade_package 'openstack-cinder'
      end

      it 'starts cinder scheduler' do
        expect(chef_run).to start_service 'openstack-cinder-scheduler'
      end

      it 'starts cinder scheduler on boot' do
        expect(chef_run).to enable_service 'openstack-cinder-scheduler'
      end

      case p
      when REDHAT_7
        it 'upgrades mysql python package' do
          expect(chef_run).to upgrade_package 'MySQL-python'
        end
      when REDHAT_8
        it 'upgrades mysql python package' do
          expect(chef_run).to upgrade_package 'python3-PyMySQL'
        end
      end
    end
  end
end
