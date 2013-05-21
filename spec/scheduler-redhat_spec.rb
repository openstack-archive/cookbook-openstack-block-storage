require "spec_helper"

describe "openstack-block-storage::scheduler" do
  describe "redhat" do
    before do
      block_storage_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-block-storage::scheduler"
    end

    it "installs cinder api packages" do
      expect(@chef_run).to upgrade_package "openstack-cinder"
      expect(@chef_run).to upgrade_package "MySQL-python"
    end

    it "starts cinder scheduler" do
      expect(@chef_run).to start_service "openstack-cinder-scheduler"
    end

    it "starts cinder scheduler on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-cinder-scheduler"
    end
  end
end
