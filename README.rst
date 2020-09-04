OpenStack Chef Cookbook - block-storage
=======================================

.. image:: https://governance.openstack.org/tc/badges/cookbook-openstack-block-storage.svg
    :target: https://governance.openstack.org/reference/tags/index.html

Description
===========

Installs the OpenStack Block Storage service **Cinder** as part of the
OpenStack reference deployment Chef for OpenStack. The `OpenStack
chef-repo`_ contains documentation for using this cookbook in the
context of a full OpenStack deployment. Cinder is currently installed
from packages.

.. _OpenStack chef-repo: https://opendev.org/openstack/openstack-chef

https://docs.openstack.org/cinder/latest/

Requirements
============

- Chef 15 or higher
- Chef Workstation 20.8.111 for testing (also includes berkshelf for
  cookbook dependency resolution)

Platform
========

-  ubuntu
-  redhat
-  centos

Cookbooks
=========

The following cookbooks are dependencies:

- 'apache2', '~> 8.0'
- 'lvm'
- 'openstackclient'
- 'openstack-common', '>= 19.0.0'
- 'openstack-identity', '>= 19.0.0'
- 'openstack-image', '>= 19.0.0'

Attributes
==========

Please see the extensive inline documentation in ``attributes/*.rb`` for
descriptions of all the settable attributes for this cookbook.

Note that all attributes are in the ``default['openstack']`` "namespace"

The usage of attributes to generate the ``cinder.conf`` is described in the
openstack-common cookbook.

Recipes
=======

openstack-block-storage::api
----------------------------

-  Installs the cinder-api and sets up the cinder database

openstack-block-storage::backup
-------------------------------

-  Installs the cinder-backup service

openstack-block-storage::cinder-common
--------------------------------------

-  Defines the common pieces of repeated code from the other recipes

openstack-block-storage::identity_registration
-----------------------------------------------

-  Defines the cinder service/user/endpoints in keystone

openstack-block-storage::scheduler
----------------------------------

-  Installs the cinder-scheduler service

openstack-block-storage::volume_driver_lvm
--------------------------------------------

-  Configures lvm as the cinder storage backend

openstack-block-storage::volume
-------------------------------

-  Installs the cinder-volume service

License and Author
==================

+-----------------+---------------------------------------------------+
| **Author**      | Justin Shepherd (justin.shepherd@rackspace.com)   |
+-----------------+---------------------------------------------------+
| **Author**      | Jason Cannavale (jason.cannavale@rackspace.com)   |
+-----------------+---------------------------------------------------+
| **Author**      | Ron Pedde (ron.pedde@rackspace.com)               |
+-----------------+---------------------------------------------------+
| **Author**      | Joseph Breu (joseph.breu@rackspace.com)           |
+-----------------+---------------------------------------------------+
| **Author**      | William Kelly (william.kelly@rackspace.com)       |
+-----------------+---------------------------------------------------+
| **Author**      | Darren Birkett (darren.birkett@rackspace.co.uk)   |
+-----------------+---------------------------------------------------+
| **Author**      | Evan Callicoat (evan.callicoat@rackspace.com)     |
+-----------------+---------------------------------------------------+
| **Author**      | Matt Ray (matt@opscode.com)                       |
+-----------------+---------------------------------------------------+
| **Author**      | Jay Pipes (jaypipes@att.com)                      |
+-----------------+---------------------------------------------------+
| **Author**      | John Dewey (jdewey@att.com)                       |
+-----------------+---------------------------------------------------+
| **Author**      | Abel Lopez (al592b@att.com)                       |
+-----------------+---------------------------------------------------+
| **Author**      | Sean Gallagher (sean.gallagher@att.com)           |
+-----------------+---------------------------------------------------+
| **Author**      | Ionut Artarisi (iartarisi@suse.cz)                |
+-----------------+---------------------------------------------------+
| **Author**      | David Geng (gengjh@cn.ibm.com)                    |
+-----------------+---------------------------------------------------+
| **Author**      | Salman Baset (sabaset@us.ibm.com)                 |
+-----------------+---------------------------------------------------+
| **Author**      | Chen Zhiwei (zhiwchen@cn.ibm.com)                 |
+-----------------+---------------------------------------------------+
| **Author**      | Mark Vanderwiel (vanderwl@us.ibm.com)             |
+-----------------+---------------------------------------------------+
| **Author**      | Eric Zhou (zyouzhou@cn.ibm.com)                   |
+-----------------+---------------------------------------------------+
| **Author**      | Edwin Wang (edwin.wang@cn.ibm.com)                |
+-----------------+---------------------------------------------------+
| **Author**      | Jan Klare (j.klare@cloudbau.de)                   |
+-----------------+---------------------------------------------------+
| **Author**      | Christoph Albers (c.albers@x-ion.de)              |
+-----------------+---------------------------------------------------+
| **Author**      | Lance Albertson (lance@osuosl.org)                |
+-----------------+---------------------------------------------------+

+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2012, Rackspace US, Inc.            |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2012-2013, AT&T Services, Inc.      |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2013, Opscode, Inc.                 |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2013-2014, SUSE Linux GmbH          |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2013-2015, IBM, Corp.               |
+-----------------+---------------------------------------------------+
| **Copyright**   | Copyright (c) 2019-2020, Oregon State University  |
+-----------------+---------------------------------------------------+

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

::

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
