require "spec_helper"

describe "cinder::volume" do
  describe "ubuntu" do
    before do
      glance_stubs
      @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
      @node = @chef_run.node
      @node.set["cinder"]["syslog"]["use"] = true
      @chef_run.converge "cinder::volume"
    end

    expect_runs_openstack_common_logging_recipe

    it "installs cinder volume packages" do
      expect(@chef_run).to upgrade_package "cinder-volume"
      expect(@chef_run).to upgrade_package "python-mysqldb"
    end

    it "installs cinder iscsi packages" do
      expect(@chef_run).to upgrade_package "tgt"
    end

    it "starts cinder volume" do
      expect(@chef_run).to start_service "cinder-volume"
    end

    it "starts cinder volume on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "cinder-volume"
    end

    expect_creates_cinder_conf "service[cinder-volume]"

    it "starts iscsi target on boot" do
      expect(@chef_run).to set_service_to_start_on_boot "tgt"
    end

    describe "targets.conf" do
      before do
        @file = @chef_run.template "/etc/tgt/targets.conf"
      end 

      it "has proper modes" do
        expect(sprintf("%o", @file.mode)).to eq "600"
      end 

      it "notifies nova-api-ec2 restart" do
        expect(@file).to notify "service[iscsitarget]", :restart
      end
    end 

    describe "patches" do
      before do
        @os_dir = "/usr/share/pyshared/cinder/openstack/common"
        @dist_dir = "/usr/lib/python2.7/dist-packages/cinder/openstack/common"
      end

      describe "fileutils.py" do
        before do
          @source = ::File.join @os_dir, "fileutils.py"
          @file = @chef_run.cookbook_file @source
        end 

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end 

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end 

        it "symlinks fileutils.py" do
          ln = ::File.join @dist_dir, "fileutils.py"
          expect(@chef_run.link(ln)).to link_to @source
        end
      end 

      describe "gettextutils.py" do
        before do
          @source = ::File.join @os_dir, "gettextutils.py"
          @file = @chef_run.cookbook_file @source
        end 

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end 

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end 

        it "symlinks gettextutils.py" do
          pending "TODO: should there be a gettextutils symlink?"
        end
      end

      describe "lockutils.py" do
        before do
          @source = ::File.join @os_dir, "lockutils.py"
          @file = @chef_run.cookbook_file @source
        end 

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end 

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end 

        it "symlinks gettextutils.py" do
          ln = ::File.join @dist_dir, "lockutils.py"
          expect(@chef_run.link(ln)).to link_to @source
        end
      end

      describe "netapp.py" do
        before do
          f = "/usr/share/pyshared/cinder/volume/netapp.py"
          @file = @chef_run.cookbook_file f
        end 

        it "has proper owner" do
          expect(@file).to be_owned_by "root", "root"
        end 

        it "has proper modes" do
          expect(sprintf("%o", @file.mode)).to eq "644"
        end 

        it "notifies nova-api-ec2 restart" do
          expect(@file).to notify "service[cinder-volume]", :restart
        end
      end
    end
  end
end
