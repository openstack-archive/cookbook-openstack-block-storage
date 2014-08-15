openstack-block-storage Cookbook CHANGELOG
==============================
This file is used to list changes made in each version of the openstack-block-storage cookbook.

## 10.0.0
* Upgrading to Juno
* Sync conf files with Juno
* Upgrading berkshelf from 2.0.18 to 3.1.5

## 9.4.1
* Add support for LVMISCSIDriver driver using block devices with LVM

## 9.4.0
* python_packages database client attributes have been migrated to
the -common cookbook
* bump berkshelf to 2.0.18 to allow Supermarket support
* added rootwrap.conf as a template
* fix fauxhai version for suse and redhat

## 9.3.0
### Blue print
* Add multiple backend configuration support

## 9.2.3
* Fix for storwize_svc_vol_rsize default

## 9.2.2
### Bug
* Add support for miscellaneous options (like in Compute)

## 9.2.1
### Bug
* Remove output of extra config lines in cinder.conf.erb

## 9.2.0
### Blue print
* Get VMware vCenter password from databag

## 9.1.1
* Fix package action to allow updates

## 9.1.0
### Blue print
* Remove policy template

## 9.0.1
### Bug
* Fix the depends cookbook version issue in metadata.rb

## 9.0.0
* Upgrade to Icehouse

## 8.4.1
### Bug
* Fix the DB2 ODBC driver issue
* Move control_exchange outside of 'rabbit'

## 8.4.0
### Blue print
* Use the library method auth_uri_transform

## 8.3.0
* Rename openstack-metering to openstack-telemetry

## 8.2.0
* VMware VMDK driver support

## 8.1.0
* Add client recipe

## 8.0.0
### New version
* Upgrade to upstream Havana release
* Add support for Storwize/SVC configuration attributes

## 7.2.2
### Bug
* fix a bug related to qpid.

## 7.2.1
### Bug
* relax the dependencies to the 7.x series

## 7.2.0
### Improvement
* Add qpid support for cinder. Default is rabbitmq

## 7.1.0
### Improvement
* Add new attributes for common rpc configuration

## 7.0.6
### Bug
* set auth_uri for authtoken in api-paste.ini (bug #1207504)

## 7.0.4
### Improvement
* Use a default log-file (/var/log/cinder/cinder.log) if syslog is disabled

## 7.0.3
### Bug
* change audit cronjob binary path depending on platform, refactored some tests

## 7.0.2
### Improvement
* ensure cronjob runs on only one node and make cronjob configurable

## 7.0.1
### Improvement
* Add audit cronjob and enable control_exchange, when metering enabled
