
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
          "route53:ListResourceRecordSets"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone:${var.hosted_zone_id}"
      },
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
      TOKEN_GITHUB             = var.token_github
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
  timeout          = 20

  environment {
    variables = {
      TOKEN_GITHUB             = var.token_github
      DEPLOYMENT_BRANCH = var.deployment_branch
      HOSTED_ZONE_ID = var.hosted_zone_id
    }
  }
}

## Set Scheduler

# Delete stack
resource "aws_cloudwatch_event_rule" "delete_infra_rule" {
  name        = "delete_infra_rule"

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


# Create stack

resource "aws_cloudwatch_event_rule" "create_infra_rule" {
  name        = "create_infra_rule"

  schedule_expression = "cron(55 6 ? * MON-FRI *)"
}


resource "aws_cloudwatch_event_target" "create_infra_lambda_target" {
  rule      = aws_cloudwatch_event_rule.create_infra_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda_create_infra.arn
}

resource "aws_lambda_permission" "allow_eventbridge_create" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_create_infra.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.create_infra_rule.arn
}

