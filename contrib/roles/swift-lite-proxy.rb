name "swift-lite-proxy"
description "swift proxy server"
run_list(
    "recipe[swift-lite::proxy-server]",
)
