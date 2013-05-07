require "spec_helper"

describe "cinder::api" do
  describe "redhat" do
    before do
      cinder_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "cinder::api"
    end

    it "installs cinder api packages" do
      expect(@chef_run).to upgrade_package "openstack-cinder"
      expect(@chef_run).to upgrade_package "python-cinderclient"
      expect(@chef_run).to upgrade_package "MySQL-python"
    end

    it "starts cinder api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "openstack-cinder-api"
    end
  end
end
