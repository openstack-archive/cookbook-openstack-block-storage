# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'redhat' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('MySQL-python')
    end

    it 'upgrades db2 python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'db2'

      ['python-ibm-db', 'python-ibm-db-sa'].each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
      end
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package('python-psycopg2')
      expect(chef_run).not_to upgrade_package('MySQL-python')
    end

    it 'upgrades qemu img package' do
      expect(chef_run).to upgrade_package('qemu-img')
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package('targetcli')
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service('openstack-cinder-volume')
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service('openstack-cinder-volume')
    end

    context 'ISCSI' do
      it 'starts iscsi target on boot' do
        expect(chef_run).to enable_service('target')
      end
    end

    context 'IBMNAS Driver' do
      let(:file) { chef_run.template('/etc/cinder/nfs_shares.conf') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
        node.set['openstack']['block-storage']['ibmnas']['nas_access_ip'] = '127.0.0.1'
        node.set['openstack']['block-storage']['ibmnas']['export'] = '/ibm/fs/export'
      end

      it 'creates IBMNAS shares_config file' do
        expect(chef_run).to create_template(file.name).with(
          owner: 'cinder',
          group: 'cinder',
          mode: '0600'
        )
        expect(chef_run).to render_file(file.name).with_content('127.0.0.1:/ibm/fs/export')
      end

      it 'upgrades nfs packages' do
        expect(chef_run).to upgrade_package 'nfs-utils'
        expect(chef_run).to upgrade_package 'nfs-utils-lib'
      end

      it 'creates the nfs mount point' do
        expect(chef_run).to create_directory('/mnt/cinder-volumes').with(
          owner: 'cinder',
          group: 'cinder',
          mode: '0755'
        )
      end
    end

    context 'NFS Driver' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
      end

      it 'upgrades nfs packages' do
        expect(chef_run).to upgrade_package('nfs-utils')
        expect(chef_run).to upgrade_package('nfs-utils-lib')
      end
    end

    context 'EMC ISCSI Driver' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
      end

      it 'upgrades emc package' do
        expect(chef_run).to upgrade_package('pywbem')
      end
    end

    describe 'IBM GPFS volume driver' do
      before do
        @chef_run = ::ChefSpec::SoloRunner.new ::REDHAT_OPTS do |n|
          n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.gpfs.GPFSDriver'
          n.set['openstack']['block-storage']['gpfs']['gpfs_mount_point_base'] = 'volumes'
        end

        @conf = '/etc/cinder/cinder.conf'
        @chef_run.converge 'openstack-block-storage::volume'
      end

      it 'verifies gpfs_mount_point_base' do
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_mount_point_base = volumes$/)
      end

      it 'verifies gpfs_images_dir and gpfs_images_share_mode is set with default value' do
        @chef_run.node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = 'images'
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_images_dir = images$/)
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_images_share_mode = copy_on_write$/)
      end

      it 'verifies gpfs_images_dir and gpfs_images_share_mode set correctly' do
        @chef_run.node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = 'images'
        @chef_run.node.set['openstack']['block-storage']['gpfs']['gpfs_images_share_mode'] = 'copy'
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_images_dir = images$/)
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_images_share_mode = copy$/)
      end

      it 'verifies gpfs_sparse_volumes is default' do
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_sparse_volumes = true$/)
      end

      it 'verifies gpfs_max_clone_depth is default' do
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_max_clone_depth = 8$/)
      end

      it 'verifies gpfs_storage_pool is default' do
        expect(@chef_run).to render_file(@conf).with_content(
          /^gpfs_storage_pool = system$/)
      end

      it 'verifies gpfs volume directory is created with owner and mode set correctly' do
        expect(@chef_run).to create_directory('volumes').with(
          owner: 'cinder',
          group: 'cinder',
          mode: '0755'
        )
      end
    end

    describe 'create_vg' do
      let(:file) { chef_run.template('/etc/init.d/cinder-group-active') }
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
        node.set['openstack']['block-storage']['volume']['create_volume_group'] = true
        stub_command('vgs cinder-volumes').and_return(false)
      end

      describe 'template contents' do
        it 'sources /etc/rc.d/init.d/functions' do
          expect(chef_run).to render_file(file.name).with_content(%r{^\s*. /etc/rc.d/init.d/functions$})
        end

        it 'calls success and echo' do
          [/^\s*success$/, /^\s*echo$/].each do |cmd|
            expect(chef_run).to render_file(file.name).with_content(cmd)
          end
        end
      end
    end
  end
end
