openstack-block-storage Cookbook CHANGELOG
==============================
This file is used to list changes made in each version of the openstack-block-storage cookbook.


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
