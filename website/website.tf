variable "deployment_branch" {
  type = string
}

variable "region" {
  type = string
}

variable "website_name" {
  type = string
}

resource "random_string" "random_string" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

resource "aws_s3_bucket" "website-bucket" {
  bucket = "s3-${var.region}-${var.website_name}-${random_string.random_string.result}-${var.deployment_branch}"

  tags = {
    Name = "s3-${var.region}-${var.website_name}-${random_string.random_string.result}-${var.deployment_branch}"
  }
}

resource "aws_s3_bucket_website_configuration" "configuration" {
  bucket = aws_s3_bucket.website-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
