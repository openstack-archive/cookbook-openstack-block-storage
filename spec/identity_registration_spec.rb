# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::identity_registration' do
  before do
    block_storage_stubs
    @chef_run = ::ChefSpec::Runner.new ::UBUNTU_OPTS do |n|
      # TODO: Remove work around once https://github.com/customink/fauxhai/pull/77 merges
      n.set['cpu']['total'] = 1
    end
    @chef_run.converge 'openstack-block-storage::identity_registration'
  end

  it 'registers cinder volume service' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Cinder Volume Service'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      service_name: 'cinder',
      service_type: 'volume',
      service_description: 'Cinder Volume Service',
      endpoint_region: 'RegionOne',
      endpoint_adminurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      endpoint_internalurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      endpoint_publicurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      action: [:create_service]
    )
  end

  it 'registers cinder volume endpoint' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Cinder Volume Endpoint'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      service_name: 'cinder',
      service_type: 'volume',
      service_description: 'Cinder Volume Service',
      endpoint_region: 'RegionOne',
      endpoint_adminurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      endpoint_internalurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      endpoint_publicurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
      action: [:create_endpoint]
    )
  end

  it 'registers service user' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Register Cinder Service User'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      tenant_name: 'service',
      user_name: 'cinder',
      user_pass: 'cinder-pass',
      user_enabled: true,
      action: [:create_user]
    )
  end

  it 'grants admin role to service user for service tenant' do
    resource = @chef_run.find_resource(
      'openstack-identity_register',
      'Grant service Role to Cinder Service User for Cinder Service Tenant'
    ).to_hash

    expect(resource).to include(
      auth_uri: 'http://127.0.0.1:35357/v2.0',
      bootstrap_token: 'bootstrap-token',
      tenant_name: 'service',
      user_name: 'cinder',
      role_name: 'admin',
      action: [:grant_role]
    )
  end
end
