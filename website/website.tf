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

variable "cloudfront_function_arn" {
  type = string
}


# variable "restrict_ip_function__arn" {
#   type = string
# }



provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

resource "random_string" "random_string" {
  length  = 10
  special = false
  numeric = false
  upper   = false
}

# S3 
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

# Use lambda#Edge insted of Waf, to save money
# # WAF
# resource "aws_wafv2_ip_set" "allowed_ips" {

#   provider           = aws.us-east-1
#   name               = "allowed-ips"
#   description        = "Authorized IP addresses"
#   scope              = "CLOUDFRONT"
#   ip_address_version = "IPV4"
#   addresses          = [var.waf_allowed_ip]
# }

# resource "aws_wafv2_web_acl" "waf_web_acl" {
#   name     = "${var.website_name}_waf"
#   scope    = "CLOUDFRONT"
#   provider = aws.us-east-1

#   default_action {
#     allow {}
#   }

#   tags = {
#     Name = "${var.website_name}_waf"
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${var.website_name}_waf"
#     sampled_requests_enabled   = true
#   }

#   // Block IPs not in whitelist
#   dynamic "rule" {
#     for_each = var.deployment_branch == "dev" ? [1] : []
#     content {
#       name     = "whitelist_ip"
#       priority = 100

#       statement {
#         not_statement {
#           statement {
#             ip_set_reference_statement {
#               arn = aws_wafv2_ip_set.allowed_ips.arn
#             }
#           }
#         }
#       }

#       action {
#         block {}
#       }


#       visibility_config {
#         cloudwatch_metrics_enabled = true
#         metric_name                = "AWSManagedRulesCommonRuleSetMetric"
#         sampled_requests_enabled   = true
#       }
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 10

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     override_action {
#       none {}
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesCommonRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesAdminProtectionRuleSet"
#     priority = 20

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesAdminProtectionRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     override_action {
#       none {}
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesAdminProtectionRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesKnownBadInputsRuleSet"
#     priority = 30

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesKnownBadInputsRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     override_action {
#       none {}
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
#       sampled_requests_enabled   = true
#     }
#   }

#   rule {
#     name     = "AWSManagedRulesAmazonIpReputationList"
#     priority = 40

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesAmazonIpReputationList"
#         vendor_name = "AWS"
#       }
#     }

#     override_action {
#       none {}
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
#       sampled_requests_enabled   = true
#     }
#   }
# }


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
  provider          = aws.us-east-1
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
  provider                = aws.us-east-1
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



  # web_acl_id = aws_wafv2_web_acl.waf_web_acl.arn

  aliases = [var.hosted_zone_name]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.website_certificate.arn
    ssl_support_method  = "sni-only"
  }


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    dynamic "lambda_function_association" {
      for_each = var.deployment_branch == "dev" ? [1] : []
      content {
        event_type = "viewer-request"
        lambda_arn = "${var.cloudfront_function_arn}:1"
      }
    }


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
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.website-bucket.bucket}/*"]
  }
}

resource "aws_iam_user_policy" "s3_policy_association" {
  name   = "upload_s3_policy_${var.deployment_branch}"
  user   = aws_iam_user.upload_website_files_user.name
  policy = data.aws_iam_policy_document.upload_s3_policy.json
}



