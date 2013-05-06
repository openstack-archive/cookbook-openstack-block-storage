require "spec_helper"

describe "cinder::scheduler" do
  describe "redhat" do
    before do
      glance_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "cinder::scheduler"
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
