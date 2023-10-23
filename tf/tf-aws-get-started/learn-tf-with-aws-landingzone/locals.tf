locals {
  env_config = yamldecode(file("./config.yaml"))[var.env]
  config = merge(
    local.env_config
  )
  tags = merge(
    var.tags,
    local.env_config.tags
  )
}