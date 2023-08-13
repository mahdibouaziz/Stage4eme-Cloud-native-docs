module "networking" {
  source = "./modules/networking"

  vpc = {
    name                 = var.networking.vpc.name
    cidr_block           = var.networking.vpc.cidr_block
    enable_dns_hostnames = var.networking.vpc.enable_dns_hostnames
    enable_dns_support   = var.networking.vpc.enable_dns_support
  }

  public-subnets = { for key, val in var.networking.public-subnets : key => val }

  route-table-name = var.networking.route-table-name

  internet-gateway-name = lookup(var.networking, "internet-gateway-name", null)

}

output "vpc-id" {
  value = module.networking.vpc-id
}

output "subnet-ids" {
  value = module.networking.public-subnet-ids
}