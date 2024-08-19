provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "terraform-tjl"
    key    = "terraform_${var.deployment_branch}.tfstate"
    region = var.region
  }
}

module "ecr" {
  source                 = "./ecr"
  game_server_name_image = va.game_server_name_image
  proxy_name_image       = var.proxy_name_image
}



