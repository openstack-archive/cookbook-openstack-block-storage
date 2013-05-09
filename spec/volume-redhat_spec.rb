require "spec_helper"

describe "cinder::volume" do
  describe "redhat" do
    before do
      cinder_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::REDHAT_OPTS
      @chef_run.converge "cinder::volume"
    end

    it "installs cinder volume packages" do
      expect(@chef_run).to upgrade_package "openstack-cinder"
      expect(@chef_run).to upgrade_package "MySQL-python"
    end

    it "installs cinder iscsi packages" do
      expect(@chef_run).to upgrade_package "scsi-target-utils"
    end

    it "starts cinder volume" do
      expect(@chef_run).to start_service "openstack-cinder-volume"
    end

    it "starts cinder volume on boot" do
      expected = "openstack-cinder-volume"
      expect(@chef_run).to set_service_to_start_on_boot expected
    end

    it "starts iscsi target on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "tgtd"
    end

    it "has redhat include" do
      file = "/etc/tgt/targets.conf"
      expect(@chef_run).to create_file_with_content file,
        "include /var/lib/cinder/volumes/*"
      expect(@chef_run).not_to create_file_with_content file,
        "include /etc/tgt/conf.d/*.conf"
    end

    it "has different tgt" do
      expect(@chef_run).to create_file_with_content "/etc/tgt/targets.conf", "/var/lib/cinder/volumes"
    end
  end
end
