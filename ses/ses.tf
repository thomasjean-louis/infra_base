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

resource "aws_ses_email_identity" "email_identity" {
  email = var.admin_mail
}



