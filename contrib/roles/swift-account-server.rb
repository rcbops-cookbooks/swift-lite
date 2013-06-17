name "swift-account-server"
description "swift account server"
run_list(
    "recipe[swift-lite::account-server]",
)
