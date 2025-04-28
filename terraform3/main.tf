provider "aws" {
   region = "us-east-1"
 }
 
 resource "aws_vpc" "main" {
   cidr_block           = "10.0.0.0/16"
   enable_dns_support   = true
   enable_dns_hostnames = true
 
   tags = {
     Name = "strapi-vpc"
   }
 }
 
 resource "aws_internet_gateway" "gw" {
   vpc_id = aws_vpc.main.id
 
   tags = {
     Name = "strapi-gw"
   }
 }
 
 resource "aws_subnet" "public_a" {
   vpc_id                  = aws_vpc.main.id
   cidr_block              = "10.0.1.0/24"
   availability_zone       = "us-east-1a"
   map_public_ip_on_launch = true
 
   tags = {
     Name = "public-subnet-a"
   }
 }
 
 resource "aws_subnet" "public_b" {
   vpc_id                  = aws_vpc.main.id
   cidr_block              = "10.0.2.0/24"
   availability_zone       = "us-east-1b"
   map_public_ip_on_launch = true
 
   tags = {
     Name = "public-subnet-b"
   }
 }
 
 resource "aws_route_table" "public" {
   vpc_id = aws_vpc.main.id
 
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.gw.id
   }
 
   tags = {
     Name = "public-rt"
   }
 }
 
 resource "aws_route_table_association" "a" {
   subnet_id      = aws_subnet.public_a.id
   route_table_id = aws_route_table.public.id
 }
 
 resource "aws_route_table_association" "b" {
   subnet_id      = aws_subnet.public_b.id
   route_table_id = aws_route_table.public.id
 }
 
 resource "aws_security_group" "strapi_sg" {
   name        = "strapi-sg"
   description = "Allow HTTP and ECS traffic"
 @@ -102,7 +35,7 @@ resource "aws_lb_target_group" "strapi" {
   port        = 80
   protocol    = "HTTP"
   vpc_id      = aws_vpc.main.id
   target_type = "ip" # <-- IMPORTANT FIX
   target_type = "ip"
 
   health_check {
     path                = "/"
 @@ -125,26 +58,24 @@ resource "aws_lb_listener" "front_end" {
   }
 }
 
 resource "aws_ecs_cluster" "strapi" {
   name = "strapi-cluster"
 }
 
 resource "aws_cloudwatch_log_group" "strapi" {
   name = "/ecs/strapi"
 }
 
 resource "aws_ecs_task_definition" "strapi" {
   family                   = "strapi-task"
   network_mode             = "awsvpc"
   requires_compatibilities = ["FARGATE"]
   cpu                      = "256"
   memory                   = "512"
   execution_role_arn       = "arn:aws:iam::118273046134:role/ecsTaskExecutionRole1"
   
 
   container_definitions = jsonencode([{
     name      = "strapi"
     image     = "strapi/strapi"
     essential = true
     environment = [
       {
         name  = "PORT"
         value = "80"  # Ensuring Strapi listens on port 80 inside the container
       }
     ]
     portMappings = [{
       containerPort = 80
       hostPort      = 80
