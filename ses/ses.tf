variable "hosted_zone_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "region" {
  type = string
}

variable "admin_mail" {
  type = string
}

# resource "aws_ses_configuration_set" "ses_config" {
#   name                       = "config_ses"
#   reputation_metrics_enabled = true
# }

# resource "aws_ses_domain_identity" "domain_identity" {
#   domain = var.hosted_zone_name
# }

# resource "aws_ses_domain_dkim" "dkim_identity" {
#   domain = aws_ses_domain_identity.domain_identity.domain
# }

# resource "aws_route53_record" "amazonses_dkim_record" {
#   count   = 3
#   zone_id = var.hosted_zone_id
#   name    = "${aws_ses_domain_dkim.dkim_identity.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.domain_identity.domain}"
#   type    = "CNAME"
#   ttl     = "300"
#   records = ["${aws_ses_domain_dkim.dkim_identity.dkim_tokens[count.index]}.dkim.amazonses.com"]
# }

# resource "aws_ses_domain_identity_verification" "domain_identity_verification" {
#   domain     = aws_ses_domain_identity.domain_identity.id
#   depends_on = [aws_route53_record.amazonses_dkim_record]
# }

resource "aws_ses_email_identity" "email_identity" {
  email = var.admin_mail
}



