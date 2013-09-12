require_relative "spec_helper"

describe "openstack-block-storage::scheduler" do
  before { block_storage_stubs }
  describe "ubuntu" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS do |n|
        n.set["openstack"]["block-storage"]["syslog"]["use"] = true
      end
      @chef_run.converge "openstack-block-storage::scheduler"
    end

    expect_runs_openstack_common_logging_recipe

    it "doesn't run logging recipe" do
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      chef_run.converge "openstack-block-storage::scheduler"

      expect(chef_run).not_to include_recipe "openstack-common::logging"
    end

    it "installs cinder api packages" do
      expect(@chef_run).to upgrade_package "cinder-scheduler"
    end

    it "upgrades stevedore" do
      expect(@chef_run).to upgrade_python_pip "stevedore"
    end

    it "does not upgrade stevedore" do
      opts = ::UBUNTU_OPTS.merge(:version => "10.04")
      chef_run = ::ChefSpec::ChefRunner.new opts
      chef_run.converge "openstack-block-storage::scheduler"

      expect(chef_run).not_to upgrade_python_pip "stevedore"
    end

    it "installs mysql python packages by default" do
      expect(@chef_run).to upgrade_package "python-mysqldb"
    end

    it "installs postgresql python packages if explicitly told" do
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      node = chef_run.node
      node.set["openstack"]["db"]["volume"]["db_type"] = "postgresql"
      chef_run.converge "openstack-block-storage::scheduler"

      expect(chef_run).to upgrade_package "python-psycopg2"
      expect(chef_run).not_to upgrade_package "python-mysqldb"
    end

    it "starts cinder scheduler" do
      expect(@chef_run).to start_service "cinder-scheduler"
    end

    it "starts cinder scheduler on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "cinder-scheduler"
    end

    it "doesn't run logging recipe" do
      expect(@chef_run).to set_service_to_start_on_boot "cinder-scheduler"
    end

    it "doesn't setup cron when no metering" do
      expect(@chef_run.cron("cinder-volume-usage-audit")).to be_nil
    end

    it "creates cron metering default" do
      ::Chef::Recipe.any_instance.stub(:search).
        with(:node, "roles:os-block-storage-scheduler").
        and_return([OpenStruct.new(:name => "fauxhai.local")])
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS do |n|
        n.set["openstack"]["metering"] = true
      end
      chef_run.converge "openstack-block-storage::scheduler"
      cron = chef_run.cron "cinder-volume-usage-audit"
      expect(cron.command).to match(/\/usr\/local\/bin\/cinder-volume-usage-audit/)
      expect(cron.command).to match(/\/var\/log\/cinder\/audit.log/)
      expect(cron.minute).to eq "00"
      expect(cron.hour).to eq "*"
      expect(cron.day).to eq "*"
      expect(cron.weekday).to eq "*"
      expect(cron.month).to eq "*"
      expect(cron.user).to eq "cinder"
      expect(cron.action).to include :create
    end

    it "creates cron metering custom" do
      ::Chef::Recipe.any_instance.stub(:search).
        with(:node, "roles:os-block-storage-scheduler").
        and_return([OpenStruct.new(:name => "foobar")])
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS do |n|
        n.set["openstack"]["metering"] = true
        n.set["openstack"]["block-storage"]["cron"]["minute"] = 50
        n.set["openstack"]["block-storage"]["cron"]["hour"] = 23
        n.set["openstack"]["block-storage"]["cron"]["day"] = 6
        n.set["openstack"]["block-storage"]["cron"]["weekday"] = 5
        n.set["openstack"]["block-storage"]["cron"]["month"] = 11
        n.set["openstack"]["block-storage"]["user"] = "foobar"
      end
      chef_run.converge "openstack-block-storage::scheduler"
      cron = chef_run.cron "cinder-volume-usage-audit"
      expect(cron.minute).to eq "50"
      expect(cron.hour).to eq "23"
      expect(cron.day).to eq "6"
      expect(cron.weekday).to eq "5"
      expect(cron.month).to eq "11"
      expect(cron.user).to eq "foobar"
      expect(cron.action).to include :delete
    end

    expect_creates_cinder_conf "service[cinder-scheduler]", "cinder", "cinder"
  end
end
