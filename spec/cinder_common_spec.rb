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

        it 'sets insecure' do
          expect(chef_run).to render_file(file.name).with_content(/^insecure = false$/)
        end

        it 'sets token hash algorithms' do
          expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = md5$/)
        end
      end

      context 'keystone authtoken attributes' do
        it 'has signing_dir' do
          node.set['openstack']['block-storage']['api']['auth']['cache_dir'] = 'auth_cache_dir'

          expect(chef_run).to render_file(file.name).with_content(/^signing_dir = auth_cache_dir$/)
        end

        it 'sets memcached server(s)' do
          node.set['openstack']['block-storage']['api']['auth']['memcached_servers'] = 'localhost:11211'
          expect(chef_run).to render_file(file.name).with_content(/^memcached_servers = localhost:11211$/)
        end

        it 'sets memcache security strategy' do
          node.set['openstack']['block-storage']['api']['auth']['memcache_security_strategy'] = 'MAC'
          expect(chef_run).to render_file(file.name).with_content(/^memcache_security_strategy = MAC$/)
        end

        it 'sets memcache secret key' do
          node.set['openstack']['block-storage']['api']['auth']['memcache_secret_key'] = '0123456789ABCDEF'
          expect(chef_run).to render_file(file.name).with_content(/^memcache_secret_key = 0123456789ABCDEF$/)
        end

        it 'sets cafile' do
          node.set['openstack']['block-storage']['api']['auth']['cafile'] = 'dir/to/path'
          expect(chef_run).to render_file(file.name).with_content(%r{^cafile = dir/to/path$})
        end

        it 'sets insecure' do
          node.set['openstack']['block-storage']['api']['auth']['insecure'] = true
          expect(chef_run).to render_file(file.name).with_content(/^insecure = true$/)
        end

        it 'sets token hash algorithms' do
          node.set['openstack']['block-storage']['api']['auth']['hash_algorithms'] = 'sha2'
          expect(chef_run).to render_file(file.name).with_content(/^hash_algorithms = sha2$/)
        end

        context 'endpoint related' do
          it 'has auth_uri' do
            expect(chef_run).to render_file(file.name).with_content(%r{^auth_uri = http://127.0.0.1:5000/v2.0$})
          end

          it 'has identity_uri' do
            expect(chef_run).to render_file(file.name).with_content(%r{^identity_uri = http://127.0.0.1:35357/$})
          end
        end

        it 'has no auth_version when auth_version is v2.0' do
          node.set['openstack']['block-storage']['api']['auth']['version'] = 'v2.0'

          expect(chef_run).not_to render_file(file.name).with_content(/^auth_version = v2.0$/)
        end

        it 'has auth_version when auth version is not v2.0' do
          node.set['openstack']['block-storage']['api']['auth']['version'] = 'v3.0'

          expect(chef_run).to render_file(file.name).with_content(/^auth_version = v3.0$/)
        end

        it 'has an admin tenant name' do
          node.set['openstack']['block-storage']['service_tenant_name'] = 'tenant_name'

          expect(chef_run).to render_file(file.name).with_content(/^admin_tenant_name = tenant_name$/)
        end

        it 'has an admin user' do
          node.set['openstack']['block-storage']['service_user'] = 'username'

          expect(chef_run).to render_file(file.name).with_content(/^admin_user = username$/)
        end

        it 'has an admin password' do
          # (fgimenez) the get_password mocking is set in spec/spec_helper.rb
          expect(chef_run).to render_file(file.name).with_content(/^admin_password = cinder-pass$/)
        end
      end

      context 'template contents' do
        context 'commonly named attributes' do
          %w(debug verbose host notification_driver
             storage_availability_zone quota_volumes quota_gigabytes quota_driver
             volume_name_template snapshot_name_template osapi_volume_workers
             use_default_quota_class quota_snapshots no_snapshot_gb_quota
             control_exchange max_gigabytes).each do |attr_key|
            it "has a #{attr_key} attribute" do
              node.set['openstack']['block-storage'][attr_key] = "#{attr_key}_value"

              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr_key}=#{attr_key}_value$/)
            end
          end
        end

        context 'backup swift backend contents' do
          before do
            node.set['openstack']['block-storage']['backup']['enabled'] = true
            node.set['openstack']['block-storage']['backup']['driver'] = 'cinder.backup.drivers.swift'
          end

          it 'has default attributes' do
            %w(swift_catalog_info=object-store:swift:publicURL
               backup_swift_auth=per_user
               backup_swift_auth_version=1
               backup_swift_container=volumebackups
               backup_swift_object_size=52428800
               backup_swift_block_size=32768
               backup_swift_retry_attempts=3
               backup_swift_retry_backoff=2
               backup_swift_enable_progress_timer=True).each do |attr|
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr}$/)
            end
          end

          it 'has override attributes' do
            %w(url
               auth
               auth_version
               tenant
               user
               key
               container
               object_size
               block_size
               retry_attempts
               retry_backoff
               enable_progress_timer).each do |attr|
              node.set['openstack']['block-storage']['backup']['swift'][attr] = "backup_swift_#{attr}"
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^backup_swift_#{attr}=backup_swift_#{attr}$/)
            end
          end

          it 'has a custom catalog_info' do
            node.set['openstack']['block-storage']['backup']['swift']['catalog_info'] = 'swift_catalog_info'
            expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^swift_catalog_info=swift_catalog_info$/)
          end
        end

        context 'rdb driver' do
          # FIXME(galstrom21): this block needs to check all of the default
          #   rdb_* configuration options
          it 'has default rbd_* options set' do
            node.set['openstack']['block-storage']['volume'] = {
              'driver' => 'cinder.volume.drivers.rbd.RBDDriver'
            }
            expect(chef_run).to render_file(file.name).with_content(/^rbd_/)
            expect(chef_run).not_to render_file(file.name).with_content(/^netapp_/)
          end
        end

        it 'has a lock_path attribute' do
          expect(chef_run).to render_config_file(file.name).with_section_content('oslo_concurrency', %r{^lock_path=/var/lib/cinder/lock$})
        end

        it 'does not have unique host id by default' do
          expect(chef_run).not_to render_config_file(file.name).with_section_content('DEFAULT', /^host=/)
        end

        it 'has keymgr api_class attribute default set' do
          expect(chef_run).to render_config_file(file.name).with_section_content('keymgr', /^api_class=cinder.keymgr.conf_key_mgr.ConfKeyManager$/)
        end

        it 'does not have keymgr attribute fixed_key set by default' do
          expect(chef_run).not_to render_file(file.name).with_content(/^fixed_key=$/)
        end

        it 'allow override for keymgr attribute fixed_key' do
          chef_run.node.set['openstack']['block-storage']['keymgr']['fixed_key'] = '1111111111111111111111111111111111111111111111111111111111111111'
          expect(chef_run).to render_config_file(file.name)\
            .with_section_content('keymgr', /^fixed_key=1111111111111111111111111111111111111111111111111111111111111111$/)
        end

        context 'netapp driver' do
          # FIXME(galstrom21): this block needs to check all of the default
          #   netapp_* configuration options
          it 'has default netapp_* options set' do
            node.set['openstack']['block-storage']['volume'] = {
              'driver' => 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
            }
            expect(chef_run).to render_file(file.name).with_content(/^netapp_/)
            expect(chef_run).not_to render_file(file.name).with_content(/^rbd_/)
          end
        end

        context 'syslog use' do
          it 'sets the log_config value when syslog is in use' do
            node.set['openstack']['block-storage']['syslog']['use'] = true

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_config = /etc/openstack/logging.conf$})
          end

          it 'sets the log_file value when syslog is not in use' do
            node.set['openstack']['block-storage']['syslog']['use'] = false

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_file = /var/log/cinder/cinder.log$})
          end
        end

        it 'has a db connection attribute' do
          allow_any_instance_of(Chef::Recipe).to receive(:db_uri)
            .with('block-storage', anything, '').and_return('sql_connection_value')

          expect(chef_run).to render_config_file(file.name)
            .with_section_content('database', /^connection=sql_connection_value$/)
        end

        it 'has a db backend attribute' do
          expect(chef_run).to render_config_file(file.name).with_section_content('database', /^backend=sqlalchemy$/)
        end

        it 'has a volume_driver attribute' do
          node.set['openstack']['block-storage']['volume']['driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver=volume_driver_value$/)
        end

        it 'has a state_path attribute' do
          node.set['openstack']['block-storage']['volume']['state_path'] = 'state_path_value'
          expect(chef_run).to render_file(file.name).with_content(/^state_path=state_path_value$/)
        end

        context 'glance endpoint' do
          it 'has a glance_api_servers attribute' do
            expect(chef_run).to render_file(file.name).with_content(%r{^glance_api_servers=http://127.0.0.1:9292$})
          end

          it 'has glance_api_version attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_api_version=1$/)
          end

          it 'has a glance_api_insecure attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_api_insecure=false$/)
          end

          it 'sets insecure for glance' do
            node.set['openstack']['block-storage']['image']['glance_api_insecure'] = true
            expect(chef_run).to render_file(file.name).with_content(/^glance_api_insecure=true$/)
          end

          it 'has a glance_ca_certificates_file attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_ca_certificates_file=$/)
          end

          it 'sets glance_ca_certificates_file attribute' do
            node.set['openstack']['block-storage']['image']['glance_ca_certificates_file'] = 'dir/to/path'
            expect(chef_run).to render_file(file.name).with_content(%r{^glance_ca_certificates_file=dir/to/path$})
          end

          it 'has a glance host attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_host=127.0.0.1$/)
          end

          it 'has a glance port attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^glance_port=9292$/)
          end
        end

        it 'has a api_rate_limit attribute' do
          node.set['openstack']['block-storage']['api']['ratelimit'] = 'api_rate_limit_value'
          expect(chef_run).to render_file(file.name).with_content(/^api_rate_limit=api_rate_limit_value$/)
        end

        context 'cinder endpoint' do
          it 'has osapi_volume_listen set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen=127.0.0.1$/)
          end

          it 'has osapi_volume_listen_port set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen_port=8776$/)
          end

          it 'has default api version set' do
            [/^enable_v1_api=False$/,
             /^enable_v2_api=True$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
            end
          end

          it 'has override api version set' do
            node.set['openstack']['block-storage']['enable_v1_api'] = 'True'
            node.set['openstack']['block-storage']['enable_v2_api'] = 'False'
            [/^enable_v1_api=True$/,
             /^enable_v2_api=False$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
            end
          end
        end

        it 'has a rpc_backend attribute' do
          node.set['openstack']['block_storage']['rpc_backend'] = 'rpc_backend_value'
          expect(chef_run).to render_file(file.name).with_content(/^rpc_backend=rpc_backend_value$/)
        end

        it 'has default RPC/AMQP options set' do
          [/^rpc_backend=cinder.openstack.common.rpc.impl_kombu$/,
           /^rpc_thread_pool_size=64$/,
           /^rpc_response_timeout=60$/].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end

        context 'rabbitmq as mq service' do
          before do
            node.set['openstack']['mq']['block-storage']['service_type'] = 'rabbitmq'
          end

          it 'has default RPC/AMQP options set' do
            [/^rpc_conn_pool_size=30$/,
             /^amqp_durable_queues=false$/,
             /^amqp_auto_delete=false$/,
             /^heartbeat_timeout_threshold=0$/,
             /^heartbeat_rate=2$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          context 'ha attributes' do
            before do
              node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = true
            end

            it 'has a rabbit_hosts attribute' do
              allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
                .and_return('rabbit_servers_value')

              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_hosts=rabbit_servers_value$/)
            end

            %w(host port).each do |attr|
              it "does not have rabbit_#{attr} attribute" do
                expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr}=/)
              end
            end
          end

          context 'non ha attributes' do
            before do
              node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = false
            end

            %w(host port).each do |attr|
              it "has rabbit_#{attr} attribute" do
                node.set['openstack']['mq']['block-storage']['rabbit'][attr] = "rabbit_#{attr}_value"
                expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_#{attr}=rabbit_#{attr}_value$/)
              end
            end

            it 'does not have a rabbit_hosts attribute' do
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_hosts=/)
            end
          end

          it 'has rabbit_userid' do
            node.set['openstack']['mq']['block-storage']['rabbit']['userid'] = 'rabbit_userid_value'
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_userid=rabbit_userid_value$/)
          end

          it 'has rabbit_password' do
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_password=#{test_pass}$/)
          end

          it 'has rabbit_virtual_host' do
            node.set['openstack']['mq']['block-storage']['rabbit']['vhost'] = 'vhost_value'
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_virtual_host=vhost_value$/)
          end

          it 'does not have ssl config set' do
            [/^rabbit_use_ssl=/,
             /^kombu_ssl_version=/,
             /^kombu_ssl_keyfile=/,
             /^kombu_ssl_certfile=/,
             /^kombu_ssl_ca_certs=/,
             /^kombu_reconnect_delay=/,
             /^kombu_reconnect_timeout=/].each do |line|
              expect(chef_run).not_to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'sets ssl config' do
            node.set['openstack']['mq']['block-storage']['rabbit']['use_ssl'] = true
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_ssl_version'] = 'TLSv1.2'
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_ssl_keyfile'] = 'keyfile'
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_ssl_certfile'] = 'certfile'
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_ssl_ca_certs'] = 'certsfile'
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_reconnect_delay'] = 123.123
            node.set['openstack']['mq']['block-storage']['rabbit']['kombu_reconnect_timeout'] = 123
            [/^rabbit_use_ssl=true/,
             /^kombu_ssl_version=TLSv1.2$/,
             /^kombu_ssl_keyfile=keyfile$/,
             /^kombu_ssl_certfile=certfile$/,
             /^kombu_ssl_ca_certs=certsfile$/,
             /^kombu_reconnect_delay=123.123$/,
             /^kombu_reconnect_timeout=123$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', line)
            end
          end

          it 'has the default rabbit_retry_interval set' do
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_retry_interval=1$/)
          end

          it 'has the default rabbit_max_retries set' do
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_rabbit', /^rabbit_max_retries=0$/)
          end
        end

        context 'qpid as mq service' do
          before do
            node.set['openstack']['mq']['block-storage']['service_type'] = 'qpid'
          end

          it 'has default RPC/AMQP options set' do
            [/^rpc_conn_pool_size=30$/,
             /^amqp_durable_queues=false$/,
             /^amqp_auto_delete=false$/].each do |line|
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', line)
            end
          end

          %w(port username sasl_mechanisms reconnect reconnect_timeout reconnect_limit
             reconnect_interval_min reconnect_interval_max reconnect_interval heartbeat protocol
             tcp_nodelay).each do |attr|
            it "has qpid_#{attr} attribute" do
              node.set['openstack']['mq']['block-storage']['qpid'][attr] = "qpid_#{attr}_value"
              expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_#{attr}=qpid_#{attr}_value$/)
            end
          end

          it 'has qpid_hostname' do
            node.set['openstack']['mq']['block-storage']['qpid']['host'] = 'qpid_host_value'
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_hostname=qpid_host_value$/)
          end

          it 'has qpid_password' do
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_password=#{test_pass}$/)
          end

          it 'has default qpid topology version' do
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^qpid_topology_version=1$/)
          end

          it 'has qpid notification_topics' do
            node.set['openstack']['mq']['block-storage']['qpid']['notification_topic'] = 'qpid_notification_topic_value'
            expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_qpid', /^notification_topics=qpid_notification_topic_value$/)
          end
        end

        context 'lvm settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
          end

          %w(group clear clear_size).each do |attr|
            it "has lvm volume_#{attr} attribute" do
              node.set['openstack']['block-storage']['volume']["volume_#{attr}"] = "volume_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^volume_#{attr}=volume_#{attr}_value$/)
            end
          end
        end

        context 'commonly named volume attributes' do
          %w(iscsi_ip_address iscsi_port iscsi_helper volumes_dir).each do |attr|
            it "has volume related #{attr} attribute" do
              node.set['openstack']['block-storage']['volume'][attr] = "common_volume_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=common_volume_#{attr}_value$/)
            end
          end
        end

        context 'rbd attributes' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          end

          it 'has a rbd_pool attribute' do
            node.set['openstack']['block-storage']['rbd']['cinder']['pool'] = 'cinder_value'
            expect(chef_run).to render_file(file.name).with_content(/^rbd_pool=cinder_value$/)
          end
          it 'has a rbd_user attribute' do
            node.set['openstack']['block-storage']['rbd']['user'] = 'rbd_user_value'
            expect(chef_run).to render_file(file.name).with_content(/^rbd_user=rbd_user_value$/)
          end
          it 'has a rbd_secret_uuid attribute' do
            node.set['openstack']['block-storage']['rbd']['secret_uuid'] = 'rbd_secret_uuid_value'
            expect(chef_run).to render_file(file.name).with_content(/^rbd_secret_uuid=rbd_secret_uuid_value$/)
          end
        end

        it 'has volume_driver attribute' do
          node.set['openstack']['block-storage']['volume']['driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver=volume_driver_value$/)
        end

        context 'netapp ISCSI settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
          end

          %w(login password).each do |attr|
            it "has a netapp_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["dfm_#{attr}"] = "dfm_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_#{attr}=dfm_#{attr}_value$/)
            end
          end

          %w(hostname port).each do |attr|
            it "has a netapp_server_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["dfm_#{attr}"] = "dfm_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_server_#{attr}=dfm_#{attr}_value$/)
            end
          end

          it 'has a netapp_storage_service attribute' do
            node.set['openstack']['block-storage']['netapp']['storage_service'] = 'netapp_storage_service_value'
            expect(chef_run).to render_file(file.name).with_content(/^netapp_storage_service=netapp_storage_service_value$/)
          end
        end

        context 'netapp direct7 mode nfs settings' do
          let(:hostnames) { %w(hostname1 hostname2 hostname3) }
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
            node.set['openstack']['block-storage']['netapp']['netapp_server_hostname'] = hostnames
          end

          %w(mount_point_base shares_config).each do |attr_key|
            it "has a nfs_#{attr_key} attribute" do
              node.set['openstack']['block-storage']['nfs'][attr_key] = "netapp_nfs_#{attr_key}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr_key}=netapp_nfs_#{attr_key}_value$/)
            end
          end

          it 'has netapp server_hostname attributes' do
            hostnames.each do |hostname|
              expect(chef_run).to render_file(file.name).with_content(/^netapp_server_hostname=#{hostname}$/)
            end
          end

          it 'has a netapp_server_port attribute' do
            node.set['openstack']['block-storage']['netapp']['netapp_server_port'] = 'netapp_server_port_value'
            expect(chef_run).to render_file(file.name).with_content(/^netapp_server_port=netapp_server_port_value$/)
          end

          %w(login password).each do |attr|
            it "has a netapp_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["netapp_server_#{attr}"] = "netapp_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_#{attr}=netapp_#{attr}_value$/)
            end
          end

          %w(disk_util sparsed_volumes).each do |attr|
            it "has a nfs_#{attr} attribute" do
              node.set['openstack']['block-storage']['nfs']["nfs_#{attr}"] = "netapp_nfs_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr}=netapp_nfs_#{attr}_value$/)
            end
          end
        end

        context 'ibmnas settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
          end

          %w(mount_point_base shares_config).each do |attr|
            it "has a ibmnas_#{attr} attribute" do
              node.set['openstack']['block-storage']['ibmnas'][attr] = "ibmnas_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr}=ibmnas_#{attr}_value$/)
            end
          end

          it 'has a nfs_sparsed_volumes attribute' do
            node.set['openstack']['block-storage']['ibmnas']['nfs_sparsed_volumes'] = 'ibmnas_nfs_sparsed_volumes_value'
            expect(chef_run).to render_file(file.name).with_content(/^nfs_sparsed_volumes=ibmnas_nfs_sparsed_volumes_value$/)
          end

          %w(nas_ip nas_login nas_ssh_port ibmnas_platform_type).each do |attr|
            it "has a ibmnas #{attr} attribute" do
              node.set['openstack']['block-storage']['ibmnas'][attr] = "ibmnas_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=ibmnas_#{attr}_value$/)
            end
          end

          it 'has a default attributes' do
            %w(nas_ip=127.0.0.1
               nas_login=admin
               nas_password=test_pass
               nas_ssh_port=22
               ibmnas_platform_type=v7ku
               nfs_sparsed_volumes=true
               nfs_mount_point_base=/mnt/cinder-volumes
               nfs_shares_config=/etc/cinder/nfs_shares.conf).each do |attr|
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}$/)
            end
          end
        end

        context 'storwize settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
          end

          it 'has a default attribute' do
            %w(san_ip=127.0.0.1
               san_private_key=/v7000_rsa
               storwize_svc_volpool_name=volpool
               storwize_svc_vol_rsize=2
               storwize_svc_vol_warning=0
               storwize_svc_vol_autoexpand=true
               storwize_svc_vol_grainsize=256
               storwize_svc_vol_compression=false
               storwize_svc_vol_easytier=true
               storwize_svc_vol_iogrp=0
               storwize_svc_flashcopy_timeout=120
               storwize_svc_connection_protocol=iSCSI
               storwize_svc_iscsi_chap_enabled=true
               storwize_svc_multihostmap_enabled=true
               storwize_svc_allow_tenant_qos=false).each do |attr|
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}$/)
            end
          end

          it 'has a overridden attribute' do
            %w(san_ip
               san_private_key
               storwize_svc_volpool_name
               storwize_svc_vol_rsize
               storwize_svc_vol_warning
               storwize_svc_vol_autoexpand
               storwize_svc_vol_grainsize
               storwize_svc_vol_compression
               storwize_svc_vol_easytier
               storwize_svc_vol_iogrp
               storwize_svc_flashcopy_timeout
               storwize_svc_connection_protocol
               storwize_svc_multihostmap_enabled
               storwize_svc_allow_tenant_qos
               storwize_svc_stretched_cluster_partner).each do |attr|
              node.set['openstack']['block-storage']['storwize'][attr] = "storwize_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=storwize_#{attr}_value$/)
            end
          end

          context 'storwize with login and password' do
            it 'has a login and password' do
              node.set['openstack']['block-storage']['storwize']['san_private_key'] = ''
              %w(san_login=admin
                 san_password=test_pass
                 san_private_key=).each do |attr|
                expect(chef_run).to render_file(file.name).with_content(/^#{attr}$/)
              end
            end
          end

          context 'storwize with iSCSI connection protocol' do
            before do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'iSCSI'
            end

            it 'has a iscsi chap enabled attribute' do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_iscsi_chap_enabled'] = 'storwize_svc_iscsi_chap_enabled_value'
              expect(chef_run).to render_file(file.name).with_content(/^storwize_svc_iscsi_chap_enabled=storwize_svc_iscsi_chap_enabled_value$/)
            end

            it 'does not have a multipath enabled attribute' do
              expect(chef_run).not_to render_file(file.name).with_content(/^storwize_svc_multipath_enabled=/)
            end
          end

          context 'storwize without iSCSI connection protocol' do
            before do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'non-iSCSI'
            end

            it 'does not have a iscsi chap enabled attribute' do
              expect(chef_run).not_to render_file(file.name).with_content(/^storwize_svc_iscsi_enabled=/)
            end

            it 'has a multipath enabled attribute' do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_multipath_enabled'] = 'storwize_svc_multipath_enabled_value'
              expect(chef_run).to render_file(file.name).with_content(/^storwize_svc_multipath_enabled=storwize_svc_multipath_enabled_value$/)
            end
          end
        end

        context 'solidfire settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.solidfire.SolidFire'
          end

          it 'has solidfire sf_emulate set' do
            node.set['openstack']['block-storage']['solidfire']['sf_emulate'] = 'test'
            expect(chef_run).to render_file(file.name).with_content(/^sf_emulate_512=test$/)
          end

          it 'has solidfire password' do
            expect(chef_run).to render_file(file.name).with_content(/^san_password=test_pass$/)
          end

          %w(san_login san_ip).each do |attr|
            it "has solidfire #{attr} set" do
              node.set['openstack']['block-storage']['solidfire'][attr] = "solidfire_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=solidfire_#{attr}_value$/)
            end
          end

          it 'does not have iscsi_ip_prefix not specified' do
            node.set['openstack']['block-storage']['solidfire']['iscsi_ip_prefix'] = nil
            expect(chef_run).to_not render_file(file.name).with_content(/^iscsi_ip_prefix=/)
          end

          it 'does have iscsi_ip_prefix when specified' do
            chef_run.node.set['openstack']['block-storage']['solidfire']['iscsi_ip_prefix'] = '203.0.113.*'
            expect(chef_run).to render_file(file.name).with_content(/^iscsi_ip_prefix=203.0.113.*$/)
          end
        end

        context 'flashsystem settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.flashsystem.FlashSystemDriver'
          end

          it 'has flashsystem password' do
            expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^san_password=test_pass$/)
          end

          it 'has a default attribute' do
            %w(san_ip=127.0.0.1
               flashsystem_connection_protocol=FC
               flashsystem_multihostmap_enabled=true).each do |attr|
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr}$/)
            end
          end

          it 'has a overridden attribute' do
            %w(san_ip
               flashsystem_connection_protocol
               flashsystem_multihostmap_enabled).each do |attr|
              node.set['openstack']['block-storage']['flashsystem'][attr] = "flashsystem_#{attr}_value"
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^#{attr}=flashsystem_#{attr}_value$/)
            end
          end

          context 'FlashSystem with FC connection protocol' do
            before do
              node.set['openstack']['block-storage']['storwize']['flashsystem_connection_protocol'] = 'FC'
            end

            it 'has a multipath enabled attribute' do
              node.set['openstack']['block-storage']['flashsystem']['flashsystem_multipath_enabled'] = 'flashsystem_multipath_enabled_value'
              expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', /^flashsystem_multipath_enabled=flashsystem_multipath_enabled_value$/)
            end
          end
        end

        context 'emc settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
          end

          %w(iscsi_target_prefix cinder_emc_config_file).each do |attr|
            it "has emc #{attr} set" do
              node.set['openstack']['block-storage']['emc'][attr] = "emc_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=emc_#{attr}_value$/)
            end
          end
        end

        context 'vmware vmdk settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver'
            %w(vmware_host_ip vmware_host_username
               vmware_api_retry_count vmware_task_poll_interval vmware_volume_folder
               vmware_image_transfer_timeout_secs vmware_max_objects_retrieval).each do |attr|
              node.set['openstack']['block-storage']['vmware'][attr] = "vmware_#{attr}_value"
            end
          end

          it 'has vmware attributes set' do
            node['openstack']['block-storage']['vmware'].each do |attr, val|
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{val}$/)
            end
          end

          it 'has password set which is from databag' do
            expect(chef_run).to render_file(file.name).with_content(/^vmware_host_password = vmware_secret_name$/)
          end

          it 'has no wsdl_location line without the attribute' do
            node.set['openstack']['block-storage']['vmware']['vmware_wsdl_location'] = nil
            expect(chef_run).not_to render_file(file.name).with_content(/^vmware_wsdl_location = /)
          end

          it 'has wsdl_location line with attribute present' do
            node.set['openstack']['block-storage']['vmware']['vmware_wsdl_location'] = 'http://127.0.0.1/wsdl'
            expect(chef_run).to render_file(file.name).with_content(%r{^vmware_wsdl_location = http://127.0.0.1/wsdl$})
          end
        end

        context 'gpfs settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.gpfs.GPFSDriver'
          end

          %w(gpfs_mount_point_base gpfs_max_clone_depth
             gpfs_sparse_volumes gpfs_storage_pool).each do |attr|
            it "has gpfs #{attr} set" do
              node.set['openstack']['block-storage']['gpfs'][attr] = "gpfs_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = gpfs_#{attr}_value$/)
            end
          end

          it 'has no gpfs_images_dir line without the attribute' do
            node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = nil
            expect(chef_run).not_to render_file(file.name).with_content(/^gpfs_images_dir = /)
            expect(chef_run).not_to render_file(file.name).with_content(/^gpfs_images_share_mode = /)
          end

          it 'has gpfs_images_dir line with attribute present' do
            node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = 'gpfs_images_dir_value'
            expect(chef_run).to render_file(file.name).with_content(/^gpfs_images_dir = gpfs_images_dir_value$/)
            expect(chef_run).to render_file(file.name).with_content(/^gpfs_images_share_mode = copy_on_write$/)
          end

          it 'templates misc_cinder array correctly' do
            node.set['openstack']['block-storage']['misc_cinder'] = ['# Comments', 'MISC=OPTION']
            expect(chef_run).to render_file(file.name).with_content(
              /^# Comments$/)
            expect(chef_run).to render_file(file.name).with_content(
              /^MISC=OPTION$/)
          end
        end

        context 'multiple backend settings' do
          before do
            node.set['openstack']['block-storage']['volume']['multi_backend'] = {
              'lvm' => {
                'volume_driver' => 'cinder.volume.drivers.lvm.LVMVolumeDriver',
                'volume_backend_name' => 'lvmdrv'
              },
              'rbd' => {
                'volume_driver' => 'cinder.volume.drivers.rbd.RBDDriver',
                'volume_backend_name' => 'rbddrv'
              },
              'netapp_iscsi' => {
                'volume_driver' => 'cinder.volume.drivers.netapp.NetAppISCSIDriver',
                'multi_netapp_iscsi' => 'multi-netapp'
              },
              'netapp_nfs' => {
                'volume_driver' => 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver',
                'volume_backend_name' => 'netappnfsdrv',
                'multi_netapp_nfs' => 'multi-netapp'
              },
              'ibmnas' => {
                'volume_driver' => 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver',
                'multi_ibmnas' => 'multi-ibmnas'
              },
              'ibmsvc' => {
                'volume_driver' => 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver',
                'multi_ibmsvc' => 'multi-ibmsvc'
              },
              'solidfire' => {
                'volume_driver' => 'cinder.volume.drivers.solidfire.SolidFire',
                'multi_solidfire' => 'multi-solidfire'
              },
              'emciscsi' => {
                'volume_driver' => 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver',
                'multi_emciscsi' => 'multi-emciscsi'
              },
              'vmware' => {
                'volume_driver' => 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver',
                'multi_vmware' => 'multi-vmware'
              },
              'gpfs' => {
                'volume_driver' => 'cinder.volume.drivers.ibm.gpfs.GPFSDriver',
                'multi_gpfs' => 'multi-gpfs'
              }
            }
            node.set['openstack']['block-storage']['volume']['volume_group'] = 'multi-lvm-group'
            node.set['openstack']['block-storage']['volume']['default_volume_type'] = 'some-type-name'
            node.set['openstack']['block-storage']['rbd']['cinder']['pool'] = 'multi-rbd-pool'
            node.set['openstack']['block-storage']['netapp']['dfm_login'] = 'multi-netapp-login'
            node.set['openstack']['block-storage']['netapp']['netapp_server_hostname'] = ['netapp-host-1', 'netapp-host-2']
            node.set['openstack']['block-storage']['netapp']['netapp_server_port'] = 'multi-netapp-port'
            node.set['openstack']['block-storage']['ibmnas']['shares_config'] = 'multi-ibmnas-share'
            node.set['openstack']['block-storage']['storwize']['storwize_svc_volpool_name'] = 'multi-svc-volpool'
            node.set['openstack']['block-storage']['solidfire']['sf_emulate'] = 'multi-sf-true'
            node.set['openstack']['block-storage']['emc']['cinder_emc_config_file'] = 'multi-emc-conf'
            node.set['openstack']['block-storage']['vmware']['vmware_host_ip'] = 'multi-vmware-ip'
            node.set['openstack']['block-storage']['gpfs']['gpfs_mount_point_base'] = 'multi-gpfs-mnt'
          end

          it 'enable multiple backends' do
            expect(chef_run).to render_file(file.name).with_content(/^enabled_backends = lvm,rbd,netapp_iscsi,netapp_nfs,ibmnas,ibmsvc,solidfire,emciscsi,vmware,gpfs$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[lvm\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.lvm\.LVMVolumeDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[rbd\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.rbd\.RBDDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[netapp_iscsi\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.netapp\.NetAppISCSIDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^netapp_server_hostname=netapp-host-1$/)
            expect(chef_run).to render_file(file.name).with_content(/^netapp_server_hostname=netapp-host-2$/)
            expect(chef_run).to render_file(file.name).with_content(/^\[netapp_nfs\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.netapp\.nfs\.NetAppDirect7modeNfsDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[ibmnas\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.ibm\.ibmnas\.IBMNAS_NFSDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[ibmsvc\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.ibm\.storwize_svc\.StorwizeSVCDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[solidfire\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.solidfire\.SolidFire$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[emciscsi\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.emc\.emc_smis_iscsi\.EMCSMISISCSIDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[vmware\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.vmware\.vmdk\.VMwareVcVmdkDriver$/)

            expect(chef_run).to render_file(file.name).with_content(/^\[gpfs\]$/)
            expect(chef_run).to render_file(file.name).with_content(/^volume_driver = cinder\.volume\.drivers\.ibm\.gpfs\.GPFSDriver$/)
          end

          it 'set lvm option' do
            expect(chef_run).to render_file(file.name).with_content(/^volume_group=multi-lvm-group$/)
          end

          it 'set default_volume_type option' do
            expect(chef_run).to render_file(file.name).with_content(/^default_volume_type=some-type-name$/)
          end

          it 'set rbd option' do
            expect(chef_run).to render_file(file.name).with_content(/^rbd_pool=multi-rbd-pool$/)
          end

          it 'set netapp_iscsi option' do
            expect(chef_run).to render_file(file.name).with_content(/^netapp_login=multi-netapp-login$/)
          end

          it 'set netapp_nfs option' do
            expect(chef_run).to render_file(file.name).with_content(/^netapp_server_port=multi-netapp-port$/)
          end

          it 'set ibmnas option' do
            expect(chef_run).to render_file(file.name).with_content(/^nfs_shares_config=multi-ibmnas-share$/)
          end

          it 'set ibmsvc option' do
            expect(chef_run).to render_file(file.name).with_content(/^storwize_svc_volpool_name=multi-svc-volpool$/)
          end

          it 'set solidfire option' do
            expect(chef_run).to render_file(file.name).with_content(/^sf_emulate_512=multi-sf-true$/)
          end

          it 'set emciscsi option' do
            expect(chef_run).to render_file(file.name).with_content(/^cinder_emc_config_file=multi-emc-conf$/)
          end

          it 'set vmware option' do
            expect(chef_run).to render_file(file.name).with_content(/^vmware_host_ip = multi-vmware-ip$/)
          end

          it 'set gpfs option' do
            expect(chef_run).to render_file(file.name).with_content(/^gpfs_mount_point_base = multi-gpfs-mnt$/)
          end
        end

        it 'no multiple backends configured' do
          expect(chef_run).to_not render_file(file.name).with_content(/^enabled_backends = [\w\W]+$/)
        end

        it 'does not set default_volume_type' do
          expect(chef_run).to_not render_file(file.name).with_content(/^default_volume_type=.+$/)
        end
      end
    end

    describe '/var/lib/cinder/lock' do
      let(:dir) { chef_run.directory('/var/lib/cinder/lock') }

      it 'should create the /var/lib/cinder/lock directory' do
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
        it 'shows the custom banner' do
          node.set['openstack']['block-storage']['custom_template_banner'] = 'banner'

          expect(chef_run).to render_file(file.name)
            .with_content(/^banner$/)
        end

        it 'sets the default attributes' do
          [
            %r{^filters_path=/etc/cinder/rootwrap.d,/usr/share/cinder/rootwrap$},
            %r{^exec_dirs=/sbin,/usr/sbin,/bin,/usr/bin$},
            /^use_syslog=False$/,
            /^syslog_log_facility=syslog$/,
            /^syslog_log_level=ERROR$/
          ].each do |line|
            expect(chef_run).to render_file(file.name).with_content(line)
          end
        end
      end
    end
  end
end
