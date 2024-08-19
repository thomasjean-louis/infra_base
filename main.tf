provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {}
}

module "ecr" {
  source                 = "./ecr"
  game_server_name_image = va.game_server_name_image
  proxy_name_image       = var.proxy_name_image
}



