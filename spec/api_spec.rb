# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'

    expect_creates_cinder_conf 'service[cinder-api]', 'cinder', 'cinder'

    it 'installs cinder api packages' do
      expect(chef_run).to upgrade_package('cinder-api')
      expect(chef_run).to upgrade_package('python-cinderclient')
    end

    it 'starts cinder api on boot' do
      expect(chef_run).to enable_service('cinder-api')
    end

    it 'installs mysql python packages by default' do
      expect(chef_run).to upgrade_package('python-mysqldb')
    end

    it 'installs postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package('python-psycopg2')
      expect(chef_run).not_to upgrade_package('python-mysqldb')
    end

    describe '/var/cache/cinder' do
      let(:dir) { chef_run.directory('/var/cache/cinder') }

      it 'has proper owner' do
        expect(dir.owner).to eq('cinder')
        expect(dir.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', dir.mode)).to eq('700')
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

      it 'runs logging recipe if node attributes say to' do
        node.set['openstack']['block-storage']['syslog']['use'] = true

        expect(chef_run).to render_file(file.name).with_content('log_config = /etc/openstack/logging.conf')
      end

      context 'rdb driver' do
        before do
          node.set['openstack']['block-storage']['volume'] = {
            'driver' => 'cinder.volume.drivers.rbd.RBDDriver'
          }
        end

        # FIXME(galstrom21): this block needs to check all of the default
        #   rdb_* configuration options
        it 'has default rbd_* options set' do
          expect(chef_run).to render_file(file.name).with_content(/^rbd_/)
          expect(chef_run).not_to render_file(file.name).with_content(/^netapp_/)
        end
      end

      context 'netapp driver' do
        before do
          node.set['openstack']['block-storage']['volume'] = {
            'driver' => 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
          }
        end

        # FIXME(galstrom21): this block needs to check all of the default
        #   netapp_* configuration options
        it 'has default netapp_* options set' do
          expect(chef_run).to render_file(file.name).with_content(/^netapp_/)
          expect(chef_run).not_to render_file(file.name).with_content(/^rbd_/)
        end
      end
    end

    it 'runs db migrations' do
      expect(chef_run).to run_execute('cinder-manage db sync')
    end

    describe 'api-paste.ini' do
      let(:file) { chef_run.template('/etc/cinder/api-paste.ini') }

      it 'has proper owner' do
        expect(file.owner).to eq('cinder')
        expect(file.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', file.mode)).to eq('644')
      end

      it 'has signing_dir' do
        expect(chef_run).to render_file(file.name).with_content('signing_dir = /var/cache/cinder/api')
      end

      it 'notifies cinder-api restart' do
        expect(file).to notify('service[cinder-api]').to(:restart)
      end

      it 'has auth_uri' do
        expect(chef_run).to render_file(file.name).with_content('auth_uri = http://127.0.0.1:5000/v2.0')
      end

      it 'has auth_host' do
        expect(chef_run).to render_file(file.name).with_content('auth_host = 127.0.0.1')
      end

      it 'has auth_port' do
        expect(chef_run).to render_file(file.name).with_content('auth_port = 35357')
      end

      it 'has auth_protocol' do
        expect(chef_run).to render_file(file.name).with_content('auth_protocol = http')
      end

      it 'has no auth_version when auth_version is v2.0' do
        expect(chef_run).not_to render_file(file.name).with_content('auth_version = v2.0')
      end

      it 'has auth_version when auth version is not v2.0' do
        node.set['openstack']['block-storage']['api']['auth']['version'] = 'v3.0'

        expect(chef_run).to render_file(file.name).with_content('auth_version = v3.0')
      end
    end
  end
end
