name "keystone-server"
run_list(
         "recipe[mysql-openstack::server]",
         "recipe[keystone::setup]",
         "recipe[keystone::keystone-api]"
)
