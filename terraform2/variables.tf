variable "region" {
  type        = string
  description = "AWS region"
}

variable "image_uri" {
  type        = string
  description = "ECR image URI"
}

variable "app_keys" {
  type        = string
  description = "Application keys for Strapi"
  sensitive   = true
}

variable "api_token_salt" {
  type        = string
  description = "API token salt for Strapi"
  sensitive   = true
}

variable "admin_jwt_secret" {
  type        = string
  description = "Admin JWT secret for Strapi"
  sensitive   = true
}

variable "transfer_token_salt" {
  type        = string
  description = "Transfer token salt for Strapi"
  sensitive   = true
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret for Strapi"
  sensitive   = true
}
