variable "hosted_zone_name" {
  type = string
}


resource "aws_route53_zone" "hosted_zone" {
  name = var.hosted_zone_name
}
