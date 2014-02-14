# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  before { block_storage_stubs }
  describe 'ubuntu' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        n.set['openstack']['block-storage']['syslog']['use'] = true
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      @chef_run.converge 'openstack-block-storage::scheduler'
    end

    expect_runs_openstack_common_logging_recipe

    it 'does not run logging recipe' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
      end
      chef_run.converge 'openstack-block-storage::scheduler'

      expect(chef_run).not_to include_recipe 'openstack-common::logging'
    end

    it 'installs cinder scheduler packages' do
      expect(@chef_run).to upgrade_package 'cinder-scheduler'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      node.set['cpu']['total'] = 1
      chef_run.converge 'openstack-block-storage::scheduler'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysqldb'
    end

    it 'starts cinder scheduler' do
      expect(@chef_run).to start_service 'cinder-scheduler'
    end

    it 'starts cinder scheduler on boot' do
      expect(@chef_run).to enable_service 'cinder-scheduler'
    end

    it 'does not run logging recipe' do
      expect(@chef_run).to enable_service 'cinder-scheduler'
    end

    it 'does not setup cron when no metering' do
      expect(@chef_run.cron('cinder-volume-usage-audit')).to be_nil
    end

    it 'creates cron metering default' do
      ::Chef::Recipe.any_instance.stub(:search)
        .with(:node, 'roles:os-block-storage-scheduler')
        .and_return([OpenStruct.new(name: 'fauxhai.local')])
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
        n.set['openstack']['metering'] = true
      end
      chef_run.converge 'openstack-block-storage::scheduler'
      cron = chef_run.cron 'cinder-volume-usage-audit'
      bin_str = '/usr/bin/cinder-volume-usage-audit > /var/log/cinder/audit.log'
      expect(cron.command).to match(/#{bin_str}/)
      crontests = [[:minute, '00'], [:hour, '*'], [:day, '*'],
                   [:weekday, '*'], [:month, '*'], [:user, 'cinder']]
      crontests.each do |k, v|
        expect(cron.send(k)).to eq v
      end
      expect(cron.action).to include :create
    end

    it 'creates cron metering custom' do
      crontests = [[:minute, '50'], [:hour, '23'], [:day, '6'],
                   [:weekday, '5'], [:month, '11'], [:user, 'foobar']]
      ::Chef::Recipe.any_instance.stub(:search)
        .with(:node, 'roles:os-block-storage-scheduler')
        .and_return([OpenStruct.new(name: 'foobar')])
      chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
        # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
        n.set['cpu']['total'] = 1
        n.set['openstack']['metering'] = true
        crontests.each do |k, v|
          n.set['openstack']['block-storage']['cron'][k.to_s] = v
        end
        n.set['openstack']['block-storage']['user'] = 'foobar'
      end
      chef_run.converge 'openstack-block-storage::scheduler'
      cron = chef_run.cron 'cinder-volume-usage-audit'
      crontests.each do |k, v|
        expect(cron.send(k)).to eq v
      end
      expect(cron.action).to include :delete
    end

    expect_creates_cinder_conf 'service[cinder-scheduler]', 'cinder', 'cinder'
  end
end
