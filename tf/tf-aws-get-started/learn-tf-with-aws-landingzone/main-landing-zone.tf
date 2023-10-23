
resource "aws_vpc" "current" {
  cidr_block           = local.config.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    { "Name" = var.name },
    local.tags,
  )
}

resource "aws_subnet" "private" {
  count = length(local.config.private_subnets)

 # availability_zone       = format("${var.aws_region.name}%s", element(local.config.private_subnets, count.index))
  cidr_block              = element(local.config.private_subnets, count.index)
  vpc_id                  = aws_vpc.current.id
  map_public_ip_on_launch = false

  tags = merge(
    local.tags,
  )
}
