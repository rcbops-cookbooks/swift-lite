name "swift-lite-object"
description "swift object server"
run_list(
    "recipe[swift-lite::object-server]",
)
