resource "aws_launch_configuration" "web" {
  for_each = var.web_apps

  name                 = "${each.key}-launch-config"
  image_id             = each.value["ami"]
  instance_type        = each.value["instance_type"]
  security_groups      = [aws_security_group.web.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    aws s3 cp s3://${aws_s3_bucket.web_bucket.id}/${format("app/%s", basename(each.value["path"]))} /usr/local/bin/app.bin
    chmod +x /usr/local/bin/app.bin
    /usr/local/bin/app.bin
  EOF
}

resource "aws_autoscaling_group" "web" {
  for_each = var.web_apps

  name                 = "${each.key}-asg"
  min_size             = each.value["weight"] == 0 ? 0 : 2
  max_size             = 4
  desired_capacity     = each.value["weight"] == 0 ? 0 : 2
  launch_configuration = aws_launch_configuration.web[each.key].name
  vpc_zone_identifier  = var.subnet_private_ids
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = each.key
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.web[each.key].arn]
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Access from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}
