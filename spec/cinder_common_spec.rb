# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['mq']['host'] = '127.0.0.1'
      node.set['openstack']['mq']['block-storage']['rabbit']['notification_topic'] = 'rabbit_topic'

      runner.converge(described_recipe)
    end

    include_context 'block-storage-stubs'

    it 'installs the cinder-common package' do
      expect(chef_run).to upgrade_package 'cinder-common'
    end

    describe '/etc/cinder' do
      let(:dir) { chef_run.directory('/etc/cinder') }

      it 'has proper owner' do
        expect(dir.owner).to eq('cinder')
        expect(dir.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', dir.mode)).to eq '750'
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

      it 'has proper owner' do
        expect(file.owner).to eq('cinder')
        expect(file.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', file.mode)).to eq '644'
      end

      it 'has name templates' do
        expect(chef_run).to render_file(file.name).with_content('volume_name_template=volume-%s')
        expect(chef_run).to render_file(file.name).with_content('snapshot_name_template=snapshot-%s')
      end

      it 'has rpc_backend set' do
        expect(chef_run).to render_file(file.name).with_content('rpc_backend=cinder.openstack.common.rpc.impl_kombu')
      end

      it 'has has volumes_dir set' do
        expect(chef_run).to render_file(file.name).with_content('volumes_dir=/var/lib/cinder/volumes')
      end

      it 'has correct volume.driver set' do
        expect(chef_run).to render_file(file.name).with_content('volume_driver=cinder.volume.drivers.lvm.LVMISCSIDriver')
      end

      it 'has osapi_volume_listen set' do
        node.set['openstack']['endpoints']['block-storage-api']['host'] = '1.1.1.1'
        expect(chef_run).to render_file(file.name).with_content('osapi_volume_listen=1.1.1.1')
      end

      it 'has osapi_volume_listen_port set' do
        node.set['openstack']['endpoints']['block-storage-api']['port'] = '9999'
        expect(chef_run).to render_file(file.name).with_content('osapi_volume_listen_port=9999')
      end

      it 'has rpc_thread_pool_size' do
        expect(chef_run).to render_file(file.name).with_content('rpc_thread_pool_size=64')
      end

      it 'has rpc_conn_pool_size' do
        expect(chef_run).to render_file(file.name).with_content('rpc_conn_pool_size=30')
      end

      it 'has rpc_response_timeout' do
        expect(chef_run).to render_file(file.name).with_content('rpc_response_timeout=60')
      end

      it 'has rabbit_host' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_host=127.0.0.1')
      end

      it 'does not have rabbit_hosts' do
        expect(chef_run).not_to render_file(file.name).with_content('rabbit_hosts=')
      end

      it 'does not have rabbit_ha_queues' do
        expect(chef_run).not_to render_file(file.name).with_content('rabbit_ha_queues=')
      end

      it 'has log_file' do
        expect(chef_run).to render_file(file.name).with_content('log_file = /var/log/cinder/cinder.log')
      end

      it 'has log_config when syslog is true' do
        node.set['openstack']['block-storage']['syslog']['use'] = true

        expect(chef_run).to render_file(file.name).with_content('log_config = /etc/openstack/logging.conf')
      end

      it 'has rabbit_port' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_port=5672')
      end

      it 'has rabbit_use_ssl' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_use_ssl=false')
      end

      it 'has rabbit_userid' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_userid=guest')
      end

      it 'has rabbit_password' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_password=mq-pass')
      end

      it 'has rabbit_virtual_host' do
        expect(chef_run).to render_file(file.name).with_content('rabbit_virtual_host=/')
      end

      it 'has rabbit notification_topics' do
        expect(chef_run).to render_file(file.name).with_content('notification_topics=rabbit_topic')
      end

      describe 'rabbit ha' do
        before do
          node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = true
        end

        it 'has rabbit_hosts' do
          expect(chef_run).to render_file(file.name).with_content('rabbit_hosts=1.1.1.1:5672,2.2.2.2:5672')
        end

        it 'has rabbit_ha_queues' do
          expect(chef_run).to render_file(file.name).with_content('rabbit_ha_queues=True')
        end

        it 'does not have rabbit_host' do
          expect(chef_run).not_to render_file(file.name).with_content('rabbit_host=127.0.0.1')
        end

        it 'does not have rabbit_port' do
          expect(chef_run).not_to render_file(file.name).with_content('rabbit_port=5672')
        end
      end

      describe 'qpid' do
        before do
          node.set['openstack']['mq']['block-storage']['service_type'] = 'qpid'
          node.set['openstack']['block-storage']['notification_driver'] = 'cinder.test_driver'
          node.set['openstack']['mq']['block-storage']['qpid']['notification_topic'] = 'qpid_topic'
            # we set username here since the attribute in common currently
            # defaults to ''
          node.set['openstack']['mq']['block-storage']['qpid']['username'] = 'guest'
        end

        it 'has qpid_hostname' do
          expect(chef_run).to render_file(file.name).with_content('qpid_hostname=127.0.0.1')
        end

        it 'has qpid_port' do
          expect(chef_run).to render_file(file.name).with_content('qpid_port=5672')
        end

        it 'has qpid_username' do
          expect(chef_run).to render_file(file.name).with_content('qpid_username=guest')
        end

        it 'has qpid_password' do
          expect(chef_run).to render_file(file.name).with_content('qpid_password=mq-pass')
        end

        it 'has qpid_sasl_mechanisms' do
          expect(chef_run).to render_file(file.name).with_content('qpid_sasl_mechanisms=')
        end

        it 'has qpid_reconnect_timeout' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect_timeout=0')
        end

        it 'has qpid_reconnect_limit' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect_limit=0')
        end

        it 'has qpid_reconnect_interval_min' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect_interval_min=0')
        end

        it 'has qpid_reconnect_interval_max' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect_interval_max=0')
        end

        it 'has qpid_reconnect_interval' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect_interval=0')
        end

        it 'has qpid_reconnect' do
          expect(chef_run).to render_file(file.name).with_content('qpid_reconnect=true')
        end

        it 'has qpid_heartbeat' do
          expect(chef_run).to render_file(file.name).with_content('qpid_heartbeat=60')
        end

        it 'has qpid_protocol' do
          expect(chef_run).to render_file(file.name).with_content('qpid_protocol=tcp')
        end

        it 'has qpid_tcp_nodelay' do
          expect(chef_run).to render_file(file.name).with_content('qpid_tcp_nodelay=true')
        end

        it 'has notification_driver' do
          expect(chef_run).to render_file(file.name).with_content('notification_driver=cinder.test_driver')
        end

        it 'has notification_topics' do
          expect(chef_run).to render_file(file.name).with_content('notification_topics=qpid_topic')
        end
      end

      describe 'lvm settings' do
        before do
          node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMISCSIDriver'
          node.set['openstack']['block-storage']['volume']['volume_group'] = 'test-group'
          node.set['openstack']['block-storage']['volume']['volume_clear_size'] = 100
          node.set['openstack']['block-storage']['volume']['volume_clear'] = 'none'
        end

        it 'has volume_group' do
          expect(chef_run).to render_file(file.name).with_content('volume_group=test-group')
        end

        it 'has volume_clear_size' do
          expect(chef_run).to render_file(file.name).with_content('volume_clear_size=100')
        end

        it 'has volume_clear' do
          expect(chef_run).to render_file(file.name).with_content('volume_clear=none')
        end
      end

      describe 'solidfire settings' do
        before do
          node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.solidfire.SolidFire'
          node.set['openstack']['block-storage']['solidfire']['sf_emulate'] = 'test'
          node.set['openstack']['block-storage']['solidfire']['san_ip'] = '203.0.113.10'
          node.set['openstack']['block-storage']['solidfire']['san_login'] = 'solidfire_admin'
        end

        it 'has solidfire sf_emulate set' do
          expect(chef_run).to render_file(file.name).with_content('sf_emulate_512=test')
        end

        it 'has solidfire san_ip set' do
          expect(chef_run).to render_file(file.name).with_content('san_ip=203.0.113.10')
        end

        it 'has solidfire san_login' do
          expect(chef_run).to render_file(file.name).with_content('san_login=solidfire_admin')
        end

        it 'has solidfire password' do
          expect(chef_run).to render_file(file.name).with_content('san_password=solidfire_testpass')
        end

        it 'does not have iscsi_ip_prefix not specified' do
          expect(chef_run).to_not render_file(file.name).with_content('iscsi_ip_prefix')
        end

        it 'does have iscsi_ip_prefix when specified' do
          chef_run.node.set['openstack']['block-storage']['solidfire']['iscsi_ip_prefix'] = '203.0.113.*'

          expect(chef_run).to render_file(file.name).with_content('iscsi_ip_prefix=203.0.113.*')
        end
      end

      describe 'emc settings' do
        before do
          node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
          node.set['openstack']['block-storage']['emc']['iscsi_target_prefix'] = 'test.prefix'
          node.set['openstack']['block-storage']['emc']['cinder_emc_config_file'] = '/etc/test/config.file'
        end

        it 'has emc iscsi_target_prefix' do
          expect(chef_run).to render_file(file.name).with_content('iscsi_target_prefix=test.prefix')
        end

        it 'has cinder_emc_config_file' do
          expect(chef_run).to render_file(file.name).with_content('cinder_emc_config_file=/etc/test/config.file')
        end
      end

      describe 'ibmnas settings' do
        before do
          chef_run.node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['nas_ip'] = '127.0.0.1'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['nas_login'] = 'ibmnas_admin'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['nas_ssh_port'] = '22'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['shares_config'] = '/etc/cinder/nfs_shares.conf'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['mount_point_base'] = '/mnt/cinder-volumes'
          chef_run.node.set['openstack']['block-storage']['ibmnas']['nfs_sparsed_volumes'] = 'true'
          chef_run.converge 'openstack-block-storage::cinder-common'
        end

        it 'has ibmnas nas_ip' do
          expect(chef_run).to render_file(file.name).with_content('nas_ip=127.0.0.1')
        end

        it 'has ibmnas nas_login' do
          expect(chef_run).to render_file(file.name).with_content('nas_login=ibmnas_admin')
        end

        it 'has ibmnas nas_password' do
          expect(chef_run).to render_file(file.name).with_content('nas_password=test_pass')
        end

        it 'has ibmnas nas_ssh_port' do
          expect(chef_run).to render_file(file.name).with_content('nas_ssh_port=22')
        end

        it 'has ibmnas shares_config' do
          expect(chef_run).to render_file(file.name).with_content('shares_config=/etc/cinder/nfs_shares.conf')
        end

        it 'has ibmnas mount_point_base' do
          expect(chef_run).to render_file(file.name).with_content('mount_point_base=/mnt/cinder-volumes')
        end

        it 'has ibmnas nfs_sparsed_volumes' do
          expect(chef_run).to render_file(file.name).with_content('nfs_sparsed_volumes=true')
        end
      end

      describe 'vmware vmdk settings' do
        before do
          chef_run.node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver'
          chef_run.converge 'openstack-block-storage::cinder-common'
        end

        [
          /^vmware_host_ip = $/,
          /^vmware_host_username = $/,
          /^vmware_host_password = $/,
          /^vmware_api_retry_count = 10$/,
          /^vmware_task_poll_interval = 5$/,
          /^vmware_volume_folder = cinder-volumes/,
          /^vmware_image_transfer_timeout_secs = 7200$/,
          /^vmware_max_objects_retrieval = 100$/
        ].each do |content|
          it "has a #{content.source[1...-1]} line" do
            expect(chef_run).to render_file(file.name).with_content(content)
          end
        end

        it 'has no wsdl_location line' do
          expect(chef_run).not_to render_file(file.name).with_content('vmware_wsdl_location = ')
        end

        it 'has wsdl_location line' do
          node.set['openstack']['block-storage']['vmware']['vmware_wsdl_location'] = 'http://127.0.0.1/wsdl'

          expect(chef_run).to render_file(file.name).with_content('vmware_wsdl_location = http://127.0.0.1/wsdl')
        end
      end
    end

    describe '/var/lock/cinder' do
      let(:dir) { chef_run.directory('/var/lock/cinder') }

      it 'has proper owner' do
        expect(dir.owner).to eq('cinder')
        expect(dir.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', dir.mode)).to eq '700'
      end
    end
  end
end
