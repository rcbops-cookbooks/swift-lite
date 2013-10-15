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

tag node["swift"]["tags"]["proxy-server"]

include_recipe "swift-lite::common"
include_recipe "memcached-openstack"
include_recipe "osops-utils"

# fix memcache
resources("service[memcached]").action :enable

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

service "enable-swift-proxy" do
  service_name swift_proxy_service
  provider platform_options["service_provider"]
  supports :status => true, :restart => true
  action :enable
end

service "swift-proxy" do
  # openstack-swift-proxy.service on fedora-17, swift-proxy on ubuntu
  service_name swift_proxy_service
  provider platform_options["service_provider"]
  supports :status => true, :restart => true
  action :start
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
  ks_admin = get_access_endpoint(node["keystone"]["api_role"], "keystone", "admin-api")
  keystone_auth_uri = ks_admin.uri
end

keystone_uri = URI(keystone_auth_uri)
proxy_bind = get_bind_endpoint("swift", "proxy")

#proxy_access = get_access_endpoint("swift-lite-proxy", "swift", "proxy")

# For more configurable options and information please check either
# proxy-server.conf manpage or proxy-server.conf-sample provided
# within the distributed package
default_options = {
  "DEFAULT" => {
    "bind_ip" => "0.0.0.0",
    "bind_port" => "8080",
    "backlog" => "4096",
    "workers" => 12
  },
  "pipeline:main" => {
    "pipeline" => "catch_errors proxy-logging healthcheck cache ratelimit authtoken keystoneauth proxy-logging proxy-server"
  },
  "app:proxy-server" => {
    "use" => "egg:swift#proxy",
    "log_facility" => "LOG_LOCAL0",
    "node_timeout" => "60",
    "client_timeout" => "60",
    "conn_timeout" => "3.5",
    "allow_account_management" => "false",
    "account_autocreate" => "true"
  },
  "filter:authtoken" => {
    "paste.filter_factory" => "keystoneclient.middleware.auth_token:filter_factory",
    "delay_auth_decision" => "1",
    "auth_host" => keystone_uri.host,
    "auth_port" => keystone_uri.port,
    "auth_protocol" => keystone_uri.scheme,
    "admin_tenant_name" => swift_settings["service_tenant_name"],
    "admin_user" => swift_settings["service_user"],
    "admin_password" => swift_settings["service_pass"],
    "signing_dir" => "/var/cache/swift",
    "cache" => "swift.cache",
    "token_cache_time" => 86100
  },
  "filter:keystoneauth" => {
    "use" => "egg:swift#keystoneauth",
    "operator_roles" => "admin, swiftoperator",
    "reseller_admin_role" => "reseller_admin"
  },
  "filter:healthcheck" => {
    "use" => "egg:swift#healthcheck"
  },
  "filter:cache" => {
    "use" => "egg:swift#memcache",
    "memcache_serialization_support" => "2",
    "memcache_servers" => memcache_servers
  },
  "filter:ratelimit" => {
    "use" => "egg:swift#ratelimit"
  },
  "filter:domain_remap" => {
    "use" => "egg:swift#domain_remap"
  },
  "filter:catch_errors" => {
    "use" => "egg:swift#catch_errors"
  },
  "filter:cname_lookup" => {
    "use" => "egg:swift#cname_lookup"
  },
  "filter:staticweb" => {
    "use" => "egg:swift#staticweb"
  },
  "filter:tempurl" => {
    "use" => "egg:swift#tempurl"
  },
  "filter:formpost" => {
    "use" => "egg:swift#tempurl"
  },
  "filter:name_check" => {
    "use" => "egg:swift#name_check"
  },
  "filter:list-endpoints" => {
    "use" => "egg:swift#list_endpoints"
  },
  "filter:proxy-logging" => {
    "use" => "egg:swift#proxy_logging"
  },
  "filter:bulk" => {
    "use" => "egg:swift#bulk"
  },
  "filter:container-quotas" => {
    "use" => "egg:swift#container_quotas"
  },
  "filter:slo" => {
    "use" => "egg:swift#slo"
  },
  "filter:account-quotas" => {
    "use" => "egg:swift#account_quotas"
  }
}

template "/etc/swift/proxy-server.conf" do
  source "inifile.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("config_options" => default_options.merge(
      node["swift"]["account"]["config"] || {}) { |k, x, y| x.merge(y) })

  notifies :restart, "service[swift-proxy]", :immediately
end

dsh_group "swift-proxy-servers" do
  user node["swift"]["dsh"]["user"]
  network node["swift"]["dsh"]["network"]
end

# epel: no thanks. this is on the management node so nuke it
file "/etc/swift/object-expirer.conf" do
  action :delete
  only_if { node.platform_family?("rhel") }
end

execute "chkconfig --del openstack-swift-object-expirer" do
  action :run
  only_if { node.platform_family?("rhel") }
end
