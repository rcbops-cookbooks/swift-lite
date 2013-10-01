#
# Cookbook Name:: swift-lite
# Recipe:: ntp
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

# if someone doesn't set these explicitly, let's find the ntp server
if node["swift"]["ntp"]["servers"].empty?
  tag = node["swift"]["tags"]["management-server"]
  network = node["swift"]["ntp"]["network"]

  my_ip = get_ip_for_net(network, node)

  node.default["swift"]["ntp"]["servers"] =
    Chef::Recipe::IPManagement.get_ips_for_tag(tag, network, node) - [my_ip]
end

node.default["ntp"]["servers"] = node["swift"]["ntp"]["servers"]

include_recipe "ntp::default"
