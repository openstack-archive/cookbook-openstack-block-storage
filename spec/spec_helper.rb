# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'openstack-block-storage' }

require 'chef/application'

LOG_LEVEL = :fatal
SUSE_OPTS = {
  platform: 'suse',
  version: '11.3',
  log_level: LOG_LEVEL
}
REDHAT_OPTS = {
  platform: 'redhat',
  version: '7.1',
  log_level: LOG_LEVEL
}
UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '14.04',
  log_level: LOG_LEVEL
}

shared_context 'block-storage-stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return('1.1.1.1:5672,2.2.2.2:5672')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'rbd_secret_uuid')
      .and_return('b0ff3bba-e07b-49b1-beed-09a45552b1ad')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'guest')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'netapp')
      .and_return 'netapp-pass'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-block-storage')
      .and_return('cinder-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack_image_cephx_key')
      .and_return('cephx-key')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('emc_test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'ibmnas_admin')
      .and_return('test_pass')
    allow(Chef::Application).to receive(:fatal!)
  end
end

shared_examples 'common-logging' do
  context 'when syslog.use is true' do
    before do
      node.set['openstack']['block-storage']['syslog']['use'] = true
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to include_recipe 'openstack-common::logging'
    end
  end

  context 'when syslog.use is false' do
    before do
      node.set['openstack']['block-storage']['syslog']['use'] = false
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to_not include_recipe 'openstack-common::logging'
    end
  end
end

def expect_runs_openstack_common_logging_recipe
  it 'runs logging recipe if node attributes say to' do
    expect(chef_run).to include_recipe 'openstack-common::logging'
  end
end

def expect_creates_cinder_conf(service, user, group, action = :restart) # rubocop:disable MethodLength
  describe 'cinder.conf' do
    let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

    it 'creates the /etc/cinder/cinder.conf file' do
      expect(chef_run).to create_template(file.name).with(
        user: user,
        group: group,
        mode: 0640
      )
    end

    it 'notifies service restart' do
      expect(file).to notify(service).to(action)
    end
  end
end
