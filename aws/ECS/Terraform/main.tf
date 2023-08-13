# VPC
resource "aws_vpc" "aws_ecs" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-vpc"
  }
}


# Public Subnets

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet_one" {
  vpc_id                  = aws_vpc.aws_ecs.id
  cidr_block              = "172.16.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "public-subnet-one"
  }
}

resource "aws_subnet" "public_subnet_two" {
  vpc_id                  = aws_vpc.aws_ecs.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "public-subnet-two"
  }
}

# Internete Gateway
resource "aws_internet_gateway" "ecs_ig" {
  vpc_id = aws_vpc.aws_ecs.id

  tags = {
    Name = "ecs-ig"
  }
}

# Routing Table
resource "aws_route_table" "route_table_ecs_vpc" {
  vpc_id = aws_vpc.aws_ecs.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_ig.id
  }

  tags = {
    Name = "route-table-ecs-vpc"
  }
}

resource "aws_route_table_association" "subnet_one_association" {
  subnet_id      = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.route_table_ecs_vpc.id
}

resource "aws_route_table_association" "subnet_two_association" {
  subnet_id      = aws_subnet.public_subnet_two.id
  route_table_id = aws_route_table.route_table_ecs_vpc.id
}

