default['openstack']['block-storage']['conf_secrets'] = {}
default['openstack']['block-storage']['conf'].tap do |conf|
  conf['DEFAULT']['notification_driver'] = 'cinder.openstack.common.notifier.rpc_notifier'
  if node['openstack']['block-storage']['syslog']['use']
    conf['DEFAULT']['log_config'] = '/etc/openstack/logging.conf'
  end
  conf['DEFAULT']['rpc_backend'] = node['openstack']['mq']['service_type']
  conf['DEFAULT']['my_ip'] = '127.0.0.1'
  conf['DEFAULT']['auth_strategy'] = 'keystone'
  conf['DEFAULT']['control_exchange'] = 'cinder'
  conf['DEFAULT']['volume_group'] = 'cinder-volumes'
  conf['DEFAULT']['state_path'] = '/var/lib/cinder'
  conf['keystone_authtoken']['auth_plugin'] = 'v2password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'cinder'
  conf['keystone_authtoken']['tenant_name'] = 'service'
  conf['keystone_authtoken']['signing_dir'] = '/var/cache/cinder/api'
  conf['oslo_concurrency']['lock_path'] = '/var/lib/cinder/tmp'
end
