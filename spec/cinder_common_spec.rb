#
# Cookbook:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:test_pass) { 'test_pass' }
    cached(:chef_run) do
      node.override['openstack']['mq']['host'] = '127.0.0.1'
      node.override['openstack']['mq']['block-storage']['rabbit']['notification_topic'] = 'rabbit_topic'
      runner.converge(described_recipe)
    end

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:get_password)
        .with('user', anything)
        .and_return(test_pass)
      allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
        .and_return('sql_connection_value')
    end

    include_context 'block-storage-stubs'

    it 'upgrades the cinder-common package' do
      expect(chef_run).to upgrade_package 'cinder-common'
    end

    describe '/etc/cinder' do
      let(:dir) { chef_run.directory('/etc/cinder') }

      it 'should create the /etc/cinder directory' do
        expect(chef_run).to create_directory(dir.name).with(
          owner: 'cinder',
          group: 'cinder',
          mode: '750'
        )
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

      it 'should create the cinder.conf template' do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          owner: 'cinder',
          group: 'cinder',
          mode: '640',
          sensitive: true
        )
      end

      describe 'keystone authtoken attributes with default values' do
        it 'does not set memcached server(s)' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcached_servers = $/)
        end

        it 'does not set memcache security strategy' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_security_strategy = $/)
        end

        it 'does not set memcache secret key' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_secret_key = $/)
        end

        it 'does not set cafile' do
          expect(chef_run).not_to render_file(file.name).with_content(/^cafile = $/)
        end
      end

      describe 'keystone authtoken attributes' do
        it do
          expect(chef_run).not_to render_file(file.name).with_content(/^auth_version = v2.0$/)
        end

        it 'has an admin password' do
          # (fgimenez) the get_password mocking is set in spec/spec_helper.rb
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('keystone_authtoken', /^password = cinder-pass$/)
        end
      end

      describe 'template contents' do
        it 'has a lock_path attribute' do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('oslo_concurrency', %r{^lock_path = /var/lib/cinder/tmp})
        end

        it 'does not have unique host id by default' do
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', /^host = /)
        end

        it 'does not have keymgr attribute fixed_key set by default' do
          expect(chef_run).not_to render_file(file.name).with_content(/^fixed_key = $/)
        end

        context 'syslog use' do
          cached(:chef_run) do
            node.override['openstack']['block-storage']['syslog']['use'] = true
            runner.converge(described_recipe)
          end
          it 'sets the log_config value when syslog is in use' do
            expect(chef_run).to render_file(file.name).with_content(%r{^log_config = /etc/openstack/logging.conf$})
          end
        end

        it 'has a db connection attribute' do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', /^connection = sql_connection_value$/)
        end

        it 'has a glance_api_servers attribute' do
          expect(chef_run).to render_config_file(file.name)
            .with_section_content('DEFAULT', %r{^glance_api_servers = http://127.0.0.1:9292$})
        end

        describe 'cinder endpoint' do
          it 'has osapi_volume_listen set' do
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('DEFAULT', /^osapi_volume_listen = 127.0.0.1$/)
          end

          it 'has osapi_volume_listen_port set' do
            expect(chef_run).to render_config_file(file.name)
              .with_section_content('DEFAULT', /^osapi_volume_listen_port = 8776$/)
          end
        end
        it 'has default transport_url/AMQP options set' do
          [
            %r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$},
          ].each do |line|
            expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
          end
        end

        describe 'rabbitmq as mq service' do
          describe 'non ha attributes' do
            it 'does not have a rabbit_hosts attribute' do
              expect(chef_run).not_to render_config_file(file.name)
                .with_section_content('oslo_messaging_rabbit', /^rabbit_hosts = /)
            end
          end
        end

        context 'commonly named volume attributes' do
          vol_attrs = %w(iscsi_ip_address iscsi_port iscsi_helper volumes_dir)
          cached(:chef_run) do
            vol_attrs.each do |attr|
              node.override['openstack']['block-storage']['conf']['DEFAULT'][attr] = "common_volume_#{attr}_value"
            end
            runner.converge(described_recipe)
          end
          vol_attrs.each do |attr|
            it "has volume related #{attr} attribute" do
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = common_volume_#{attr}_value$/)
            end
          end
        end
      end
    end

    describe '/var/lib/cinder/tmp' do
      let(:dir) { chef_run.directory('/var/lib/cinder/tmp') }

      it 'should create the /var/lib/cinder/tmp directory' do
        expect(chef_run).to create_directory(dir.name).with(
          user: 'cinder',
          group: 'cinder',
          mode: '755'
        )
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/cinder/rootwrap.conf') }

      it 'creates the /etc/cinder/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: '644'
        )
      end

      context 'template contents' do
        it 'sets the default attributes' do
          [
            %r{^filters_path = /etc/cinder/rootwrap.d,/usr/share/cinder/rootwrap$},
            %r{^exec_dirs = /sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog = false$/,
            /^syslog_log_facility = syslog$/,
            /^syslog_log_level = ERROR$/,
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end
    end

    it do
      expect(chef_run).to run_ruby_block("delete all attributes in node['openstack']['block-storage']['conf_secrets']")
    end
  end
end
