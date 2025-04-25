#!/bin/bash

# Update and install required packages
yum update -y
yum install -y docker jq awscli
service docker start
usermod -a -G docker ec2-user

# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 118273046134.dkr.ecr.us-east-1.amazonaws.com

# Get the latest image tag from ECR
latest_tag=$(aws ecr describe-images \
  --repository-name gbk-strapi-app \
  --region us-east-1 \
  --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
  --output text)

# Pull the image with the latest tag
docker pull 118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:new-tag

# Run the container
docker run -d -p 1337:1337 118273046134.dkr.ecr.us-east-1.amazonaws.com/gbk-strapi-app:new-tag
