# valid: :swauth or :keystone
default["swift"]["audit_hour"] = "5"                                        # cluster_attribute

default["swift"]["service_tenant_name"] = "service"                         # node_attribute
default["swift"]["service_user"] = "swift"                                  # node_attribute
default["swift"]["service_pass"] = nil

# Replacing with OpenSSL::Password in recipes/proxy-server.rb
default["swift"]["service_role"] = "admin"                                  # node_attribute

# should we install packages, or upgrade them?
default["swift"]["package_action"] = "install"

# ensure a uid on the swift user?
default["swift"]["uid"] = nil

# role to use to find memcache servers
default["swift"]["memcache_role"] = "swift-lite-proxy"

# swift dsh management
default["swift"]["dsh"]["user"]["name"] = "swiftops"
default["swift"]["dsh"]["admin_user"]["name"] = "swiftops"
default["swift"]["dsh"]["network"] = "swift-management"

# swift node tagging
default["swift"]["tags"]["management-server"] = "swift-management-server"
default["swift"]["tags"]["proxy-server"] = "swift-proxy-server"
default["swift"]["tags"]["account-server"] = "swift-account-server"
default["swift"]["tags"]["container-server"] = "swift-countainer-server"
default["swift"]["tags"]["object-server"] = "swift-object-server"

# swift ntp
default["swift"]["ntp"]["servers"] = []
default["swift"]["ntp"]["network"] = "swift-management"

# proxy service tuning
#
# This takes proxy-server.conf settings in hashified format.  Please
# see the sample proxy-server.conf files distributed by the swift-proxy
# or the openstack documentation for more information on possible settings
#
default["swift"]["proxy"]["config"]["DEFAULT"]["workers"] = [node["cpu"]["total"] - 1, 1].max

# account service tuning
#
# Like the proxy config blocks, this can be modified in direct hashified format.
#
default["swift"]["account"]["config"]["DEFAULT"]["workers"] = 6

# container service tuning
default["swift"]["container"]["config"]["DEFAULT"]["workers"] = 6

# object service tuning
default["swift"]["object"]["config"]["DEFAULT"]["workers"] = 8


# keystone information
default["swift"]["region"] = "RegionOne"
default["swift"]["keystone_endpoint"] = "http://127.0.0.1/"

default["swift"]["services"]["proxy"]["scheme"] = "http"                    # node_attribute
default["swift"]["services"]["proxy"]["network"] = "swift-proxy"           # node_attribute (inherited from cluster?)
default["swift"]["services"]["proxy"]["port"] = 8080                        # node_attribute (inherited from cluster?)
default["swift"]["services"]["proxy"]["path"] = "/v1/AUTH_%(tenant_id)s"                       # node_attribute


default["swift"]["services"]["object-server"]["network"] = "swift-storage"          # node_attribute (inherited from cluster?)
default["swift"]["services"]["object-server"]["port"] = 6000                # node_attribute (inherited from cluster?)


default["swift"]["services"]["container-server"]["network"] = "swift-storage"       # node_attribute (inherited from cluster?)
default["swift"]["services"]["container-server"]["port"] = 6001             # node_attribute (inherited from cluster?)


default["swift"]["services"]["account-server"]["network"] = "swift-storage"         # node_attribute (inherited from cluster?)
default["swift"]["services"]["account-server"]["port"] = 6002               # node_attribute (inherited from cluster?)

default["swift"]["services"]["ring-repo"]["network"] = "swift-storage"              # node_attribute (inherited from cluster?)

# Leveling between distros
case platform
when "redhat"
  default["swift"]["platform"] = {                      # node_attribute
    "disk_format" => "ext4",
    "proxy_packages" => ["openstack-swift-proxy", "python-memcached"],
    "object_packages" => ["openstack-swift-object", "sudo"],
    "container_packages" => ["openstack-swift-container"],
    "account_packages" => ["openstack-swift-account"],
    "swift_packages" => ["openstack-swift", "sudo", "cronie"],
    "rsync_packages" => ["rsync"],
    "service_prefix" => "openstack-",
    "service_suffix" => "",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Redhat,
    "override_options" => ""
  }
#
# python-iso8601 is a missing dependency for swift.
# https://bugzilla.redhat.com/show_bug.cgi?id=875948
when "centos"
  default["swift"]["platform"] = {                      # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["openstack-swift-proxy", "python-memcached" ],
    "object_packages" => ["openstack-swift-object"],
    "container_packages" => ["openstack-swift-container"],
    "account_packages" => ["openstack-swift-account"],
    "swift_packages" => ["openstack-swift", "sudo", "cronie", "python-iso8601"],
    "rsync_packages" => ["rsync"],
    "service_prefix" => "openstack-",
    "service_suffix" => "",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Redhat,
    "override_options" => ""
  }
when "fedora"
  default["swift"]["platform"] = {                                          # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["openstack-swift-proxy", "python-memcached"],
    "object_packages" => ["openstack-swift-object"],
    "container_packages" => ["openstack-swift-container"],
    "account_packages" => ["openstack-swift-account"],
    "swift_packages" => ["openstack-swift"],
    "rsync_packages" => ["rsync"],
    "service_prefix" => "openstack-",
    "service_suffix" => ".service",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Systemd,
    "override_options" => ""
  }
when "ubuntu"
  default["swift"]["platform"] = {                                          # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["swift-proxy", "python-memcache"],
    "object_packages" => ["swift-object"],
    "container_packages" => ["swift-container"],
    "account_packages" => ["swift-account", "python-swiftclient"],
    "swift_packages" => ["swift"],
    "rsync_packages" => ["rsync"],
    "service_prefix" => "",
    "service_suffix" => "",
    "git_dir" => "/var/cache/git",
    "git_service" => "git-daemon",
    "service_provider" => Chef::Provider::Service::Upstart,
    "override_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
