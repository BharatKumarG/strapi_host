# provider configuration
provider "aws" {
  region = "us-east-1"
}

# Declare region as a variable
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Declare the Strapi image as a variable
variable "strapi_image" {
  default = "118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:latest"
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 7
}

# Create VPC for Strapi
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "strapi-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "strapi-public-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "strapi-gateway"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "strapi-public-rt"
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group for Strapi
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow 1337 and HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-sg"
  }
}

# ECS Cluster for Strapi
resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
  task_role_arn            = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"

  container_definitions = jsonencode([{
    name      = "strapi",
    image     = var.strapi_image,
    portMappings = [{
      containerPort = 1337,
      protocol      = "tcp"
    }],
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = "/ecs/strapi",
        awslogs-region        = var.region,
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# ECS Service for Strapi
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.strapi_sg.id]
    assign_public_ip = true
  }
}

# Output the Strapi URL
output "strapi_url" {
  value = "http://${aws_ecs_service.strapi.name}.ecs.${var.region}.amazonaws.com:1337"
}
