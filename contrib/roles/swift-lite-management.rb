name "swift-lite-management"
description "swift management server"
run_list(
    "recipe[swift-lite::management-server]"
)
