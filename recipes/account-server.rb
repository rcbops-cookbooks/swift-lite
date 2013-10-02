#
# Cookbook Name:: swift
# Recipe:: account-server
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

tag node["swift"]["tags"]["account-server"]

include_recipe "swift-lite::common"
include_recipe "swift-lite::storage-common"

platform_options = node["swift"]["platform"]

platform_options["account_packages"].each.each do |pkg|
  package pkg do
    action node["swift"]["package_action"].to_sym
    options platform_options["override_options"] # retain configs
  end
end

# epel/f-17 missing init scripts for the non-major services.
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor reaper replicator}.each do |svc|
  template "/etc/systemd/system/openstack-swift-account-#{svc}.service" do
    owner "root"
    group "root"
    mode "0644"
    source "simple-systemd-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Account #{svc.capitalize}",
                :user => "swift",
                :exec => "/usr/bin/swift-account-#{svc} " +
                "/etc/swift/account-server.conf"
              })
    only_if { platform?(%w{fedora}) }
  end
end

# TODO(breu): track against upstream epel packages to determine if this
# is still necessary
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor reaper replicator}.each do |svc|
  template "/etc/init.d/openstack-swift-account-#{svc}" do
    owner "root"
    group "root"
    mode "0755"
    source "simple-redhat-init-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Account #{svc.capitalize}",
                :user => "swift",
                :exec => "account-#{svc}"
              })
    only_if { platform?(%w{redhat centos}) }
  end
end

%w{swift-account swift-account-auditor swift-account-reaper swift-account-replicator}.each do |svc|
  service_name = platform_options["service_prefix"] + svc + platform_options["service_suffix"]
  service svc do
    service_name service_name
    provider platform_options["service_provider"]
    supports :status => true, :restart => true
    action [:enable, :start]
    only_if "[ -e /etc/swift/account-server.conf ] && [ -e /etc/swift/account.ring.gz ]"
  end
end

account_endpoint = get_bind_endpoint("swift","account-server")

# For more configurable options and information please check either
# account-server.conf manpage or account-server.conf-sample provided
# within the distributed package
default_options = {
  "DEFAULT" => {
    "bind_ip" => "0.0.0.0",
    "bind_port" => 6002,
    "workers" => 6,
    "user" => "swift",
    "swift_dir" => "/etc/swift",
    "devices" => "/srv/node",
    "db_preallocation" => "off"
  },
  "pipeline:main" => {
    "pipeline" => "healthcheck recon account-server"
  },
  "app:account-server" => {
    "use" => "egg:swift#account",
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
  "account-replicator" => {
    "log_facility" => "LOG_LOCAL2",
    "per_diff" => 10000,
    "concurrency" => 4,
  },
  "account-auditor" => {
    "log_facility" => "LOG_LOCAL2",
    "interval" => 1800
  },
  "account-reaper" => {
    "log_facility" => "LOG_LOCAL2",
    "concurrency" => 2,
    "delay_reaping" => 604800
  }
}

template "/etc/swift/account-server.conf" do
  source "inifile.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("config_options" => default_options.merge(
      node["swift"]["account"]["config"] || {}) { |k, x, y| x.merge(y) }
  )

  notifies :restart, "service[swift-account]", :immediately
  notifies :restart, "service[swift-account-auditor]", :immediately
  notifies :restart, "service[swift-account-reaper]", :immediately
  notifies :restart, "service[swift-account-replicator]", :immediately
end

dsh_group "swift-account-servers" do
  user node["swift"]["dsh"]["user"]
  network node["swift"]["dsh"]["network"]
end
