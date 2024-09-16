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

resource "aws_s3_bucket_public_access_block" "static_site_bucket_public_access" {
  bucket = aws_s3_bucket.website-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
  s3_origin_id   = aws_s3_bucket.website-bucket.bucket
  s3_domain_name = "${aws_s3_bucket.website-bucket.bucket}.s3-website.${var.region}.amazonaws.com"
}

resource "aws_cloudfront_origin_access_control" "cf-s3-oac" {
  name                              = "CloudFront S3 OAC"
  description                       = "CloudFront S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ACM certificate
resource "aws_acm_certificate" "website_certificate" {
  domain_name       = var.hosted_zone_name
  provider          = "aws.us-east-1"
  validation_method = "DNS"
}

resource "aws_route53_record" "dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.website_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  provider                = "aws.us-east-1"
  certificate_arn         = aws_acm_certificate.website_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_record : record.fqdn]
}

resource "aws_cloudfront_distribution" "distribution" {
  depends_on = [aws_acm_certificate_validation.certificate_validation]

  enabled             = true
  default_root_object = "index.html"

  origin {
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cf-s3-oac.id

  }


  aliases = [var.hosted_zone_name]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.website_certificate.arn
    ssl_support_method  = "sni-only"
  }


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }



  price_class = "PriceClass_All"

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
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
      Resource = "arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*" }
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
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*"]
  }
}

resource "aws_iam_user_policy" "s3_policy_association" {
  name   = "upload_s3_policy_${var.deployment_branch}"
  user   = aws_iam_user.upload_website_files_user.name
  policy = data.aws_iam_policy_document.upload_s3_policy.json
}


