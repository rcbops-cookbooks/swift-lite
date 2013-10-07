#
# Cookbook Name:: swift
# Recipe:: swift-common
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
include_recipe "osops-utils"

platform_options = node["swift"]["platform"]

platform_options["swift_packages"].each do |pkg|
  package pkg do
    action node["swift"]["package_action"].to_sym
    options platform_options["override_options"]
  end
end

# Configure uid if we've specifid one and make sure the user has a shell for dsh
user "swift" do
  if node["swift"].has_key?("uid")
    uid node["swift"]["uid"]
  end
  shell "/bin/bash"
  action :modify
end

directory "/etc/swift" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  only_if "/usr/bin/id swift"
end

template "/etc/swift/swift.conf" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  variables("hash_path_suffix" => node["swift"]["swift_hash_suffix"],
            "hash_path_prefix" => node["swift"]["swift_hash_prefix"])
  only_if "/usr/bin/id swift"
end

template "/etc/sudoers.d/swift" do
  owner "root"
  group "root"
  mode "0440"
  variables(
    :node => node
  )
  action :nothing
end

template "swift-management-sudoers" do
  path "/etc/sudoers.d/swift-management"
  source "sudo/swift-management.erb"
  owner "root"
  group "root"
  mode "0440"
  variables(
    :user => node["swift"]["dsh"]["user"]["name"]
  )
end
