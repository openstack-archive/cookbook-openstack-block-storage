# encoding: utf-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['mq']['host'] = '127.0.0.1'
      node.set['openstack']['mq']['block-storage']['rabbit']['notification_topic'] = 'rabbit_topic'

      runner.converge(described_recipe)
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
          mode: 00750
        )
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }
      let(:test_pass) { 'test_pass' }
      before do
        allow_any_instance_of(Chef::Recipe).to receive(:get_password)
          .with('user', anything)
          .and_return(test_pass)
      end

      it 'should create the cinder.conf template' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'cinder',
          group: 'cinder',
          mode: 00640
        )
      end

      context 'keystone authtoken attributes with default values' do
        it 'sets memcached server(s)' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcached_servers = $/)
        end

        it 'sets memcache security strategy' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_security_strategy = $/)
        end

        it 'sets memcache secret key' do
          expect(chef_run).not_to render_file(file.name).with_content(/^memcache_secret_key = $/)
        end

        it 'sets cafile' do
          expect(chef_run).not_to render_file(file.name).with_content(/^cafile = $/)
        end
      end

      context 'keystone authtoken attributes' do
        it 'has signing_dir' do
          node.set['openstack']['block-storage']['conf']['keystone_authtoken']['signing_dir'] = 'auth_cache_dir'

          expect(chef_run).to render_file(file.name).with_content(/^signing_dir = auth_cache_dir$/)
        end

        context 'endpoint related' do
          it 'has auth_uri' do
            expect(chef_run).to render_file(file.name).with_content(%r{^auth_url = http://127.0.0.1:5000/v3$})
          end
        end

        it do
          expect(chef_run).not_to render_file(file.name).with_content(/^auth_version = v2.0$/)
        end

        it 'has an admin tenant name' do
          node.set['openstack']['block-storage']['conf']['keystone_authtoken']['admin_tenant_name'] = 'tenant_name'

          expect(chef_run).to render_file(file.name).with_content(/^admin_tenant_name = tenant_name$/)
        end

        it 'has an admin user' do
          node.set['openstack']['block-storage']['conf']['keystone_authtoken']['admin_user'] = 'username'

          expect(chef_run).to render_file(file.name).with_content(/^admin_user = username$/)
        end

        it 'has an admin password' do
          # (fgimenez) the get_password mocking is set in spec/spec_helper.rb
          expect(chef_run).to render_file(file.name).with_content(/^password = cinder-pass$/)
        end
      end

      context 'template contents' do
        context 'commonly named attributes' do
          %w(debug verbose host notification_driver
             osapi_volume_worker control_exchange).each do |attr_key|
            it "has a #{attr_key} attribute" do
              node.set['openstack']['block-storage']['conf']['DEFAULT'][attr_key] = "#{attr_key}_value"

              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr_key} = #{attr_key}_value$/)
            end
          end
        end

        context 'backup swift backend contents' do
          before do
            node.set['openstack']['block-storage']['backup']['enabled'] = true
            node.set['openstack']['block-storage']['backup']['driver'] = 'cinder.backup.drivers.swift'
          end
        end

        it 'has a lock_path attribute' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_concurrency', %r{^lock_path = /var/lib/cinder/tmp})
        end

        it 'does not have unique host id by default' do
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', /^host = /)
        end

        it 'does not have keymgr attribute fixed_key set by default' do
          expect(chef_run).not_to render_file(file.name).with_content(/^fixed_key = $/)
        end

        context 'syslog use' do
          it 'sets the log_config value when syslog is in use' do
            node.set['openstack']['block-storage']['syslog']['use'] = true

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_config = /etc/openstack/logging.conf$})
          end
        end

        it 'has a db connection attribute' do
          allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
            .and_return('sql_connection_value')

          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', /^connection = sql_connection_value$/)
        end

        it 'has a slave db connection attribute' do
          allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
            .and_return('sql_connection_value')

          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', /^connection = sql_connection_value$/)
        end

        it 'has a volume_driver attribute' do
          node.set['openstack']['block-storage']['conf']['DEFAULT']['volume_driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver = volume_driver_value$/)
        end

        it 'has a state_path attribute' do
          node.set['openstack']['block-storage']['conf']['DEFAULT']['state_path'] = 'state_path_value'
          expect(chef_run).to render_file(file.name).with_content(/^state_path = state_path_value$/)
        end

        context 'glance endpoint' do
          it 'has a glance_api_servers attribute' do
            expect(chef_run).to render_file(file.name).with_content(%r{^glance_api_servers = http://127.0.0.1:9292$})
          end

          it 'has a glance host attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_host = 127.0.0.1$/)
          end

          it 'has a glance port attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_port = 9292$/)
          end
        end

        context 'cinder endpoint' do
          it 'has osapi_volume_listen set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen = 127.0.0.1$/)
          end

          it 'has osapi_volume_listen_port set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen_port = 8776$/)
          end
        end
        it 'has default transport_url/AMQP options set' do
          [%r{^transport_url = rabbit://guest:mypass@127.0.0.1:5672$}].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end

        context 'rabbitmq as mq service' do
          context 'non ha attributes' do
            before do
              node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = false
            end

            %w(host port).each do |attr|
              it "has rabbit_#{attr} attribute" do
                node.set['openstack']['block-storage']['conf']['oslo_messaging_rabbit']["rabbit_#{attr}"] = "rabbit_#{attr}_value"
                expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr} = rabbit_#{attr}_value$/)
              end
            end

            it 'does not have a rabbit_hosts attribute' do
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_hosts = /)
            end
          end

          it 'has rabbit_virtual_host' do
            node.set['openstack']['block-storage']['conf']['oslo_messaging_rabbit']['rabbit_virtual_host'] = 'vhost_value'
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_virtual_host = vhost_value$/)
          end
        end

        context 'lvm settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
          end
        end

        context 'commonly named volume attributes' do
          %w(iscsi_ip_address iscsi_port iscsi_helper volumes_dir).each do |attr|
            it "has volume related #{attr} attribute" do
              node.set['openstack']['block-storage']['conf']['DEFAULT'][attr] = "common_volume_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = common_volume_#{attr}_value$/)
            end
          end
        end

        context 'rbd attributes' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          end
        end

        it 'has volume_driver attribute' do
          node.set['openstack']['block-storage']['conf']['DEFAULT']['volume_driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver = volume_driver_value$/)
        end

        context 'netapp ISCSI settings' do
          before do
            node.set['openstack']['block-storage']['conf']['DEFAULT']['volume_driver'] = 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
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
          mode: 00755
        )
      end
    end

    describe 'rootwrap.conf' do
      let(:file) { chef_run.template('/etc/cinder/rootwrap.conf') }

      it 'creates the /etc/cinder/rootwrap.conf file' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0644
        )
      end

      context 'template contents' do
        it 'sets the default attributes' do
          [
            %r{^filters_path = /etc/cinder/rootwrap.d,/usr/share/cinder/rootwrap$},
            %r{^exec_dirs = /sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog = false$/,
            /^syslog_log_facility = syslog$/,
            /^syslog_log_level = ERROR$/
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
