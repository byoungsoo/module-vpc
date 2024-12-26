
################################################################################
# Naming Rule - ${var.project_code}-${var.account}-${var.aws_region_code}-resource-{az}-{name}
################################################################################


################################################################################
# locals
################################################################################
locals {
  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc_ipv4_cidr_block_association.vpc_secondary_cidr_block[0].vpc_id, aws_vpc.vpc_main[0].id, "")
  create_vpc = var.create_vpc
}

// vpc
resource "aws_vpc" "vpc_main" { 
  cidr_block                        = var.vpc_cidr

  instance_tenancy                  = var.instance_tenancy
  enable_dns_support                = var.enable_dns_support 
  enable_dns_hostnames              = var.enable_dns_hostnames 
  
  tags = merge(
    { "Name" = var.vpc_name },
    var.all_tags,
    var.vpc_tags,
  )
  ## To-do for IPv6
  assign_generated_ipv6_cidr_block  = false 
  ## To-do for IPAM
}