
variable "app_name" {
  type = string
}

variable "deployment_branch" {
  type = string  
}

variable "token_github" {
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
    }
  }
}

## Set Scheduler

# Delete stack
resource "aws_cloudwatch_event_rule" "delete_infra_rule" {
  name        = "delete_infra_rule"

  schedule_expression = "cron(16 8 * * *)"
}


resource "aws_cloudwatch_event_target" "delete_infra_lambda_target" {
  rule      = aws_cloudwatch_event_rule.delete_infra_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda_delete_infra.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_delete_infra.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.delete_infra_rule.arn
}


# Create stack

