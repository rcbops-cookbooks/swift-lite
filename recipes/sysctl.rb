#
# Cookbook Name:: swift-lite
# Recipe:: sysctl
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

if node.recipe?("swift-lite::proxy-server")
  options = node["swift"]["services"]["proxy"]["sysctl"]

  sysctl_multi 'swift-proxy-server' do
    instructions options
  end
end

if node.recipe?("swift-lite::account-server")
  options = node["swift"]["services"]["account-server"]["sysctl"]

  sysctl_multi 'swift-account-server' do
    instructions options
  end
end

if node.recipe?("swift-lite::container-server")
  options = node["swift"]["services"]["container-server"]["sysctl"]

  sysctl_multi 'swift-container-server' do
    instructions options
  end
end

if node.recipe?("swift-lite::object-server")
  options = node["swift"]["services"]["object-server"]["sysctl"]

  sysctl_multi 'swift-object-server' do
    instructions options
  end
end
