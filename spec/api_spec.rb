# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'

    expect_creates_cinder_conf 'service[cinder-api]', 'cinder', 'cinder'

    it 'upgrades cinder api packages' do
      expect(chef_run).to upgrade_package('cinder-api')
      expect(chef_run).to upgrade_package('python-cinderclient')
    end

    it 'starts cinder api on boot' do
      expect(chef_run).to enable_service('cinder-api')
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package('python-psycopg2')
      expect(chef_run).not_to upgrade_package('python-mysqldb')
    end

    describe '/var/cache/cinder' do
      let(:dir) { chef_run.directory('/var/cache/cinder') }

      it 'should create the directory' do
        expect(chef_run).to create_directory(dir.name).with(
          owner: 'cinder',
          group: 'cinder',
          mode: 00700
        )
      end
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('cinder-manage db sync').with(user: 'cinder', group: 'cinder')
    end

    describe 'policy file' do
      it 'does not manage policy file unless specified' do
        expect(chef_run).not_to create_remote_file('/etc/cinder/policy.json')
      end
      describe 'policy file specified' do
        before { node.set['openstack']['block-storage']['policyfile_url'] = 'http://server/mypolicy.json' }
        let(:remote_policy) { chef_run.remote_file('/etc/cinder/policy.json') }

        it 'manages policy file when remote file is specified' do
          expect(chef_run).to create_remote_file('/etc/cinder/policy.json').with(
            user: 'cinder',
            group: 'cinder',
            mode: 00644)
        end
      end
    end
  end
end
