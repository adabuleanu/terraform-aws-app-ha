resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_public_ids
  security_groups    = [aws_security_group.web_alb.id]

  tags = merge(local.tags, tomap({ Name = "web-app" }))
}

resource "aws_security_group" "web_alb" {
  name   = "web-alb-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = [443, 80]

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = var.tags
}

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.web.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Sample"
      status_code  = "404"
    }
  }

  tags = var.tags
}

resource "aws_lb_target_group" "web" {
  for_each = var.web_apps

  name     = "${each.key}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/success"
    port                = 8080
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = length(keys(var.web_apps)) == 1 ? aws_lb_target_group.web[one(keys(var.web_apps))].arn : null
    dynamic "forward" {
      for_each = length(keys(var.web_apps)) == 1 ? [] : [aws_lb_target_group.web]
      content {
        dynamic "target_group" {
          for_each = var.web_apps
          content {
            arn    = aws_lb_target_group.web[target_group.key].arn
            weight = target_group.value["weight"]
          }
        }
        stickiness {
          enabled  = true
          duration = 600
        }
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = var.tags
}

resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.web.zone_id
  name    = "web"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}
