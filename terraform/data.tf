data "aws_route53_zone" "web" {
  name         = var.route53_name
  private_zone = false
  vpc_id       = var.vpc_id
}

data "aws_acm_certificate" "web" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}
