data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket       = var.state_bucket
    key          = "vpc"
    region       = var.aws_region
    session_name = "terraform"
    profile      = var.aws_profile
  }
}

data "aws_route53_zone" "web" {
  name         = var.route53_name
  private_zone = false
}

data "aws_acm_certificate" "web" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}
