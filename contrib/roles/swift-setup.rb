name "swift-setup"
description "sets up swift keystone passwords/users"
run_list(
    "recipe[swift-lite::setup]"
)
