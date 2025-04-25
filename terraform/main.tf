provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "strapi_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create Security Group for EC2 instance
resource "aws_security_group" "strapi_sg" {
  name        = "strapi.app.gbkgg"
  description = "Security group for Strapi EC2 instance"
  vpc_id      = aws_vpc.strapi_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Subnet
resource "aws_subnet" "strapi_subnet" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# EC2 instance
resource "aws_instance" "strapi_instance" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.strapi_subnet.id
  vpc_security_group_ids      = [aws_security_group.strapi_sg.id]
  associate_public_ip_address = true
  key_name                    = "bharath"

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "StrapiInstance_GBGB"
  }
}

# Image tag variable
variable "image_tag" {
  description = "The tag of the Docker image to be deployed"
  type        = string
}

# User data script with dynamic image tag
data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    image_tag = var.image_tag
  }
}

# Output EC2 public IP
output "ec2_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}
