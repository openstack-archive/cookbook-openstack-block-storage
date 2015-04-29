# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'suse' do
    let(:runner) { ChefSpec::SoloRunner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'upgrades cinder volume package' do
      expect(chef_run).to upgrade_package('openstack-cinder-volume')
    end

    it 'upgrades qemu img package' do
      expect(chef_run).to upgrade_package('qemu-img')
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package('python-mysql')
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package('python-psycopg2')
      expect(chef_run).not_to upgrade_package('python-mysql')
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package('tgt')
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service('openstack-cinder-volume')
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service('openstack-cinder-volume')
    end

    context 'ISCSI' do
      let(:file) { chef_run.template('/etc/tgt/targets.conf') }
      it 'starts iscsi target on boot' do
        expect(chef_run).to enable_service('tgtd')
      end

      it 'has suse include' do
        expect(chef_run).to render_file(file.name).with_content('include /var/lib/cinder/volumes/*')
        expect(chef_run).not_to render_file(file.name).with_content('include /etc/tgt/conf.d/*.conf')
      end
    end

    context 'NFS Driver' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
      end

      it 'installs nfs packages' do
        expect(chef_run).to upgrade_package('nfs-utils')
        expect(chef_run).not_to upgrade_package('nfs-utils-lib')
      end
    end

    context 'EMC ISCSI Driver' do
      before do
        node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
      end

      it 'installs emc packages' do
        expect(chef_run).to upgrade_package('python-pywbem')
      end
    end
  end
end
