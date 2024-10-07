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

variable "send_mail" {
  type = string
}

resource "aws_ses_email_identity" "email_identity" {
  email = var.admin_mail
}

resource "aws_ses_email_identity" "send_email_identity" {
  email = var.send_mail
}



