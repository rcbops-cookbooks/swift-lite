name "swift-lite-ntp"
description "swift ntp server"
run_list(
    "recipe[swift-lite::ntp]"
)
