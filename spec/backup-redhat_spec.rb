#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::backup' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'block-storage-stubs'

      describe 'enable cinder backup service' do
        before do
          node.override['openstack']['block-storage']['backup']['enabled'] = true
        end

        it 'starts cinder backup' do
          expect(chef_run).to start_service 'openstack-cinder-backup'
        end

        it 'starts cinder backup on boot' do
          expect(chef_run).to enable_service 'openstack-cinder-backup'
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
end
