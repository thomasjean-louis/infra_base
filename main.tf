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
  app_name          = var.app_name
  deployment_branch = var.deployment_branch
  token_github      = var.token_github
  hosted_zone_id    = local.hosted_zone_id
  hosted_zone_name  = var.hosted_zone_name
}

module "website" {
  source            = "./website"
  region            = var.region
  website_name      = var.website_name
  deployment_branch = var.deployment_branch
  hosted_zone_id    = local.hosted_zone_id
  hosted_zone_name  = var.hosted_zone_name
  waf_allowed_ip    = var.waf_allowed_ip
}






