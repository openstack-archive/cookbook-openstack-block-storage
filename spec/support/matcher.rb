# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

def upgrade_python_pip(pkgname)
  ChefSpec::Matchers::ResourceMatcher.new(:python_pip, :upgrade, pkgname)
end
