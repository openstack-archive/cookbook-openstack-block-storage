require "spec_helper"

describe "cinder::scheduler" do
  describe "ubuntu" do
    before do
      cinder_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["cinder"]["syslog"]["use"] = true
      @node.set["cinder"]["volume"]["volume_driver"] = "cinder.volume.driver.RBDDriver"
      @chef_run.converge "cinder::scheduler"
    end

    expect_runs_openstack_common_logging_recipe

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

    describe "cinder-volume-usage-audit" do
      before do
        f = "/usr/local/bin/cinder-volume-usage-audit"
        @file = @chef_run.cookbook_file f
      end 

      it "has proper owner" do
        expect(@file).to be_owned_by "root", "root"
      end 

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "755"
      end 
    end 

    it "has cinder-volume-usage-audit cronjob" do
      cron = @chef_run.cron "cinder-volume-usage-audit"
      cmd = "/usr/local/bin/cinder-volume-usage-audit > " \
            "/var/log/cinder/audit.log 2>&1"
      expect(cron.command).to eq cmd
      expect(cron.minute).to eq '00'
    end

    expect_creates_cinder_conf "service[cinder-scheduler]"
  end
end
