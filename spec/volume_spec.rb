# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'

    expect_creates_cinder_conf('service[cinder-volume]', 'cinder', 'cinder')

    it 'upgrades cinder volume packages' do
      expect(chef_run).to upgrade_package 'cinder-volume'
    end

    it 'upgrades qemu utils package' do
      expect(chef_run).to upgrade_package 'qemu-utils'
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service 'cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service 'cinder-volume'
    end

    it 'starts iscsi target on boot' do
      expect(chef_run).to enable_service 'tgt'
    end

    it 'upgrades mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysqldb'
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package 'tgt'
    end

    it 'upgrades emc package' do
      node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'

      expect(chef_run).to upgrade_package 'python-pywbem'
    end

    context 'IBMNAS Driver' do
      let(:file) { chef_run.template('/etc/cinder/nfs_shares.conf') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
      end

      context 'IBMNAS shares_config file' do
        it 'creates the file' do
          expect(chef_run).to create_template(file.name).with(
            owner: 'cinder',
            group: 'cinder',
            mode: '0600'
        )
        end

        it 'sets the ibmnas access_ip attribute' do
          node.set['openstack']['block-storage']['ibmnas']['nas_access_ip'] = '127.0.0.1'
          node.set['openstack']['block-storage']['ibmnas']['export'] = '/ibm/fs/export'
          expect(chef_run).to render_file(file.name).with_content('127.0.0.1:/ibm/fs/export')
        end
      end

      it 'upgrades nfs package' do
        expect(chef_run).to upgrade_package 'nfs-common'
      end

      it 'creates the nfs mount point' do
        expect(chef_run).to create_directory('/mnt/cinder-volumes').with(
          owner: 'cinder',
          group: 'cinder',
          mode: '0755'
        )
      end
    end

    context 'NetApp Driver' do
      describe 'NFS' do
        before do
          node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
        end

        it 'upgrades nfs package' do
          expect(chef_run).to upgrade_package 'nfs-common'
        end

        it 'creates the nfs mount point' do
          expect(chef_run).to create_directory '/mnt/cinder-volumes'
        end

        context 'shares config file' do
          let(:shares_config_file) { 'nfs_shares_config_file' }
          let(:file) { chef_run.template(shares_config_file) }

          before do
            node.set['openstack']['block-storage']['nfs']['shares_config'] = shares_config_file
          end

          it 'creates the file' do
            node.set['openstack']['block-storage']['user'] = 'test_user'
            node.set['openstack']['block-storage']['group'] = 'test_group'

            expect(chef_run).to create_template(file.name).with(
              owner: 'test_user',
              group: 'test_group',
              mode: '0600'
            )
          end

          it 'sets netapp server hostname export settings' do
            netapp_server_hostname = %w(hostname1 hostname2)
            node.set['openstack']['block-storage']['netapp']['netapp_server_hostname'] = netapp_server_hostname
            node.set['openstack']['block-storage']['netapp']['export'] = 'netapp_export_value'

            netapp_server_hostname.each do |hostname|
              expect(chef_run).to render_file(file.name).with_content(/^#{hostname}:netapp_export_value$/)
            end
          end
        end
      end

      describe 'ISCSI' do
        before do
          node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.iscsi.NetAppISCSIDriver'
        end

        it 'configures netapp dfm password' do
          n = chef_run.node['openstack']['block-storage']['netapp']['dfm_password']
          expect(n).to eq 'netapp-pass'
        end
      end
    end

    context 'Ceph (RBD) Driver' do
      let(:file) { chef_run.template('/etc/ceph/ceph.client.cinder.keyring') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
        node.set['ceph']['config']['fsid'] = '00000000-0000-0000-0000-000000000000'
      end

      it 'includes the ceph recipe' do
        expect(chef_run).to include_recipe('ceph')
      end
    end
    context 'Storewize Driver' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
      end

      it 'download san private key if needed' do
        node.set['openstack']['block-storage']['storwize']['san_private_key_url'] = 'http://server/key'
        expect(chef_run).to create_remote_file('/v7000_rsa').with(
          source: 'http://server/key',
          user: 'cinder',
          group: 'cinder',
          mode: '0400'
        )
      end

      it 'upgrades svc package' do
        expect(chef_run).to upgrade_package 'sysfsutils'
      end

      context 'ISCSI' do
        before do
          node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'iSCSI'
        end

        it 'configures storewize with iscsi' do
          # Test that the FC specific options are not set when connected via iSCSI
          expect(chef_run).not_to render_file(file.name).with_content('storwize_svc_multipath_enabled')
        end
      end

      context 'FC' do
        before do
          node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'FC'
        end

        it 'configures storewize with fc' do
          # Test that the iSCSI specific options are not set when connected via FC
          expect(chef_run).not_to render_file(file.name).with_content('storwize_svc_iscsi_chap_enabled')
        end
      end
    end

    context 'FlashSystem Driver' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.flashsystem.FlashSystemDriver'
      end

      it 'upgrades sysfsutils package' do
        expect(chef_run).to upgrade_package 'sysfsutils'
      end
    end

    describe 'targets.conf' do
      let(:file) { chef_run.template('/etc/tgt/targets.conf') }

      it 'should create the targets.conf' do
        expect(chef_run).to create_template(file.name).with(
          mode: 0600
        )
      end

      it 'notifies iscsi restart' do
        expect(file).to notify('service[iscsitarget]').to(:restart)
      end

      it 'has ubuntu include' do
        node.set['openstack']['block-storage']['volume']['volumes_dir'] = 'volumes_dir_value'

        expect(chef_run).to render_file(file.name).with_content('include /etc/tgt/conf.d/*.conf')
        expect(chef_run).not_to render_file(file.name).with_content('include volumes_dir_value/*')
      end
    end

    describe 'create_vg' do
      let(:file) { chef_run.template('/etc/init.d/cinder-group-active') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
        node.set['openstack']['block-storage']['volume']['create_volume_group'] = true
        stub_command('vgs cinder-volumes').and_return(false)
      end

      it 'upgrades lvm packages' do
        expect(chef_run).to upgrade_package 'lvm2'
      end

      it 'cinder vg active' do
        expect(chef_run).to enable_service 'cinder-group-active'
      end

      it 'create volume group' do
        volume_size = chef_run.node['openstack']['block-storage']['volume']['volume_group_size']
        seek_count = volume_size.to_i * 1024
        group_name = chef_run.node['openstack']['block-storage']['volume']['volume_group']
        path = chef_run.node['openstack']['block-storage']['volume']['state_path']
        vg_file = "#{path}/#{group_name}.img"
        cmd = "dd if=/dev/zero of=#{vg_file} bs=1M seek=#{seek_count} count=0; vgcreate cinder-volumes $(losetup --show -f #{vg_file})"
        expect(chef_run).to run_execute(cmd)
      end

      it 'notifies cinder group active start' do
        expect(file).to notify('service[cinder-group-active]').to(:start)
      end

      it 'creates cinder group active template file' do
        expect(chef_run).to create_template(file.name)
      end

      describe 'template contents' do
        let(:volume_group_value) { 'volume_group_value' }
        before do
          node.set['openstack']['block-storage']['volume']['volume_group'] = volume_group_value
          stub_command("vgs #{volume_group_value}").and_return(true)
        end

        it 'calls vgs with the volume name attribute' do
          expect(chef_run).to render_file(file.name).with_content(%r{vgs #{volume_group_value} > /dev/null 2>&1})
        end

        it 'calls vgcreate with the volume name and volume file attributes' do
          node.set['openstack']['block-storage']['volume']['state_path'] = 'state_path_value'
          volume_file = "state_path_value/#{volume_group_value}.img"
          expect(chef_run).to render_file(file.name).with_content(/vgcreate #{volume_group_value} \$\(losetup --show -f #{volume_file}\)/)
        end

        it 'has ubuntu settings' do
          expect(chef_run).to render_file(file.name).with_content(/^\s*echo "SUCCESS"/)
          expect(chef_run).not_to render_file(file.name).with_content(/^\s*success$/)
        end
      end
    end

    describe 'create vg on block devices' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
        node.set['openstack']['block-storage']['volume']['create_volume_group'] = true
        node.set['openstack']['block-storage']['volume']['create_volume_group_type'] = 'block_devices'
        node.set['openstack']['block-storage']['volume']['block_devices'] = '/dev/sdx /dev/sdx1'
        stub_command('vgs cinder-volumes').and_return(false)
      end

      it 'create volume group on block devices' do
        cmd = 'pvcreate /dev/sdx /dev/sdx1; vgcreate cinder-volumes /dev/sdx /dev/sdx1'
        expect(chef_run).to run_execute('Create Cinder volume group with block devices').with(command: cmd)
      end
    end

    describe 'cinder_emc_config.xml' do
      let(:file) { chef_run.template('/etc/cinder/cinder_emc_config.xml') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
      end

      it 'creates cinder emc config file' do
        expect(chef_run).to create_template(file.name).with(
          mode: 0644
        )
      end

      describe 'template contents' do
        before do
          allow_any_instance_of(Chef::Recipe).to receive(:get_password)
            .with('user', anything)
            .and_return('emc_test_pass')
        end

        %w(StorageType EcomServerPort EcomUserName).each do |attr|
          it "has an emc #{attr} setting" do
            node.set['openstack']['block-storage']['emc'][attr] = "emc_#{attr}_value"
            expect(chef_run).to render_file(file.name).with_content(/^<#{attr}>emc_#{attr}_value<\/#{attr}>$/)
          end
        end

        it 'has a EcomServerIP' do
          node.set['openstack']['block-storage']['emc']['EcomServerIP'] = 'emc_EcomServerIP_value'
          expect(chef_run).to render_file(file.name).with_content(/^<EcomServerIp>emc_EcomServerIP_value<\/EcomServerIp>$/)
        end

        it 'has EcomPassword' do
          node.set['openstack']['block-storage']['emc']['EcomUserName'] = 'emc_username'
          expect(chef_run).to render_file(file.name).with_content(/^<EcomPassword>emc_test_pass<\/EcomPassword>$/)
        end

        it 'does not have MaskingView when not specified' do
          expect(chef_run).not_to render_file(file.name).with_content(/^<MaskingView>/)
        end

        it 'has MaskingView when specified' do
          node.set['openstack']['block-storage']['emc']['MaskingView'] = 'testMaskingView'

          expect(chef_run).to render_file(file.name).with_content(/^<MaskingView>testMaskingView<\/MaskingView>$/)
        end
      end
    end
  end
end
