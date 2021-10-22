#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  ALL_RHEL.each do |p|
    context "redhat #{p[:version]}" do
      let(:runner) { ChefSpec::SoloRunner.new(p) }
      let(:node) { runner.node }
      cached(:chef_run) { runner.converge(described_recipe) }

      include_context 'block-storage-stubs'

      it do
        expect(chef_run).to_not create_file('/etc/apache2/conf-available/cinder-wsgi.conf')
      end

      it do
        expect(chef_run).to upgrade_package %w(openstack-cinder)
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
