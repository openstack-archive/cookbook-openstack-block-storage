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
    include_examples 'creates_cinder_conf', 'execute[Clear cinder-api apache restart]', 'cinder', 'cinder', 'run'

    it do
      expect(chef_run).to nothing_execute('Clear cinder-api apache restart')
        .with(
          command: 'rm -f /var/chef/cache/cinder-api-apache-restarted'
        )
    end

    %w(
      /etc/cinder/cinder.conf
      /etc/apache2/sites-available/cinder-api.conf
    ).each do |f|
      it "#{f} notifies execute[Clear cinder-api apache restart]" do
        expect(chef_run.template(f)).to notify('execute[Clear cinder-api apache restart]').to(:run).immediately
      end
    end

    it do
      expect(chef_run).to run_execute('cinder-api apache restart')
        .with(
          command: 'touch /var/chef/cache/cinder-api-apache-restarted',
          creates: '/var/chef/cache/cinder-api-apache-restarted'
        )
    end

    it do
      expect(chef_run.execute('cinder-api apache restart')).to notify('service[apache2]').to(:restart).immediately
    end

    it 'upgrades cinder api packages' do
      expect(chef_run).to upgrade_package('libapache2-mod-wsgi-py3')
      expect(chef_run).to upgrade_package('python3-cinder')
      expect(chef_run).to upgrade_package('cinder-api')
    end

    it 'upgrades mysql python3 package' do
      expect(chef_run).to upgrade_package('python3-mysqldb')
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('cinder-manage db sync').with(user: 'cinder', group: 'cinder')
    end

    describe 'policy file' do
      it 'does not manage policy file unless specified' do
        expect(chef_run).not_to create_remote_file('/etc/cinder/policy.json')
      end
      describe 'policy file specified' do
        before { node.override['openstack']['block-storage']['policyfile_url'] = 'http://server/mypolicy.json' }
        let(:remote_policy) { chef_run.remote_file('/etc/cinder/policy.json') }

        it 'manages policy file when remote file is specified' do
          expect(chef_run).to create_remote_file('/etc/cinder/policy.json').with(
            user: 'cinder',
            group: 'cinder',
            mode: 0o0644
          )
        end
      end
    end
  end
end
