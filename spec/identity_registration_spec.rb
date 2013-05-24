require "spec_helper"

describe "openstack-block-storage::identity_registration" do
  before do
    @identity_register_mock = double "identity_register"
  end

  it "registers cinder volume service" do
    block_storage_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Cinder Volume Service") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_name).
          with "cinder"
        @identity_register_mock.should_receive(:service_type).
          with "volume"
        @identity_register_mock.should_receive(:service_description).
          with "Cinder Volume Service"
        @identity_register_mock.should_receive(:endpoint_region).
          with "RegionOne"
        @identity_register_mock.should_receive(:endpoint_adminurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_internalurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_publicurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:action).
          with :create_service

        @identity_register_mock.instance_eval &arg
      end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-block-storage::identity_registration"
  end

  it "registers cinder volume endpoint" do
    block_storage_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Cinder Volume Endpoint") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:service_name).
          with "cinder"
        @identity_register_mock.should_receive(:service_type).
          with "volume"
        @identity_register_mock.should_receive(:service_description).
          with "Cinder Volume Service"
        @identity_register_mock.should_receive(:endpoint_region).
          with "RegionOne"
        @identity_register_mock.should_receive(:endpoint_adminurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_internalurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:endpoint_publicurl).
          with "https://127.0.0.1:8776/v1/%(tenant_id)s"
        @identity_register_mock.should_receive(:action).
          with :create_endpoint

        @identity_register_mock.instance_eval &arg
      end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-block-storage::identity_registration"
  end

  it "registers service user" do
    block_storage_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Register Cinder Service User") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:tenant_name).
          with "service"
        @identity_register_mock.should_receive(:user_name).
          with "cinder"
        @identity_register_mock.should_receive(:user_pass).
          with "cinder-pass"
        @identity_register_mock.should_receive(:user_enabled).
          with "true"
        @identity_register_mock.should_receive(:action).
          with :create_user

        @identity_register_mock.instance_eval &arg
      end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-block-storage::identity_registration"
  end

  it "grants admin role to service user for service tenant" do
    block_storage_stubs
    ::Chef::Recipe.any_instance.stub(:openstack_identity_register)
    ::Chef::Recipe.any_instance.should_receive(:openstack_identity_register).
      with("Grant service Role to Cinder Service User for Cinder Service Tenant") do |&arg|
        @identity_register_mock.should_receive(:auth_uri).
          with "https://127.0.0.1:35357/v2.0"
        @identity_register_mock.should_receive(:bootstrap_token).
          with "bootstrap-token"
        @identity_register_mock.should_receive(:tenant_name).
          with "service"
        @identity_register_mock.should_receive(:user_name).
          with "cinder"
        @identity_register_mock.should_receive(:role_name).
          with "admin"
        @identity_register_mock.should_receive(:action).
          with :grant_role

        @identity_register_mock.instance_eval &arg
      end

    chef_run = ::ChefSpec::ChefRunner.new ::UBUNTU_OPTS
    chef_run.converge "openstack-block-storage::identity_registration"
  end
end
