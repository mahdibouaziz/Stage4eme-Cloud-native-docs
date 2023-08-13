# Required
variable "vpc" {
  type = object({
    name                 = string
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
}

# Required
variable "public-subnets" {
  type = map(
    object({
      cidr_block              = string
      map_public_ip_on_launch = bool
    })
  )
}

# Required
variable "route-table-name" {
  type = string
}

# Optional - If ommitied it will not be created
variable "internet-gateway-name" {
  type = string
}
