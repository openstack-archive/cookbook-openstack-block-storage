require "spec_helper"

describe "cinder::api" do
  describe "ubuntu" do
    before do
      cinder_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["cinder"]["syslog"]["use"] = true
      @chef_run.converge "cinder::api"
    end

    expect_runs_openstack_common_logging_recipe

    it "doesn't run logging recipe" do
      chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      chef_run.converge "cinder::api"

      expect(chef_run).not_to include_recipe "openstack-common::logging"
    end

    it "installs cinder api packages" do
      expect(@chef_run).to upgrade_package "cinder-common"
      expect(@chef_run).to upgrade_package "cinder-api"
      expect(@chef_run).to upgrade_package "python-cinderclient"
      expect(@chef_run).to upgrade_package "python-mysqldb"
    end

    ##
    #TODO: ChefSpec needs to handle guards better.  This
    #      should only be created when pki is enabled.
    describe "/var/cache/cinder" do
      before do
        @dir = @chef_run.directory "/var/cache/cinder"
      end

      it "has proper owner" do
        expect(@dir).to be_owned_by "cinder", "cinder"
      end

      it "has proper modes" do
        expect(sprintf("%o", @dir.mode)).to eq "700"
      end
    end

    it "starts cinder api on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "cinder-api"
    end

    expect_creates_cinder_conf "service[cinder-api]"

    describe "cinder.conf" do
      before do
        @file = "/etc/cinder/cinder.conf"
      end

      it "runs logging recipe if node attributes say to" do
        expect(@chef_run).to create_file_with_content @file,
          "log_config = /etc/openstack/logging.conf"
      end

      it "doesn't run logging recipe" do
        chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
        chef_run.converge "cinder::api"

        expect(chef_run).not_to create_file_with_content @file,
          "log_config = /etc/openstack/logging.conf"
      end

      it "has rbd driver settings" do
        chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
        node = chef_run.node
        node.set["cinder"]["volume"] = {
          "volume_driver" => "cinder.volume.driver.RBDDriver"
        }
        chef_run.converge "cinder::api"

        expect(chef_run).to create_file_with_content @file,
          /^rbd_/
        expect(chef_run).not_to create_file_with_content @file,
          /^netapp_/
      end

      it "has netapp driver settings" do
        chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
        node = chef_run.node
        node.set["cinder"]["volume"] = {
          "volume_driver" => "cinder.volume.netapp.NetAppISCSIDriver"
        }
        chef_run.converge "cinder::api"

        expect(chef_run).to create_file_with_content @file,
          /^netapp_/
        expect(chef_run).not_to create_file_with_content @file,
          /^rbd_/
      end
    end

    it "runs db migrations" do
      cmd = "cinder-manage db sync"
      expect(@chef_run).to execute_command cmd
    end

    describe "api-paste.ini" do
      before do
        @file = @chef_run.template "/etc/cinder/api-paste.ini"
      end

      it "has proper owner" do
        expect(@file).to be_owned_by "cinder", "cinder"
      end

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "644"
      end

      it "has signing_dir with auth_strategy is pki" do
        chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
        node = chef_run.node
        node.set["openstack"]["auth"]["strategy"] = "pki"
        chef_run.converge "cinder::api"

        expect(chef_run).to create_file_with_content @file.name,
          "signing_dir = /var/cache/cinder/api"
      end

      it "does not have signing_dir when auth strategy is not pki" do
        expect(@chef_run).not_to create_file_with_content @file.name,
          "signing_dir = /var/cache/cinder/api"
      end

      it "notifies nova-api-ec2 restart" do
        expect(@file).to notify "service[cinder-api]", :restart
      end
    end
  end
end
