require_relative "spec_helper"

describe "openstack-block-storage::api" do
  before { block_storage_stubs }
  describe "redhat" do
    before do
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "openstack-block-storage::api"
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
