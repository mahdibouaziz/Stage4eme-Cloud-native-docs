output "vpc-id" {
  value = aws_vpc.aws_ecs.id
}

output "public-subnet-ids" {
  value = [for val in aws_subnet.public_subnets : val.id]
}