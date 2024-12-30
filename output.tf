################################################################################
# VPC
################################################################################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(aws_vpc.vpc_main[0].id, null)
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = try(aws_vpc.vpc_main[0].arn, null)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(aws_vpc.vpc_main[0].cidr_block, null)
}

################################################################################
# Publiс Subnets
################################################################################
output "public_subnet_objects" {
  description = "A list of all public subnets, containing the full objects."
  value       = aws_subnet.public_subnets
}

output "public_subnet_name" {
  description = "A list of all public subnets, containing the full objects."
  value       =[for subnet in aws_subnet.public_subnets : subnet.tags.Name]
}

output "private_subnet_objects" {
  description = "A list of all public subnets, containing the full objects."
  value       = aws_subnet.public_subnets
}

output "private_subnet_name" {
  description = "A list of all public subnets, containing the full objects."
  value       =[for subnet in aws_subnet.private_subnets : subnet.tags.Name]
}

output "nat_subnet_azs" {
  description = "A list of all nat subnet azs."
  value       = local.nat_subnet_azs
}

output "public_subnet_ids" {
  description = "A list of all public subnets ids."
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "A list of all public subnets ids."
  value       = local.private_subnet_ids
}

output "prvonly_subnet_ids" {
  description = "A list of all public subnets ids."
  value       = local.prvonly_subnet_ids
}


# output "other_pub_subnet_id" {
#     value = { for subnet_id, subnet in aws_subnet.other_subnets : subnet_id => subnet.id }
# }

# output "private_subnet_id" {
#     value = { for subnet_id, subnet in aws_subnet.other_subnets : subnet_id => subnet.id }
# }

# output "private_subnet_id" {
#     value = { for subnet_id, subnet in aws_subnet.other_subnets : subnet_id => subnet.id }
# }