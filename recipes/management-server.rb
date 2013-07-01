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

%w{ proxy account container object }.each do |type|
  dsh_group "swift-#{type}-servers" do
    admin_user node["swift"]["dsh"]["admin_user"]
    network node["swift"]["dsh"]["network"]
  end
end
