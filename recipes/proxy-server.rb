#
# Cookbook Name:: swift-lite
# Recipe:: proxy-server
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "swift-lite::common"
include_recipe "memcached-openstack"
include_recipe "osops-utils"

# find the node with the service password
swift_settings = node["swift"] unless get_settings_by_recipe("swift-lite::setup", "swift") != nil
platform_options = node["swift"]["platform"]

# install platform-specific packages
platform_options["proxy_packages"].each do |pkg|
  package pkg do
    action node["swift"]["package_action"].to_sym
    options platform_options["override_options"]
  end
end

package "python-swift-informant" do
  action node["swift"]["package_action"].to_sym
  options platform_options["override_options"]
  only_if { node["swift"]["use_informant"] }
end

package "python-keystone" do
  action node["swift"]["package_action"].to_sym
  options platform_options["override_options"]
end

directory "/var/cache/swift" do
  owner "swift"
  group "swift"
  mode 0600
end

swift_proxy_service = platform_options["service_prefix"] + "swift-proxy" + platform_options["service_suffix"]
service "swift-proxy" do
  # openstack-swift-proxy.service on fedora-17, swift-proxy on ubuntu
  service_name swift_proxy_service
  provider platform_options["service_provider"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
  only_if "[ -e /etc/swift/proxy-server.conf ] && [ -e /etc/swift/object.ring.gz ]"
end

# Find all our endpoint info
memcache_endpoints = get_realserver_endpoints(node["swift"]["memcache_role"], "memcached", "cache")

memcache_servers = memcache_endpoints.collect do |endpoint|
  "#{endpoint["host"]}:#{endpoint["port"]}"
end.join(",")


if swift_settings.has_key?("keystone_endpoint")
  keystone_auth_uri = swift_settings["keystone_endpoint"]
else
  ks_admin = get_access_endpoint("keystone-api", "keystone", "admin-api")
  keystone_auth_uri = ks_admin.uri
end

proxy_bind = get_bind_endpoint("swift", "proxy")
#proxy_access = get_access_endpoint("swift-lite-proxy", "swift", "proxy")

template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("bind_host" => proxy_bind["host"],
            "bind_port" => proxy_bind["port"],
            "keystone_auth_uri" => keystone_auth_uri,
            "service_tenant_name" => swift_settings["service_tenant_name"],
            "service_user" => swift_settings["service_user"],
            "service_pass" => swift_settings["service_pass"],
            "memcache_servers" => memcache_servers,
            "bind_host" => proxy_bind["host"],
            "bind_port" => proxy_bind["port"]
            )
  notifies :restart, "service[swift-proxy]", :immediately
end

dsh_group "swift-proxy-servers" do
  user node["swift"]["dsh"]["user"]
  network node["swift"]["dsh"]["network"]
end
