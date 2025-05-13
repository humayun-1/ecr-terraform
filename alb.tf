resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  enable_deletion_protection = false
}


resource "aws_lb_target_group" "app" {
  name                 = "${var.app_name}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 120

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    protocol            = "HTTP"
    path                = "/api/health"
    interval            = 30
    matcher             = "200-399"
  }

  # Enable stickiness if needed
  stickiness {
    enabled         = false
    type            = "lb_cookie"
    cookie_duration = 86400
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}