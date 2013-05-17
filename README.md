Description
===========

Installs the OpenStack Block Storage service **Cinder** as part of the OpenStack reference deployment Chef for OpenStack. The http://github.com/mattray/chef-openstack-repo contains documentation for using this cookbook in the context of a full OpenStack deployment. Cinder is currently installed from packages.

http://cinder.openstack.org

Requirements
============

* Chef 0.10.0 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* database
* glance
* keystone
* mysql
* openssh
* openstack-common
* rabbitmq
* selinux (Fedora)

Usage
=====

api
----
- Installs the cinder-api, sets up the cinder database,
 and cinder service/user/endpoints in keystone

db
--
- Creates the Cinder database

scheduler
----
- Installs the cinder-scheduler service

volume
----
- Installs the cinder-volume service and sets up the iscsi helper

Defaults to the ISCSI (LVM) Driver.

Attributes
==========

* `cinder["db"]["username"]` - cinder username for database
* `cinder["rabbit"]["username"]` - Username for cinder rabbit access
* `cinder["rabbit"]["vhost"]` - The rabbit vhost to use
* `cinder["service_tenant_name"]` - name of tenant to use for the cinder service account in keystone
* `cinder["service_user"]` - cinder service user in keystone
* `cinder["service_role"]` - role for the cinder service user in keystone
* `cinder["syslog"]["use"]`
* `cinder["syslog"]["facility"]`
* `cinder["syslog"]["config_facility"]`
* `cinder["platform"]` - hash of platform specific package/service names and options
* `cinder["volume"]["state_path"]` - Top-level directory for maintaining cinder's state
* `cinder["volume"]["volume_driver"]` - Driver to use for volume creation
* `cinder["volume"]["volume_group"]` - Name for the VG that will contain exported volumes
* `cinder["volume"]["iscsi_helper"]` - ISCSI target user-land tool to use
* `cinder["rbd_pool"]` - RADOS Block Device pool to use
* `cinder["rbd_user"]` - User for Cephx Authentication
* `cinder["rbd_secret_uuid"]` - Secret UUID for Cephx Authentication
* `cinder["policy"]["context_is_admin"]` - Define administrators
* `cinder["policy"]["default"]` - default volume operations rule
* `cinder["policy"]["admin_or_owner"]` - Define an admin or owner
* `cinder["policy"]["admin_api"]` - Define api admin

Testing
=====

This cookbook is using [ChefSpec](https://github.com/acrmp/chefspec) for
testing. Run the following before commiting. It will run your tests,
and check for lint errors.

    $ ./run_tests.bash

License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Justin Shepherd (<justin.shepherd@rackspace.com>) |
| **Author**           |  Jason Cannavale (<jason.cannavale@rackspace.com>) |
| **Author**           |  Ron Pedde (<ron.pedde@rackspace.com>)             |
| **Author**           |  Joseph Breu (<joseph.breu@rackspace.com>)         |
| **Author**           |  William Kelly (<william.kelly@rackspace.com>)     |
| **Author**           |  Darren Birkett (<darren.birkett@rackspace.co.uk>) |
| **Author**           |  Evan Callicoat (<evan.callicoat@rackspace.com>)   |
| **Author**           |  Matt Ray (<matt@opscode.com>)                     |
| **Author**           |  Jay Pipes (<jaypipes@att.com>)                    |
| **Author**           |  John Dewey (<jdewey@att.com>)                     |
| **Author**           |  Abel Lopez (<al592b@att.com>)                     |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2012, Rackspace US, Inc.            |
| **Copyright**        |  Copyright (c) 2012-2013, AT&T Services, Inc.      |
| **Copyright**        |  Copyright (c) 2013, Opscode, Inc.                 |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
