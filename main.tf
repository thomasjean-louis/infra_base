## Project config 
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

## Global variables
data "aws_caller_identity" "account_data" {}

data "aws_route53_zone" "project_route_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

locals {
  account_id     = data.aws_caller_identity.account_data.account_id
  hosted_zone_id = data.aws_route53_zone.project_route_zone.zone_id
}

## Modules
module "ecr" {
  source                 = "./ecr"
  game_server_name_image = var.game_server_name_image
  proxy_name_image       = var.proxy_name_image
  account_id             = local.account_id
  region                 = var.region
  deployment_branch      = var.deployment_branch
}

module "iam" {
  source            = "./iam"
  account_id        = local.account_id
  deployment_branch = var.deployment_branch
}

module "r53" {
  source           = "./r53"
  hosted_zone_name = var.hosted_zone_name
}

module "lambda" {
  source            = "./lambda"
  region            = var.region
  account_id        = local.account_id
  app_name          = var.app_name
  deployment_branch = var.deployment_branch
  token_github      = var.token_github
  hosted_zone_id    = local.hosted_zone_id
  hosted_zone_name  = var.hosted_zone_name
}

module "website" {
  source                  = "./website"
  region                  = var.region
  website_name            = var.website_name
  deployment_branch       = var.deployment_branch
  hosted_zone_id          = local.hosted_zone_id
  hosted_zone_name        = var.hosted_zone_name
  cloudfront_function_arn = var.cloudfront_function_arn
}

# Cognito
module "cognito" {
  source                   = "./cognito"
  region                   = var.region
  app_name                 = var.app_name
  admin_cognito_username   = var.admin_cognito_username
  admin_cognito_password   = var.admin_cognito_password
  classic_cognito_username = var.classic_cognito_username
  classic_cognito_password = var.classic_cognito_password

  hosted_zone_id       = local.hosted_zone_id
  subdomain_auth       = var.subdomain_auth
  hosted_zone_name     = var.hosted_zone_name
  default_cognito_mail = var.default_cognito_mail
  deployment_branch    = var.deployment_branch
  admin_group_name     = var.admin_group_name
  user_group_name      = var.user_group_name
}

# DynamoDB
module "dynamodb" {
  source                         = "./dynamodb"
  game_monitoring_table_name     = var.game_monitoring_table_name
  game_monitoring_id_column_name = var.game_monitoring_id_column_name
}

# Ses, to send notification mails
module "ses" {
  source           = "./ses"
  hosted_zone_name = var.hosted_zone_name
  hosted_zone_id   = local.hosted_zone_id
  region           = var.region
  admin_mail       = var.admin_mail
}








