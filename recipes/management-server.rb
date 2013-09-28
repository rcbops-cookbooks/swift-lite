#
# Cookbook Name:: swift-lite
# Recipe:: management-server
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

storage = %w{ swift-account-servers swift-container-servers swift-object-servers }
everyone = Array.new(storage).push("swift-proxy-servers")

everyone.each do |group|
  dsh_group group do
    admin_user node["swift"]["dsh"]["admin_user"]
    network node["swift"]["dsh"]["network"]
  end
end

execute "swift-storage-dsh-group" do
  username = node["swift"]["dsh"]["admin_user"]["name"]

  cwd "/home/#{username}/.dsh/group"
  command "cat #{storage.join(' ')} | sort | uniq > swift-storage"
  user username
  group username
end

execute "swift-dsh-group" do
  username = node["swift"]["dsh"]["admin_user"]["name"]

  cwd "/home/#{username}/.dsh/group"
  command "cat #{everyone.join(' ')} | sort | uniq > swift"
  user username
  group username
end

tag node["swift"]["tags"]["management-server"]
