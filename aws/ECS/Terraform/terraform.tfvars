#################### GLOBAL #####################

region = "us-west-1"

#################### NETWORKING #####################

networking = {
  vpc = {
    name                 = "ecs-vpc"
    cidr_block           = "172.16.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
  }

  public-subnets = {
    public-subnet-one = {
      cidr_block              = "172.16.0.0/24"
      map_public_ip_on_launch = true
    }
    public-subnet-two = {
      cidr_block              = "172.16.1.0/24"
      map_public_ip_on_launch = true
    }
  }

  route-table-name = "route-table-ecs-vpc"

  # This is optional, is it is set, it will create an Internet Gateway
  # and then add this Internet Gateway to the Table route
  internet-gateway-name = "ecs-ig"

}
