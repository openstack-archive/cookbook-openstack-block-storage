openstack-block-storage Cookbook CHANGELOG
==============================
This file is used to list changes made in each version of the openstack-block-storage cookbook.

7.2.2
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
