# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/application'
require_relative 'support/matcher'

::LOG_LEVEL = :fatal
::SUSE_OPTS = {
  platform: 'suse',
  version: '11.03',
  log_level: ::LOG_LEVEL
}
::REDHAT_OPTS = {
  platform: 'redhat',
  version: '6.3',
  log_level: ::LOG_LEVEL
}
::UBUNTU_OPTS = {
  platform: 'ubuntu',
  version: '12.04',
  log_level: ::LOG_LEVEL
}

def block_storage_stubs # rubocop:disable MethodLength
  ::Chef::Recipe.any_instance.stub(:rabbit_servers)
    .and_return('1.1.1.1:5672,2.2.2.2:5672')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('service', anything)
    .and_return('')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('db', anything)
    .and_return('')
  ::Chef::Recipe.any_instance.stub(:secret)
    .with('secrets', 'openstack_identity_bootstrap_token')
    .and_return('bootstrap-token')
  ::Chef::Recipe.any_instance.stub(:secret)
    .with('secrets', 'rbd_secret_uuid')
    .and_return('b0ff3bba-e07b-49b1-beed-09a45552b1ad')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('user', 'guest')
    .and_return('rabbit-pass')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('user', 'solidfire_admin')
    .and_return('solidfire_testpass')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('service', 'openstack-block-storage')
    .and_return('cinder-pass')
  ::Chef::Recipe.any_instance.stub(:get_password)
    .with('service', 'openstack_image_cephx_key')
    .and_return('cephx-key')
  ::Chef::Application.stub(:fatal!)
end

def expect_runs_openstack_common_logging_recipe
  it 'runs logging recipe if node attributes say to' do
    expect(@chef_run).to include_recipe 'openstack-common::logging'
  end
end

def expect_creates_cinder_conf(service, user, group, action = :restart) # rubocop:disable MethodLength
  describe 'cinder.conf' do
    before do
      @file = @chef_run.template '/etc/cinder/cinder.conf'
    end

    it 'has proper owner' do
      expect(@file.owner).to eq(user)
      expect(@file.group).to eq(group)
    end

    it 'has proper modes' do
      expect(sprintf('%o', @file.mode)).to eq '644'
    end

    it 'notifies service restart' do
      expect(@file).to notify(service).to(action)
    end
  end
end

def expect_creates_policy_json(service, user, group, action = :restart) # rubocop:disable MethodLength
  describe 'policy.json' do
    before do
      @file = @chef_run.template '/etc/cinder/policy.json'
    end

    it 'has proper owner' do
      expect(@file.owner).to eq(user)
      expect(@file.group).to eq(group)
    end

    it 'has proper modes' do
      expect(sprintf('%o', @file.mode)).to eq '644'
    end

    it 'notifies service restart' do
      expect(@file).to notify(service).to(action)
    end
  end
end

# README(galstrom21): This will remove any coverage warnings from
#   dependent cookbooks
ChefSpec::Coverage.filters << '*/openstack-block-storage'

at_exit { ChefSpec::Coverage.report! }
