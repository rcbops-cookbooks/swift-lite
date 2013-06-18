name "mysql-master"
description "Installs mysql and sets up replication (if 2 nodes with role)"
run_list(
  "recipe[mysql-openstack::server]"
)
