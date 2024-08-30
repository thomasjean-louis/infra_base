variable "deployment_branch" {
  type = string
}

variable "account_id" {
  type = string
}


resource "aws_iam_user" "terraform_infra_user" {
  name = "terraform_infra_user_${var.deployment_branch}"

  tags = {
    name = "terraform_infra_user_${var.deployment_branch}"
  }
}


resource "aws_iam_role" "terraform_infra_role" {
  name = "terraform_infra_role_${var.deployment_branch}"

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
    name = "terraform_infra_role_${var.deployment_branch}"
  }
}



