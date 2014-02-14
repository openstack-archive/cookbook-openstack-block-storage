# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  before { block_storage_stubs }
  before do
    @chef_run = ::ChefSpec::Runner.new ::SUSE_OPTS do |n|
      n.set['openstack']['mq'] = {
        'host' => '127.0.0.1'
      }
      n.set['openstack']['block-storage']['syslog']['use'] = true
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      n.set['cpu']['total'] = 1
    end
    @chef_run.converge 'openstack-block-storage::cinder-common'
  end

  it 'installs the openstack-cinder package' do
    expect(@chef_run).to upgrade_package 'openstack-cinder'
  end
end
