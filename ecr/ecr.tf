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

## IAM user + inline policies required for ECR management
resource "aws_iam_user" "terraform_infra_user" {
  name = "ecr_user_${var.deployment_branch}"

  tags = {
    name = "ecr_user_${var.deployment_branch}"
  }
}

data "aws_iam_policy_document" "ecr_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}


resource "aws_iam_user_policy" "ecr_policy" {
  name   = "ecr_policy_${var.deployment_branch}"
  user   = aws_iam_user.terraform_infra_user.name
  policy = data.aws_iam_policy_document.ecr_policy_document.json
}







