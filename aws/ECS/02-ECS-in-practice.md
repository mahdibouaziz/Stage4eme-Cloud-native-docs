# IAM roles setup

- Create a role named `ecsInstanceRole` which will allow EC2 instances in an ECS cluster to access ECS.
  - When you create this role, choose `Elastic Container Service` -> `EC2 Role for ELactic Container Service`
- Create a role named `ecsRole` which will allow ECS to create and manage AWS resources on your behalf.
  - When you create this role, choose `Elastic Container Service` -> `Elastic Container Service`
- Create a role named `ecsTaskExecutionRole` which will allow ECS tasks to call AWS services on your behalf.
  - When you create this role, choose `Elastic Container Service` -> `Elastic Container Service Task`
- Create a role named `ecsAutoScalingRole` which will allow Auto Scaling to access and update ECS services.
  - When you create this role, choose `Elastic Container Service` -> `Elastic Container Service Autoscale`

# Networking Infra setup

- Create the Networking infrastructure
  - VPC
    - Create a VPC
      - **ecs-vpc** with CIDR=172.16.0.0/16, Enable DNS Support and Enable DNS Hostnames
  - Subnets
    - Create 2 subnets
      - **PublicSubnetOne** with CIDR 172.16.0.0/24 and MapPublicIpOnLaunch
      - **PublicSubnetTwo** with CIDR 172.16.1.0/24 and MapPublicIpOnLaunch
  - Internet Gateway
    - Create Internet Gateway **ecs-ig** and attach it to our VPC
  - Routing Table
    - Create a routing table in our VPC named **route-table-ecs-vpc**
    - Create a Routing rule which will allow all requests to go throuth the Internet Gateway (for internet access)
    - Associate the routing table with Subnet1 and Subnet2

# ECS Cluster Setup

- Create an ECS Cluster
  - CLuster Name: **ecs-cluster-test**
  - VPC: **ecs-vpc**
  - Select the needed subnets, in my case there are 2 subnets
  - Keep the default namespace as the cluster name
  - Select Amazon EC2 instances, and create your ASG
  - Add the needed tags and Create your cluster
