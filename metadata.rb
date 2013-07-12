name              "swift-lite"
maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Install and configure Openstack Swift with less crazy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.16"
recipe            "swift-lite::account-server", "Installs the swift account server"
recipe            "swift-lite::object-server", "Installs the swift object server"
recipe            "swift-lite::proxy-server", "Installs the swift proxy server"
recipe            "swift-lite::container-server", "Installs the swift container server"
recipe            "swift-lite::management-server", "Installs the swift management server"
recipe            "swift-lite::ntp-server", "Installs the ntp server for the swift cluster"
recipe            "swift-lite::ntp", "Configures ntp on the nodes to use the cluster ntp server"

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ dsh openssl osops-utils sysctl memcached-openstack ntp }.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.20"
