################################################################################
# ALl Resource
################################################################################
variable "all_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "common_resource_name" {
  description = "Forward- {var.project_code}-{var.account}-{var.aws_region_code} // Added- resource-{az}-{name}"
  type        = string
  default     = ""
}


################################################################################
# VPC
################################################################################
variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = list(string)
  default     = []
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}


################################################################################
# Subnets
################################################################################
variable "public_subnet_cidr_blocks" {
    type = list(
      object({
        name       = string
        cidr_block = string
        az         = string
        })
    )
    default = []
    description = "Subnet has IGW routing rule for 0.0.0.0/0"
}

variable "private_subnet_cidr_blocks" {
    type = list(
      object({
        name       = string
        cidr_block = string
        az         = string
        })
    )
    default = []
    description = "Subnet has local routing rule and NAT gateway rule"
}

variable "prvonly_subnet_cidr_blocks" {
    type = list(
      object({
        name       = string
        cidr_block = string
        az         = string
        })
    )
    default = []
    description = "Subnet only has local routing rule"
}


################################################################################
# Gateway
################################################################################
variable "create_igw" {
  description = "Controls if IGW should be created (it affects almost all resources)"
  type        = bool
  default     = true
}
variable "igw_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "nat_gateway_subnet_name" {
  description = "Subnets that should be created NAT gateway"
  type        = string
  default     = "sbn-dmz"
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "natgw_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`"
  type        = bool
  default     = false
}

variable "reuse_nat_ips" {
  description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable"
  type        = bool
  default     = false
}

variable "external_nat_ip_ids" {
  description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
  type        = list(string)
  default     = []
}

variable "external_nat_ips" {
  description = "List of EIPs to be used for `nat_public_ips` output (used in combination with reuse_nat_ips and external_nat_ip_ids)"
  type        = list(string)
  default     = []
}

variable "nat_gateway_destination_cidr_block" {
  description = "Used to pass a custom destination route for private NAT Gateway. If not specified, the default 0.0.0.0/0 is used as a destination route"
  type        = string
  default     = "0.0.0.0/0"
}
