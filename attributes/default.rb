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
    "proxy_packages" => ["openstack-swift-proxy", "sudo", "cronie", "python-memcached"],
    "object_packages" => ["openstack-swift-object", "sudo", "cronie"],
    "container_packages" => ["openstack-swift-container", "sudo", "cronie"],
    "account_packages" => ["openstack-swift-account", "sudo", "cronie"],
    "swift_packages" => ["openstack-swift", "sudo", "cronie"],
    "swauth_packages" => ["openstack-swauth", "sudo", "cronie"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["xinetd", "git", "git-daemon"],
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
    "proxy_packages" => ["openstack-swift-proxy", "sudo", "cronie", "python-iso8601", "python-memcached" ],
    "object_packages" => ["openstack-swift-object", "sudo", "cronie", "python-iso8601" ],
    "container_packages" => ["openstack-swift-container", "sudo", "cronie", "python-iso8601" ],
    "account_packages" => ["openstack-swift-account", "sudo", "cronie", "python-iso8601" ],
    "swift_packages" => ["openstack-swift", "sudo", "cronie", "python-iso8601" ],
    "swauth_packages" => ["openstack-swauth", "sudo", "cronie", "python-iso8601" ],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["xinetd", "git", "git-daemon"],
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
    "swauth_packages" => ["openstack-swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git", "git-daemon"],
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
    "swauth_packages" => ["swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git-daemon-sysvinit"],
    "service_prefix" => "",
    "service_suffix" => "",
    "git_dir" => "/var/cache/git",
    "git_service" => "git-daemon",
    "service_provider" => Chef::Provider::Service::Upstart,
    "override_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
