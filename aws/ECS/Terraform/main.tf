# VPC
resource "aws_vpc" "aws_ecs" {
  cidr_block           = var.networking.vpc.cidr_block
  enable_dns_hostnames = var.networking.vpc.enable_dns_hostnames
  enable_dns_support   = var.networking.vpc.enable_dns_support

  tags = {
    Name = var.networking.vpc.name
  }
}

# Public Subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  for_each = var.networking.public-subnets

  vpc_id                  = aws_vpc.aws_ecs.id
  cidr_block              = each.value["cidr_block"]
  map_public_ip_on_launch = each.value["map_public_ip_on_launch"]

  tags = {
    Name = each.key
  }
}


# Internete Gateway
resource "aws_internet_gateway" "ecs_ig" {
  # Create an Internet Gateway only if the key "internet-gateway-name" exists
  count = lookup(var.networking, "internet-gateway-name", null) == null ? 0 : 1

  vpc_id = aws_vpc.aws_ecs.id

  tags = {
    Name = var.networking.internet-gateway-name
  }
}

# Routing Table
# Create Route to the Internet Gateway only if the key "internet-gateway-name" exists
locals {
  route = lookup(var.networking, "internet-gateway-name", null) == null ? [] : [{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_ig[0].id
  }]
}

resource "aws_route_table" "route_table_ecs_vpc" {
  vpc_id = aws_vpc.aws_ecs.id

  # Create the Route to the Internet gateway if we have an internet gateway
  dynamic "route" {
    for_each = local.route
    content {
      cidr_block = route.value["cidr_block"]
      gateway_id = route.value["gateway_id"]
    }
  }

  tags = {
    Name = var.networking.route-table-name
  } 

}

resource "aws_route_table_association" "public_subnets_association" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table_ecs_vpc.id
}
