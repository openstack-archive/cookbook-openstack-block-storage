# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::scheduler' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'

    expect_creates_cinder_conf 'service[cinder-scheduler]', 'cinder', 'cinder'

    it 'upgrades cinder scheduler package' do
      expect(chef_run).to upgrade_package 'cinder-scheduler'
    end

    it 'starts cinder scheduler' do
      expect(chef_run).to start_service 'cinder-scheduler'
    end

    it 'starts cinder scheduler on boot' do
      expect(chef_run).to enable_service 'cinder-scheduler'
    end

    it 'upgrades mysql python package' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysqldb'
    end

    it 'does not setup cron when no metering' do
      expect(chef_run.cron('cinder-volume-usage-audit')).to be_nil
    end

    it 'creates cron metering default' do
      allow_any_instance_of(Chef::Recipe).to receive(:search)
        .with(:node, 'roles:os-block-storage-scheduler')
        .and_return([OpenStruct.new(name: 'fauxhai.local')])
      node.set['openstack']['telemetry'] = true

      cron = chef_run.cron 'cinder-volume-usage-audit'
      bin_str = '/usr/bin/cinder-volume-usage-audit > /var/log/cinder/audit.log'
      expect(cron.command).to match(/#{bin_str}/)
      crontests = [[:minute, '00'], [:hour, '*'], [:day, '*'],
                   [:weekday, '*'], [:month, '*'], [:user, 'cinder']]
      crontests.each do |k, v|
        expect(cron.send(k)).to eq v
        expect(chef_run).to create_cron('cinder-volume-usage-audit')
      end
      expect(cron.action).to include :create
    end

    it 'creates cron metering custom' do
      crontests = [[:minute, '50'], [:hour, '23'], [:day, '6'],
                   [:weekday, '5'], [:month, '11'], [:user, 'foobar']]
      allow_any_instance_of(Chef::Recipe).to receive(:search)
        .with(:node, 'roles:os-block-storage-scheduler')
        .and_return([OpenStruct.new(name: 'foobar')])
      node.set['openstack']['telemetry'] = true
      crontests.each do |k, v|
        node.set['openstack']['block-storage']['cron'][k.to_s] = v
      end
      node.set['openstack']['block-storage']['user'] = 'foobar'

      cron = chef_run.cron 'cinder-volume-usage-audit'
      crontests.each do |k, v|
        expect(cron.send(k)).to eq v
      end
      expect(cron.action).to include :delete
    end
  end
end
