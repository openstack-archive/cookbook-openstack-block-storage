# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'registers service tenant' do
      expect(chef_run).to create_tenant_openstack_identity_register(
        'Register Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        tenant_description: 'Service Tenant'
      )
    end

    it 'registers cinder v2 volume service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register Cinder V2 Volume Service'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'cinderv2',
        service_type: 'volumev2',
        service_description: 'Cinder Volume Service V2',
        endpoint_region: 'RegionOne',
        endpoint_adminurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
        endpoint_internalurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
        endpoint_publicurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s'
      )
    end

    context 'registers v2 volume endpoint' do
      it 'with default values' do
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinderv2',
          service_type: 'volumev2',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
          endpoint_internalurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
          endpoint_publicurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s'
        )
      end

      it 'with different admin URL' do
        admin_url = 'https://admin.host:123/admin_path'
        general_url = 'http://general.host:456/general_path'

        # Set the general endpoint
        node.set['openstack']['endpoints']['block-storage-api']['uri'] = general_url
        # Set the admin endpoint override
        node.set['openstack']['endpoints']['admin']['block-storage-api']['uri'] = admin_url

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinderv2',
          service_type: 'volumev2',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: admin_url,
          endpoint_internalurl: general_url,
          endpoint_publicurl: general_url
        )
      end

      it 'with different public URL' do
        public_url = 'https://public.host:789/public_path'
        general_url = 'http://general.host:456/general_path'

        # Set the general endpoint
        node.set['openstack']['endpoints']['block-storage-api']['uri'] = general_url
        # Set the public endpoint override
        node.set['openstack']['endpoints']['public']['block-storage-api']['uri'] = public_url

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinderv2',
          service_type: 'volumev2',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: general_url,
          endpoint_internalurl: general_url,
          endpoint_publicurl: public_url
        )
      end

      it 'with different internal URL' do
        internal_url = 'http://internal.host:456/internal_path'
        general_url = 'http://general.host:456/general_path'

        # Set the general endpoint
        node.set['openstack']['endpoints']['block-storage-api']['uri'] = general_url
        # Set the internal endpoint override
        node.set['openstack']['endpoints']['internal']['block-storage-api']['uri'] = internal_url

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinderv2',
          service_type: 'volumev2',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: general_url,
          endpoint_internalurl: internal_url,
          endpoint_publicurl: general_url
        )
      end

      it 'with all different URLs' do
        admin_url = 'https://admin.host:123/admin_path'
        internal_url = 'http://internal.host:456/internal_path'
        public_url = 'https://public.host:789/public_path'

        node.set['openstack']['endpoints']['internal']['block-storage-api']['uri'] = internal_url
        node.set['openstack']['endpoints']['admin']['block-storage-api']['uri'] = admin_url
        node.set['openstack']['endpoints']['public']['block-storage-api']['uri'] = public_url

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinderv2',
          service_type: 'volumev2',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: admin_url,
          endpoint_internalurl: internal_url,
          endpoint_publicurl: public_url
        )
      end

      it 'with different service type/name' do
        node.set['openstack']['block-storage']['service_name'] = 'cinder'
        node.set['openstack']['block-storage']['service_type'] = 'volume'

        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinder',
          service_type: 'volume',
          service_description: 'Cinder Volume Service V2',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
          endpoint_internalurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s',
          endpoint_publicurl: 'http://127.0.0.1:8776/v2/%(tenant_id)s'
        )
      end

      it 'with custom region override' do
        node.set['openstack']['block-storage']['region'] = 'volumeRegion'
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder V2 Volume Endpoint'
        ).with(endpoint_region: 'volumeRegion')
      end
    end

    it 'registers service user' do
      expect(chef_run).to create_user_openstack_identity_register(
        'Register Cinder Service User'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'cinder',
        user_pass: 'cinder-pass',
        user_enabled: true
      )
    end

    it 'grants service role to service user for service tenant' do
      expect(chef_run).to grant_role_openstack_identity_register(
        'Grant service Role to Cinder Service User for Cinder Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'cinder',
        role_name: 'service'
      )
    end
  end
end
