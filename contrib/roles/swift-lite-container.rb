name "swift-lite-container"
description "swift container server"
run_list(
    "recipe[swift-lite::container-server]",
)
