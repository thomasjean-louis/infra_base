## Projects
variable "region" {
  default = "eu-west-3"
}

variable "app_name" {
  type      = string
  sensitive = true
}

variable "deployment_branch" {
  type      = string
  sensitive = true
}

variable "git_branch" {
  default = "default"
}

variable "admin_mail" {
  type      = string
  sensitive = true
}

variable "send_mail" {
  type      = string
  sensitive = true
}

## Route 53

variable "hosted_zone_name" {
  type      = string
  sensitive = true
}

## ECR
variable "game_server_name_image" {
  type      = string
  sensitive = true
}

variable "proxy_name_image" {
  type      = string
  sensitive = true
}

## Github

variable "token_github" {
  type      = string
  sensitive = true
}

# Website

variable "website_name" {
  type      = string
  sensitive = true
}

###### Cognito
variable "subdomain_auth" {
  type      = string
  sensitive = true
}

variable "admin_cognito_username" {
  type      = string
  sensitive = true
}

variable "admin_cognito_password" {
  type      = string
  sensitive = true
}

variable "classic_cognito_username" {
  type      = string
  sensitive = true
}

variable "classic_cognito_password" {
  type      = string
  sensitive = true
}

variable "default_cognito_mail" {
  type      = string
  sensitive = true
}

variable "admin_group_name" {
  default = "admin"
}

variable "user_group_name" {
  default = "user"
}

# Cloudfront
variable "cloudfront_function_arn" {
  type      = string
  sensitive = true
}

# DynamoDB
variable "game_monitoring_table_name" {
  default = "gamemonitoring"
}

variable "game_monitoring_id_column_name" {
  default = "ID"
}


