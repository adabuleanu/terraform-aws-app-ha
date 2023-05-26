output "app_alb_dns" {
  value = aws_lb.web.dns_name
}

output "app_endpoint" {
  value = format("https://%s.%s/success", aws_route53_record.web.name, var.route53_name, )
}
