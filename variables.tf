## Projects
variable "region" {
  default = "eu-west-3"
}

variable "deployment_branch" {
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



