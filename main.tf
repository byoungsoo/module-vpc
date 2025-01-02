
################################################################################
# Naming Rule - ${var.project_code}-${var.account}-${var.aws_region_code}-resource-{az}-{name}
################################################################################


################################################################################
# VPC
################################################################################
locals {
  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc_ipv4_cidr_block_association.vpc_secondary_cidr_block[0].vpc_id, aws_vpc.vpc_main[0].id, "")
  create_vpc = var.create_vpc
}

// vpc
resource "aws_vpc" "vpc_main" { 
  count = local.create_vpc ? 1 : 0
  cidr_block                        = var.vpc_cidr
  instance_tenancy                  = var.instance_tenancy
  enable_dns_support                = var.enable_dns_support 
  enable_dns_hostnames              = var.enable_dns_hostnames 
  
  tags = merge(
    { "Name" = "${var.common_resource_name}-vpc-${var.vpc_name}" },
    var.all_tags,
    var.vpc_tags
  )
  ## To-do for IPv6
  assign_generated_ipv6_cidr_block  = false 
  ## To-do for IPAM
}

resource "aws_vpc_ipv4_cidr_block_association" "vpc_secondary_cidr_block" {
  count = local.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  # Do not turn this into `local.vpc_id`
  vpc_id = aws_vpc.vpc_main[0].id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

################################################################################
# Subnet
################################################################################
locals {
  nat_subnets = [for subnet in aws_subnet.public_subnets : subnet.id if strcontains(subnet.tags.Name, var.nat_gateway_subnet_name)]
  nat_subnet_azs = [for subnet in aws_subnet.public_subnets : split("-", subnet.availability_zone_id)[1] if strcontains(subnet.tags.Name, var.nat_gateway_subnet_name)]
  public_subnet_ids = [for subnet in aws_subnet.public_subnets : subnet.id]
  private_subnet_ids = [for subnet in aws_subnet.private_subnets : subnet.id]
  prvonly_subnet_ids = [for subnet in aws_subnet.prvonly_subnets : subnet.id]
}
resource "aws_subnet" "public_subnets" {
  for_each = { for subnet in var.public_subnet_cidr_blocks : "${subnet.name}-${split("-",subnet.az)[2]}" => subnet }
  # sbn-dmz-az1 => {name="sbn-dmz-az1", cidr_block="10.5.1.0/24", az="us-east-1a"},
  vpc_id                    = aws_vpc.vpc_main[0].id

  cidr_block                = each.value.cidr_block
  availability_zone         = each.value.az
  map_public_ip_on_launch   = true
  tags = merge(
    { "Name" =  "${var.common_resource_name}-sbn-${split("-",each.value.az)[2]}-${each.value.name}"},
    var.all_tags
  )
}

resource "aws_subnet" "private_subnets" {
    for_each = { for subnet in var.private_subnet_cidr_blocks : "${subnet.name}-${split("-",subnet.az)[2]}" => subnet }
  # sbn-dmz-az1 => {name="sbn-dmz-az1", cidr_block="10.5.1.0/24", az="us-east-1a"},
  vpc_id                    = aws_vpc.vpc_main[0].id

  cidr_block                = each.value.cidr_block
  availability_zone         = each.value.az
  map_public_ip_on_launch   = false
  tags = merge(
    { "Name" =  "${var.common_resource_name}-sbn-${split("-",each.value.az)[2]}-${each.value.name}"},
    var.all_tags,
    (each.value.name == var.karpenter_subnet_name ? var.karpenter_tag : {})
  )
}

resource "aws_subnet" "prvonly_subnets" {
    for_each = { for subnet in var.prvonly_subnet_cidr_blocks : "${subnet.name}-${split("-",subnet.az)[2]}" => subnet }
  # sbn-dmz-az1 => {name="sbn-dmz-az1", cidr_block="10.5.1.0/24", az="us-east-1a"},
  vpc_id                    = aws_vpc.vpc_main[0].id

  cidr_block                = each.value.cidr_block
  availability_zone         = each.value.az
  map_public_ip_on_launch   = false
  tags = merge(
    { "Name" =  "${var.common_resource_name}-sbn-${split("-",each.value.az)[2]}-${each.value.name}"},
    var.all_tags
  )
}

################################################################################
# Gateway
################################################################################
locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(local.nat_subnet_azs) : 1
  nat_gateway_ips   = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat_eip[*].id
}

resource "aws_internet_gateway" "igw" {
  count = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.vpc_main[0].id
  tags = merge(
    { "Name" = "${var.common_resource_name}-igw-${var.igw_name}" },
    var.all_tags
  )
}
resource "aws_eip" "nat_eip" {
  count = local.create_vpc && var.enable_nat_gateway && !var.reuse_nat_ips ? local.nat_gateway_count : 0

  domain = "vpc"
  tags = merge(
    {
      "Name" = format(
        "${var.common_resource_name}-eip-natgw-%s",
        element(local.nat_subnet_azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.all_tags,
  )

  depends_on = [aws_internet_gateway.igw[0]]
}

// NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  
  allocation_id = element(local.nat_gateway_ips, var.single_nat_gateway ? 0 : count.index)
  subnet_id = element(local.nat_subnets[*], var.single_nat_gateway ? 0 : count.index)

  tags = merge(
    {
      Name = format(
        "${var.common_resource_name}-natgw-%s",
        element(local.nat_subnet_azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.all_tags
  )

  depends_on = [aws_internet_gateway.igw[0]]
}


# ################################################################################
# # Routing rule
# ################################################################################
resource "aws_route_table" "rt_table_pub" {
  vpc_id = aws_vpc.vpc_main[0].id
  
  tags = merge(
    { "Name" = "${var.common_resource_name}-rtb-pub" },
    var.all_tags,
  )
}
# There are as many routing tables as the number of NAT gateways
resource "aws_route_table" "rt_table_prv" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  vpc_id = aws_vpc.vpc_main[0].id
  tags = merge(
    {
      "Name" = var.single_nat_gateway ? "${var.common_resource_name}-rtb-prv" : format(
        "${var.common_resource_name}-rtb-%s-prv",
        element(local.nat_subnet_azs, count.index),
      )
    },
    var.all_tags
  )
}
resource "aws_route_table" "rt_table_prv_only" {
  vpc_id = aws_vpc.vpc_main[0].id
tags = merge(
    { "Name" = "${var.common_resource_name}-rtb-prvonly" },
    var.all_tags,
  )
}

resource "aws_route" "rt_rule_pub" {
  route_table_id = aws_route_table.rt_table_pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw[0].id
}

resource "aws_route" "rt_rule_prv" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0
  route_table_id         = element(aws_route_table.rt_table_prv[*].id, count.index)
  destination_cidr_block = var.nat_gateway_destination_cidr_block
  nat_gateway_id         = element(aws_nat_gateway.nat_gateway[*].id, count.index)
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "rt_rule_pub" {
  count = length(local.public_subnet_ids)
  subnet_id      = element(local.public_subnet_ids, count.index)
  route_table_id = aws_route_table.rt_table_pub.id
}

resource "aws_route_table_association" "rt_rule_prv" {
  count = length(local.private_subnet_ids)
  subnet_id = element(local.private_subnet_ids, count.index)
  route_table_id = element(
    aws_route_table.rt_table_prv[*].id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route_table_association" "rt_rule_prvonly" {
  count = length(local.prvonly_subnet_ids)
  subnet_id = element(local.prvonly_subnet_ids, count.index)
  route_table_id = aws_route_table.rt_table_prv_only.id
}
