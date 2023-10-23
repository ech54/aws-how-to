locals {
  env_config = yamldecode(file("./config.yaml"))[variable.env]
  config = merge(
    local.env_config
  )
  tags = merge(
    var.tags,
    local.env_config.tags
  )
}