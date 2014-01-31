# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  before { block_storage_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['syslog']['use'] = true
      end
      @chef_run.converge 'openstack-block-storage::volume'
    end

    expect_runs_openstack_common_logging_recipe

    it 'does not run logging recipe' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).not_to include_recipe 'openstack-common::logging'
    end

    it 'installs cinder volume packages' do
      expect(@chef_run).to upgrade_package 'cinder-volume'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysqldb'
    end

    it 'installs cinder iscsi packages' do
      expect(@chef_run).to upgrade_package 'tgt'
    end

    it 'installs nfs packages' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
      end
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).to upgrade_package 'nfs-common'
    end

    it 'creates the nfs mount point' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
      end
      chef_run.converge 'openstack-block-storage::volume'

      expect(chef_run).to create_directory '/mnt/cinder-volumes'
    end

    it 'configures netapp dfm password' do
      ::Chef::Recipe.any_instance.stub(:get_password).with('service', 'netapp')
        .and_return 'netapp-pass'
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.iscsi.NetAppISCSIDriver'
      end
      chef_run.converge 'openstack-block-storage::volume'
      n = chef_run.node['openstack']['block-storage']['netapp']['dfm_password']

      expect(n).to eq 'netapp-pass'
    end

    describe 'RBD Ceph as block-storage backend' do
      before do
        @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
          n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          n.set['openstack']['block-storage']['rbd_secret_name'] = 'rbd_secret_uuid'
          # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
          n.set['cpu']['total'] = 1
        end
        @chef_run.converge 'openstack-block-storage::volume'
      end

      it 'fetches the rbd_uuid_secret' do
        n = @chef_run.node['openstack']['block-storage']['rbd_secret_uuid']
        expect(n).to eq 'b0ff3bba-e07b-49b1-beed-09a45552b1ad'
      end

      it 'includes the ceph_client recipe' do
        expect(@chef_run).to include_recipe('openstack-common::ceph_client')
      end

      it 'installs the python-ceph package by default' do
        expect(@chef_run).to install_package('python-ceph')
      end

      it 'honors package option platform overrides for python-ceph' do
        @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
          n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          n.set['openstack']['block-storage']['rbd_secret_name'] = 'rbd_secret_uuid'
          n.set['openstack']['block-storage']['platform']['package_overrides'] = '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes'
        end
        @chef_run.converge 'openstack-block-storage::volume'

        expect(@chef_run).to install_package('python-ceph').with(options: '-o Dpkg::Options::=\'--force-confold\' -o Dpkg::Options::=\'--force-confdef\' --force-yes')
      end

      it 'honors package name platform overrides for python-ceph' do
        @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
          n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          n.set['openstack']['block-storage']['rbd_secret_name'] = 'rbd_secret_uuid'
          n.set['openstack']['block-storage']['platform']['cinder_ceph_packages'] = ['my-ceph', 'my-other-ceph']
        end
        @chef_run.converge 'openstack-block-storage::volume'

        %w{my-ceph my-other-ceph}.each do |pkg|
          expect(@chef_run).to install_package(pkg)
        end
      end

      it 'creates a cephx client keyring' do
        pending 'https://review.openstack.org/#/c/69368/'
        @file = '/etc/ceph/ceph.client.cinder.keyring'
        [/^\[client\.cinder\]$/,
         /key = cephx-key$/].each do |content|
          expect(@chef_run).to render_file(@file).with_content(content)
          expect(@chef_run).to create_template(@file).with(
            cookbook: 'openstack-common',
            owner: 'cinder',
            group: 'cinder',
            mode: 0600
          )
        end
      end
    end

    it 'configures storewize private key' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.storwize_svc.StorwizeSVCDriver'
      end
      chef_run.converge 'openstack-block-storage::volume'

      san_key = chef_run.file chef_run.node['openstack']['block-storage']['san']['san_private_key']
      expect(san_key.mode).to eq('0400')
    end

    it 'configures storewize with iscsi' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.storwize_svc.StorwizeSVCDriver'
        n.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'iSCSI'
      end
      conf = '/etc/cinder/cinder.conf'
      chef_run.converge 'openstack-block-storage::volume'

      # Test that the FC specific options are not set when connected via iSCSI
      expect(chef_run).not_to render_file(conf).with_content('storwize_svc_multipath_enabled')
    end

    it 'configures storewize with fc' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.storwize_svc.StorwizeSVCDriver'
        n.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'FC'
      end
      conf = '/etc/cinder/cinder.conf'
      chef_run.converge 'openstack-block-storage::volume'

      # Test that the iSCSI specific options are not set when connected via FC
      expect(chef_run).not_to render_file(conf).with_content('storwize_svc_iscsi_chap_enabled')
    end

    it 'starts cinder volume' do
      expect(@chef_run).to start_service 'cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expect(@chef_run).to enable_service 'cinder-volume'
    end

    expect_creates_cinder_conf 'service[cinder-volume]', 'cinder', 'cinder'

    it 'starts iscsi target on boot' do
      expect(@chef_run).to enable_service 'tgt'
    end

    describe 'targets.conf' do
      before do
        @file = @chef_run.template '/etc/tgt/targets.conf'
      end

      it 'has proper modes' do
        expect(sprintf('%o', @file.mode)).to eq '600'
      end

      it 'notifies iscsi restart' do
        expect(@file).to notify('service[iscsitarget]').to(:restart)
      end

      it 'has ubuntu include' do
        expect(@chef_run).to render_file(@file.name).with_content('include /etc/tgt/conf.d/*.conf')
        expect(@chef_run).not_to render_file(@file.name).with_content('include /var/lib/cinder/volumes/*')
      end
    end

    describe 'create_vg' do
      before do
        @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
          n.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMISCSIDriver'
          n.set['openstack']['block-storage']['volume']['create_volume_group'] = true
        end
        stub_command('vgs cinder-volumes').and_return(false)
        @filename = '/etc/init.d/cinder-group-active'
        @chef_run.converge 'openstack-block-storage::volume'
        @file = @chef_run.template(@filename)
      end

      it 'cinder vg active' do
        expect(@chef_run).to enable_service 'cinder-group-active'
      end

      it 'create volume group' do
        volume_size = @chef_run.node['openstack']['block-storage']['volume']['volume_group_size']
        seek_count = volume_size.to_i * 1024
        group_name = @chef_run.node['openstack']['block-storage']['volume']['volume_group']
        path = @chef_run.node['openstack']['block-storage']['volume']['state_path']
        vg_file = "#{path}/#{group_name}.img"
        cmd = "dd if=/dev/zero of=#{vg_file} bs=1M seek=#{seek_count} count=0; vgcreate cinder-volumes $(losetup --show -f #{vg_file})"
        expect(@chef_run).to run_execute(cmd)
      end

      it 'notifies cinder group active start' do
        expect(@file).to notify('service[cinder-group-active]').to(:start)
      end

      it 'creates cinder group active template file' do
        expect(@chef_run).to create_template(@filename)
      end
    end
  end
end
