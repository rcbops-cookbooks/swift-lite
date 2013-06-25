Support
=======

Issues have been disabled for this repository.
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[swift-lite]: \<short description of problem\>

In the issue description, please include a longer description of the
issue, along with any relevant log/command/error output.  If logfiles
are extremely long, please place the relevant portion into the issue
description, and link to a gist containing the entire logfile

Description
===========

Installs packages and configuration for OpenStack Swift

Requirements
============

Client:
 * CentOS >= 6.3
 * Ubuntu >= 12.04

Chef:
 * 0.10.8

Other variants of Ubuntu and Fedora may work, something crazy like
Solaris probably will not.  YMMV, objects in mirror, etc.

This differs from the rcbops OpenStack Swift cookbooks in that it
tries to do much less with the swift cluster.  Specifically:

 * It does not do swath auth.  It just does keystone.

 * It does not do ring management, or set up a repo for storing rings in.

 * It does not do drive detection, formatting, mounting or unmounting

Generally this means that it does not do things that could potentially
cause cluster data loss, preferring to leave that to experienced
system administrators.

Attributes
==========

 * node[:swift][:swift_hash] - swift_hash_path_suffix in /etc/swift/swift.conf

 * node[:swift][:audit_hour] - Hour to run swift_auditor on storage nodes (default 5)

 * node["swift"]["uid"] - uid of swift user (will be created before installing packages)

The following values can override values from search.  If deploying
keystone using the rcbops cookbooks, these need not be set, as they
will be determined from the keystone configuration.

 * node[:keystone][:admin_port]

 * node[:keystone][:admin_token]

 * node[:keystone][:admin_user]

In addition, there are some attributes used by osops-utils to find
interfaces on particular devices.

 * node[:osops_networks][:swift_storage] - CIDR of the storage network (what
   address to bind storage nodes to, primarily.

 * node[:osops_network][:swift_replication] - CIDR of the replication
   network.  This could be the same CIDR as the swift network.

 * node[:osops_networks][:swift_proxy] - CIDR of the network that that
   the proxy listens on.

If installing more than one swift proxy (which is likely), you will
need to set the proxy vip which will get published in keystone.  This
attribute is:

 * node["vips"]["swift-proxy"]: "http(s?)://x.x.x.x:port"

It is your responsibility to ensure it is ssl terminated (as
appropriate to your environment).  I might suggest ZXTM or new
HA-proxy with ssl, or HA-proxy with stud.

Packages can be force upgraded using the following key:

 * node["swift"]["package_action"] = "upgrade"

Deps
====

 * dsh
 * keystone
 * openssl
 * osops-utils
 * sysctl

Roles
=====

 * swift-account-server - storage node for account data
 * swift-container-server - storage node for container data
 * swift-object-server - storage node for object server
 * swift-proxy-server - proxy for swift storge nodes

In small environments, it is likely that all storage machines will
have all these roles, with a load balancer ahead of it.

In larger environments, where it is cost effective to split the proxy
and storage layer, storage nodes will carry
swift-{account,container,object}-server roles, and there will be
dedicated hosts with the swift-proxy-server role.

In really really huge environments, it's possible that the storage
node will be split into swift-{container,account}-server nodes and
swift-object-server nodes.

Examples
========

Example environment:


    {
        "override_attributes": {
            "swift": {
                "swift_hash": "107c0568ea84",
            },
            "osops_networks": {
                "swift_storage": "192.168.122.0/24",
                "swift_replication": "192.168.122.0/24",
                "swift_proxy": "all"
            }
        },
        "cookbook_versions": {
        },
        "description": "",
        "default_attributes": {
        },
        "name": "swift",
        "chef_type": "environment",
        "json_class": "Chef::Environment"
    }

This sets up defaults for a swauth-based cluster with the storage
network on 192.168.122.0/24, replicating on same, and proxy listening
on all available interfaces.

More complete examples are in contrib/environment


Run list for proxy server:

    "run_list": [
        "role[swift-setup]",
        "role[swift-proxy-server]"
    ]

Run list for combined object, container, and account server:

    "run_list": [
        "role[swift-object-server]",
        "role[swift-account-server]",
        "role[swift-container-server]"
    ]

This obviously depends on a previously deployed keystone server using
the rcbops cookbooks.  Consult the keystone README.md for details on
deploying keystone with that cookbook.

This also wants relatively new swift.  You can use the newest
backported versions of swift by adding recipe[osops-utils::packages],
or by adding a package repo to point to newer swift before running any
of the proxy or server recipes.

The names of the roles are important, and example roles (which can be
extened) are in contrib/roles.


License and Author
==================

Author:: Ron Pedde (<ron.pedde@rackspace.com>)
Author:: Will Kelly (<will.kelly@rackspace.com>)

Copyright:: 2012, 2013 Rackspace US, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
