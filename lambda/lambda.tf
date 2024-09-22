variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string
}

variable "token_github" {
  type = string
}

variable "hosted_zone_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "waf_allowed_ip" {
  type = string
}

# iam Lambda role
resource "aws_iam_role" "lambda_infra_role" {
  name = "${var.app_name}_lambda_infra_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM role
resource "aws_iam_role_policy" "lambda_infra_role_policy" {
  name = "${var.app_name}_lambda_infra_${var.deployment_branch}"
  role = aws_iam_role.lambda_infra_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
      },
      {
        Action = [
          "cloudformation:ListStacks",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:cloudformation:${var.region}:${var.account_id}:stack/*/*"
      },
      {
        Action = [
          "wafv2:GetWebACLForResource",
          "wafv2:GetWebACL"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:wafv2:${var.region}:${var.account_id}:regional/webacl/*/*"
      },
      {
        Action = [
          "route53:GetHostedZone",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Action = [
          "route53:GetChange",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:DeleteFunction"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:lambda:${var.region}:${var.account_id}:function:*"
      },
      {
        Action = [
          "elasticloadbalancing:SetWebACL",
          "elasticloadbalancing:DeleteLoadBalancer",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:loadbalancer/*"
      },
      {
        Action = [
          "elasticloadbalancing:DeleteListener",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:listener/*"
      },
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:DeleteService"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ecs:${var.region}:${var.account_id}:service/*"
      },
      {
        Action = [
          "elasticloadbalancing:DescribeListeners"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:elasticloadbalancing:${var.region}:${var.account_id}:targetgroup/*"
      },
      {
        Action = [
          "acm:DeleteCertificate"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:acm:${var.region}:${var.account_id}:certificate/*"
      }
    ]
  })
}




# Create terraform infra
data "archive_file" "create_infra_zip" {
  type        = "zip"
  source_file = "${path.module}/create_infra.py"
  output_path = "${path.module}/create_infra.zip"
}

resource "aws_lambda_function" "lambda_create_infra" {
  function_name    = "create_infra"
  filename         = data.archive_file.create_infra_zip.output_path
  source_code_hash = data.archive_file.create_infra_zip.output_base64sha256
  role             = aws_iam_role.lambda_infra_role.arn
  handler          = "create_infra.lambda_handler"
  runtime          = "python3.9"
  timeout          = 20

  environment {
    variables = {
      TOKEN_GITHUB      = var.token_github
      DEPLOYMENT_BRANCH = var.deployment_branch
    }
  }
}

# Delete terraform infra
data "archive_file" "delete_infra_zip" {
  type        = "zip"
  source_file = "${path.module}/delete_infra.py"
  output_path = "${path.module}/deleteinfra.zip"
}

resource "aws_lambda_function" "lambda_delete_infra" {
  function_name    = "delete_infra"
  filename         = data.archive_file.delete_infra_zip.output_path
  source_code_hash = data.archive_file.delete_infra_zip.output_base64sha256
  role             = aws_iam_role.lambda_infra_role.arn
  handler          = "delete_infra.lambda_handler"
  runtime          = "python3.9"
  timeout          = 400

  environment {
    variables = {
      TOKEN_GITHUB      = var.token_github
      DEPLOYMENT_BRANCH = var.deployment_branch
      HOSTED_ZONE_ID    = var.hosted_zone_id
    }
  }
}

## Set Scheduler

# Delete stack
resource "aws_cloudwatch_event_rule" "delete_infra_rule" {
  name = "delete_infra_rule"

  schedule_expression = "cron(0 16 ? * MON-FRI *)"
}


resource "aws_cloudwatch_event_target" "delete_infra_lambda_target" {
  rule      = aws_cloudwatch_event_rule.delete_infra_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda_delete_infra.arn
}

resource "aws_lambda_permission" "allow_eventbridge_delete" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_delete_infra.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.delete_infra_rule.arn
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

resource "aws_iam_role" "restrict_ip_role" {
  name               = "template-variable-demo"
  path               = "/"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# resource "aws_iam_role_policy" "my-role" {
#   name   = "template-variable-demo"
#   role   = aws_iam_role.restrict_ip_role.name
#   policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#               "logs:CreateLogGroup",
#               "logs:CreateLogStream",
#               "logs:PutLogEvents"
#             ],
#             "Resource": "arn:aws:logs:*:*:*"
#         }
#     ]
# }
# POLICY
# }


# Restrict Ip lambda Edge function
# data "archive_file" "restrict_ip_zip" {
#   type        = "zip"
#   source_file = "${path.module}/restrict_ip.js"
#   output_path = "${path.module}/restrict_ip.zip"
# }

data "archive_file" "ip-function" {
  type        = "zip"
  output_path = "${path.module}/ip-function.zip"

  source {
    content  = templatefile("${path.module}/restrict_ip.js", { restrict_ip = var.waf_allowed_ip })
    filename = "restrict_ip.js"
  }
}

resource "aws_lambda_function" "lambda_restrict_ip" {
  provider         = aws.us-east-1
  function_name    = "restrict_ip"
  filename         = data.archive_file.ip-function.output_path
  source_code_hash = data.archive_file.ip-function.output_base64sha256
  role             = aws_iam_role.restrict_ip_role.arn
  handler          = "restrict_ip.lambda_handler"
  runtime          = "nodejs20.x"
  timeout          = 4
  publish          = true
}

resource "aws_lambda_permission" "allow_cloudfront" {
  provider      = aws.us-east-1
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.lambda_restrict_ip.function_name
  principal     = "edgelambda.amazonaws.com"
}

output "restrict_ip_function_arn" {
  value = "${aws_lambda_function.lambda_restrict_ip.arn}:${aws_lambda_function.lambda_restrict_ip.version}"
}



# # Create stack

# resource "aws_cloudwatch_event_rule" "create_infra_rule" {
#   name        = "create_infra_rule"

#   schedule_expression = "cron(55 6 ? * MON-FRI *)"
# }


# resource "aws_cloudwatch_event_target" "create_infra_lambda_target" {
#   rule      = aws_cloudwatch_event_rule.create_infra_rule.name
#   target_id = "SendToLambda"
#   arn       = aws_lambda_function.lambda_create_infra.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_create" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_create_infra.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.create_infra_rule.arn
# }

