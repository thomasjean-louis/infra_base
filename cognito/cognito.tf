variable "region" {
  type = string
}

variable "app_name" {
  type = string
}

variable "default_cognito_mail" {
  type = string
}

variable "admin_cognito_username" {
  type = string
}

variable "admin_cognito_password" {
  type = string
}

variable "classic_cognito_username" {
  type = string
}

variable "classic_cognito_password" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "subdomain_auth" {
  type = string
}

variable "hosted_zone_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

variable "admin_group_name" {
  type = string
}

variable "user_group_name" {
  type = string
}

resource "random_string" "random_string" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

#Cognito log groups
resource "aws_cloudwatch_log_group" "log_group" {
  name = "cognito"
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "cognito"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}


resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.app_name}-user-pool-${var.deployment_branch}"

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  password_policy {
    minimum_length                   = 6
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

}

# User Pool

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                         = "${var.app_name}-user-pool_client-${var.deployment_branch}"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.app_name}-identity-pool"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
    server_side_token_check = false
  }
}

# Iam identity role
resource "aws_iam_role" "role_identity_pool" {
  name = "${var.app_name}_identity_pool"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "cognito-identity.amazonaws.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "cognito-identity.amazonaws.com:aud" : "${aws_cognito_identity_pool.identity_pool.id}"
          },
          "ForAnyValue:StringLike" : {
            "cognito-identity.amazonaws.com:amr" : "authenticated"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cognito_authenticated_policy" {
  name = "${var.app_name}_cognito_authenticated_policy_${var.deployment_branch}"
  role = aws_iam_role.role_identity_pool.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "cognito-identity:GetCredentialsForIdentity"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "cognito_identity_role_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.role_identity_pool.arn
  }
}



output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.user_pool.endpoint
}


# Groups
resource "aws_cognito_user_group" "admin_group" {
  name         = var.admin_group_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Admin group"
}

resource "aws_cognito_user_group" "user_group" {
  name         = var.user_group_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "User group"
}


# Users
resource "aws_cognito_user" "admin_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.admin_cognito_username
  password     = var.admin_cognito_password

  enabled = true

  attributes = {
    email          = var.default_cognito_mail
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "admin_user_group" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  group_name   = aws_cognito_user_group.admin_group.name
  username     = aws_cognito_user.admin_user.username
}

resource "aws_cognito_user" "classic_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.classic_cognito_username
  password     = var.classic_cognito_password

  enabled = true

  attributes = {
    email          = var.default_cognito_mail
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "classic_user_group" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  group_name   = aws_cognito_user_group.user_group.name
  username     = aws_cognito_user.classic_user.username
}

