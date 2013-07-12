name "swift-lite-account"
description "swift account server"
run_list(
    "recipe[swift-lite::account-server]",
)
