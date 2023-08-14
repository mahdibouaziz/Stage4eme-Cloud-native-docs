#################### NETWORKING #####################

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

#################### ECR Repository #####################

resource "aws_ecr_repository" "aws-ecr" {
  name = "test-ecr"

  tags = {
    Name        = "test-ecr"
    Environment = "Test"
  }
}

#################### IAM Roles #####################

# IAM policy to enable the service to pull the image from ECR
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  # allow ECS tasks to call AWS services on your behalf
  name = "ecsTaskExecutionRole-test"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    Name = "test-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


#################### ECS Cluster #####################

# Create the ECS Cluster
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "test-cluster"
  tags = {
    Name        = "test-ecs"
    Environment = "test"
  }
}

# Log Group on CloudWatch to get the containers logs.
resource "aws_cloudwatch_log_group" "log-group" {
  name = "test-logs"

  tags = {
    Application = "test-ecs"
    Environment = "test"
  }
}

#################### Task Definition #####################

resource "aws_ecs_task_definition" "aws-ecs-task" {
  requires_compatibilities = ["FARGATE"]
  family                   = "test-task"

  container_definitions = jsonencode([
    {
      name      = "test"
      image     = "nginx"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log-group.id
          awslogs-region        = var.region
          awslogs-stream-prefix = "test-fargate"
        }
      }

    }
  ])

  network_mode       = "awsvpc"
  memory             = "512"
  cpu                = "256"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn      = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "test-ecs-td"
    Environment = "test"
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

#################### Application Load Balancer #####################

resource "aws_security_group" "alb_sg" {
  name        = "ALB SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = module.networking.vpc-id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_HTTP"
  }
}


resource "aws_lb" "application_load_balancer" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = module.networking.public-subnet-ids

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name        = "test-alb"
    Environment = "test"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.networking.vpc-id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "test-lb-tg"
    Environment = "test"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}


#################### ECS Service #####################

resource "aws_security_group" "application_sg" {
  name        = "Allow HTTP From ALB"
  description = "Allow HTTP inbound traffic from Application load balancer"
  vpc_id      = module.networking.vpc-id

  ingress {
    description     = "HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_HTTP"
  }
}

resource "aws_ecs_service" "aws-ecs-service" {
  name    = "test-ecs-service"
  cluster = aws_ecs_cluster.aws-ecs-cluster.id

  task_definition = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  desired_count   = 1

  launch_type = "FARGATE"

  scheduling_strategy = "REPLICA"

  force_new_deployment = true

  network_configuration {
    subnets          = module.networking.public-subnet-ids # TODO - Change this 
    assign_public_ip = true
    security_groups = [
      aws_security_group.application_sg.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "test"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.listener]
}

#################### Application Auto Scaling #####################

# Create an Autoscaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.aws-ecs-cluster.name}/${aws_ecs_service.aws-ecs-service.name}" # service/clusterName/serviceName
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "test-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "test-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}
