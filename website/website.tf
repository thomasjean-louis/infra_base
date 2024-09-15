variable "deployment_branch" {
  type = string
}

variable "region" {
  type = string
}

variable "website_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "hosted_zone_name" {
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


# Cloudfront distribution

locals {
  s3_origin_id   = "${aws_s3_bucket.website-bucket.bucket}-origin"
  s3_domain_name = "${aws_s3_bucket.website-bucket.bucket}.s3-website-${var.region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "distribution" {

  enabled = true

  origin {
    origin_id   = local.s3_origin_id
    domain_name = local.s3_domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

}

# Cloudfront alias
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = var.hosted_zone_id
  name    = var.hosted_zone_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  depends_on = [aws_cloudfront_distribution.distribution, aws_s3_bucket.website-bucket]
  bucket     = aws_s3_bucket.website-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowCloudFrontServicePrincipal"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { "Service" : "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website-bucket.arn}/**"
        Condition = {
          "StringEquals" : {
            "AWS:SourceArn" : "${aws_cloudfront_distribution.distribution.arn}"
      } } }
    ]
  })
}

# Create IAM user to upload content into the bucket
resource "aws_iam_user" "upload_website_files_user" {
  name = "upload_website_files_user_${var.deployment_branch}"

  tags = {
    name = "upload_website_files_user_${var.deployment_branch}"
  }
}

data "aws_iam_policy_document" "upload_s3_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject "]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*"]
  }
}

resource "aws_iam_user_policy" "s3_policy_association" {
  name   = "upload_s3_policy_${var.deployment_branch}"
  user   = aws_iam_user.upload_website_files_user.name
  policy = data.aws_iam_policy_document.upload_s3_policy.json
}


