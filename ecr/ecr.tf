variable "account_id" {
  type = string
}

variable "game_server_name_image" {
  type = string
}

variable "proxy_name_image" {
  type = string
}

variable "deployment_branch" {
  type = string
}

## Repositories
resource "aws_ecr_repository" "game_server_ecr_repo" {
  name                 = var.game_server_name_image
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository" "proxy_ecr_repo" {
  name                 = var.proxy_name_image
  image_tag_mutability = "IMMUTABLE"
}

## IAM user + roles required for ECR management
resource "aws_iam_user" "terraform_infra_user" {
  name = "ecr_user_${var.deployment_branch}"

  tags = {
    name = "ecr_user_${var.deployment_branch}"
  }
}

resource "aws_iam_role" "terra_form_infra_role" {
  name = "ecr_role_${var.deployment_branch}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : { "AWS" : "arn:aws:iam::${var.account_id}:user/${aws_iam_user.terraform_infra_user.name}" },
      },
    ]
  })

  tags = {
    name = "ecr_role_${var.deployment_branch}"
  }
}






