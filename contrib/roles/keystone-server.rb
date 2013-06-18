name "keystone-server"
run_list(
         "role[mysql-master]",
         "recipe[keystone::setup]",
         "recipe[keystone::keystone-api]"
)
