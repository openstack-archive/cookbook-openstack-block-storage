# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it do
      expect(chef_run).to_not create_file('/etc/apache2/conf-available/cinder-wsgi.conf')
    end

    it 'upgrades cinder api package' do
      expect(chef_run).to upgrade_package 'openstack-cinder'
      expect(chef_run).to upgrade_package 'mod_wsgi'
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package 'MySQL-python'
    end
  end
end
