#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'block-storage-stubs'

      case p
      when REDHAT_7
        it do
          expect(chef_run).to upgrade_package('MySQL-python')
        end

        it do
          expect(chef_run).to upgrade_package('qemu-img-ev')
        end

        it do
          expect(chef_run).to upgrade_package %w(targetcli dbus-python)
        end
      when REDHAT_8
        it do
          expect(chef_run).to upgrade_package('python3-PyMySQL')
        end

        it do
          expect(chef_run).to upgrade_package('qemu-img')
        end

        it do
          expect(chef_run).to upgrade_package %w(targetcli python3-dbus)
        end
      end

      it do
        expect(chef_run).to start_service('openstack-cinder-volume')
      end

      it do
        expect(chef_run).to enable_service('openstack-cinder-volume')
      end

      context 'ISCSI' do
        it do
          expect(chef_run).to enable_service('iscsitarget')
        end
      end
    end
  end
end
