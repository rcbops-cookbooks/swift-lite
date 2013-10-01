#
# Cookbook Name:: swift
# Recipe:: swift-container-server
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
#

include_recipe "swift-lite::common"
include_recipe "swift-lite::storage-common"


platform_options = node["swift"]["platform"]

platform_options["container_packages"].each do |pkg|
  package pkg do
    action node["swift"]["package_action"].to_sym
    options platform_options["override_options"]
  end
end

# epel/f-17 missing init scripts for the non-major services.
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor updater replicator}.each do |svc|
  template "/etc/systemd/system/openstack-swift-container-#{svc}.service" do
    owner "root"
    group "root"
    mode "0644"
    source "simple-systemd-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Container #{svc.capitalize}",
                :user => "swift",
                :exec => "/usr/bin/swift-container-#{svc} " +
                "/etc/swift/container-server.conf"
              })
    only_if { platform?(%w{fedora}) }
  end
end

# TODO(breu): track against upstream epel packages to determine if this
# is still necessary
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor updater replicator}.each do |svc|
  template "/etc/init.d/openstack-swift-container-#{svc}" do
    owner "root"
    group "root"
    mode "0755"
    source "simple-redhat-init-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Container #{svc.capitalize}",
                :user => "swift",
                :exec => "container-#{svc}"
              })
    only_if { platform?(%w{redhat centos}) }
  end
end

%w{swift-container swift-container-auditor swift-container-replicator swift-container-updater}.each do |svc|
  service_name=platform_options["service_prefix"] + svc + platform_options["service_suffix"]

  service svc do
    service_name service_name
    provider platform_options["service_provider"]
    supports :status => true, :restart => true
    action [:enable, :start]
    only_if "[ -e /etc/swift/container-server.conf ] && [ -e /etc/swift/container.ring.gz ]"
  end
end

container_endpoint = get_bind_endpoint("swift", "container-server")

# For more configurable options and information please check either
# account-server.conf manpage or account-server.conf-sample provided
# within the distributed package
default_options = {
  "DEFAULT" => {
    "bind_ip" => "0.0.0.0",
    "bind_port" => "6001",
    "workers" => "6",
    "user" => "swift",
    "swift_dir" => "/etc/swift",
    "devices" => "/srv/node",
    "db_preallocation" => "off"
  },
  "pipeline:main" => {
    "pipeline" => "healthcheck recon container-server"
  },
  "app:container-server" => {
    "use" => "egg:swift#container",
    "log_facility" => "LOG_LOCAL1"
  },
  "filter:healthcheck" => {
    "use" => "egg:swift#healthcheck"
  },
  "filter:recon" => {
    "use" => "egg:swift#recon",
    "log_facility" => "LOG_LOCAL2",
    "recon_cache_path" => "/var/cache/swift",
    "recon_lock_path" => "/var/lock/swift"
  },
  "container-replicator" => {
    "log_facility" => "LOG_LOCAL2",
    "concurrency" => 6
  },
  "container-updater" => {
    "log_facility" => "LOG_LOCAL2",
    "concurrency" => "4",
    "node_timeout" => "15",
    "conn_timeout" => "5"
  },
  "container-auditor" => {
    "log_facility" => "LOG_LOCAL2",
    "interval" => 1800
  },
  "container-sync" => {
  }
}

template "/etc/swift/container-server.conf" do
  source "inifile.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("config_options" => default_options.merge(
      node["swift"]["container"]["config"] || {}) { |k, x, y| x.merge(y) }
  )

  notifies :restart, "service[swift-container]", :immediately
  notifies :restart, "service[swift-container-replicator]", :immediately
  notifies :restart, "service[swift-container-updater]", :immediately
  notifies :restart, "service[swift-container-auditor]", :immediately
end

dsh_group "swift-container-servers" do
  user node["swift"]["dsh"]["user"]
  network node["swift"]["dsh"]["network"]
end

tag node["swift"]["tags"]["container-server"]
