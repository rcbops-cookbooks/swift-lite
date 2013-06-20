name "swift-lite-setup"
description "sets up swift keystone passwords/users"
run_list(
    "recipe[swift-lite::setup]"
)
