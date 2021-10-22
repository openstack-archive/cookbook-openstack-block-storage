#
# Cookbook:: openstack-block-storage

require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
  config.log_level = :warn
  config.file_cache_path = '/var/chef/cache'
end

REDHAT_7 = {
  platform: 'redhat',
  version: '7',
}.freeze

REDHAT_8 = {
  platform: 'redhat',
  version: '8',
}.freeze

ALL_RHEL = [
  REDHAT_7,
  REDHAT_8,
].freeze

UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '18.04',
}.freeze

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
      .with('user', 'admin')
      .and_return('emc_test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'ibmnas_admin')
      .and_return('test_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('block_storage')
      .and_return('rabbit://guest:mypass@127.0.0.1:5672')
    stub_command('/usr/sbin/httpd -t').and_return(true)
    stub_command('/usr/sbin/apache2 -t').and_return(true)
    allow(Chef::Application).to receive(:fatal!)
    # identity stubs
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'credential_key0')
      .and_return('thisiscredentialkey0')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'credential_key1')
      .and_return('thisiscredentialkey1')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'fernet_key0')
      .and_return('thisisfernetkey0')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('secrets', 'fernet_key1')
      .and_return('thisisfernetkey1')
    allow_any_instance_of(Chef::Recipe).to receive(:search_for)
      .with('os-identity').and_return(
        [{
          'openstack' => {
            'identity' => {
              'admin_tenant_name' => 'admin',
              'admin_user' => 'admin',
            },
          },
        }]
      )
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers)
      .and_return([])
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('identity')
      .and_return('rabbit://openstack:mypass@127.0.0.1:5672')
  end
end

shared_examples 'common-logging' do
  context 'when syslog.use is true' do
    cached(:chef_run) do
      node.override['openstack']['block-storage']['syslog']['use'] = true
      runner.converge(described_recipe)
    end

    it 'runs logging recipe if node attributes say to' do
      expect(chef_run).to include_recipe 'openstack-common::logging'
    end
  end

  context 'when syslog.use is false' do
    cached(:chef_run) do
      node.override['openstack']['block-storage']['syslog']['use'] = false
      runner.converge(described_recipe)
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

shared_examples 'creates_cinder_conf' do |service, user, group, action = :restart|
  describe 'cinder.conf' do
    let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

    it 'creates the /etc/cinder/cinder.conf file' do
      expect(chef_run).to create_template(file.name).with(
        user: user,
        group: group,
        mode: '640'
      )
    end

    it 'notifies service restart' do
      expect(file).to notify(service).to(action)
    end

    it do
      [
        /^auth_type = password$/,
        /^region_name = RegionOne$/,
        /^username = cinder/,
        /^project_name = service$/,
        /^user_domain_name = Default/,
        /^project_domain_name = Default/,
        %r{^auth_url = http://127.0.0.1:5000/v3$},
        /^password = cinder-pass$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name)
          .with_section_content('keystone_authtoken', line)
      end
    end

    it 'has oslo_messaging_notifications conf values' do
      [
        /^driver = cinder.openstack.common.notifier.rpc_notifier$/,
      ].each do |line|
        expect(chef_run).to render_config_file(file.name).with_section_content('oslo_messaging_notifications', line)
      end
    end
  end
end
