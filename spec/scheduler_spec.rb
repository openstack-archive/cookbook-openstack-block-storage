require "spec_helper"

describe "openstack-block-storage::scheduler" do
  describe "ubuntu" do
    before do
      cinder_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["openstack-block-storage"]["syslog"]["use"] = true
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
      expect(@chef_run).to upgrade_package "python-mysqldb"
    end

    it "starts cinder scheduler" do
      expect(@chef_run).to start_service "cinder-scheduler"
    end

    it "starts cinder scheduler on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "cinder-scheduler"
    end

    expect_creates_cinder_conf "service[cinder-scheduler]"
  end
end
