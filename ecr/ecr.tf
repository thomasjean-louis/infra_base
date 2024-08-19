variable "game_server_name_image" {
  type = string
}

variable "proxy_name_image" {
  type = string
}


resource "aws_ecr_repository" "game_server_ecr_repo" {
  name                 = var.game_server_name_image
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository" "proxy_ecr_repo" {
  name                 = var.proxy_name_image
  image_tag_mutability = "IMMUTABLE"
}
