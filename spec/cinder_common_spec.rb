require_relative "spec_helper"

describe "openstack-block-storage::cinder-common" do
  before { block_storage_stubs }
  before do
    @chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS do |n|
      n.set["openstack"]["block-storage"]["syslog"]["use"] = true
    end
    @chef_run.converge "openstack-block-storage::cinder-common"
  end

  describe "/etc/cinder" do
    before do
     @dir = @chef_run.directory "/etc/cinder"
    end

    it "has proper owner" do
      expect(@dir).to be_owned_by "cinder", "cinder"
    end

    it "has proper modes" do
     expect(sprintf("%o", @dir.mode)).to eq "750"
    end
  end

  describe "cinder.conf" do
    before do
     @file = @chef_run.template "/etc/cinder/cinder.conf"
    end

    it "has proper owner" do
      expect(@file).to be_owned_by "cinder", "cinder"
    end

    it "has proper modes" do
     expect(sprintf("%o", @file.mode)).to eq "644"
    end
  end
end
