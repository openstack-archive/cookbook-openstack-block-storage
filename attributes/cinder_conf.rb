default['openstack']['block-storage']['conf_secrets'] = {}
default['openstack']['block-storage']['conf'].tap do |conf|
  conf['oslo_messaging_notifications']['driver'] = 'cinder.openstack.common.notifier.rpc_notifier'
  if node['openstack']['block-storage']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end
  conf['DEFAULT']['auth_strategy'] = 'keystone'
  conf['DEFAULT']['control_exchange'] = 'cinder'
  conf['DEFAULT']['glance_api_version'] = '2'
  conf['DEFAULT']['volume_group'] = 'cinder-volumes'
  conf['DEFAULT']['state_path'] = '/var/lib/cinder'
  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'cinder'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'

  conf['oslo_concurrency']['lock_path'] = '/var/lib/cinder/tmp'
end
