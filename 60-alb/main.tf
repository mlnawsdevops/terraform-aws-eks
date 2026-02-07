# ingress alb
# fixed for future services...catalogue, cat, etc

# Health checks:
# IP mode → check pod IP:80
# Instance mode → check NodePort (traffic-port)

# Adding future services:
# Copy a listener rule + target group
# Add a Route53 record pointing to the same ALB

# expense-dev.daws100s.online → ClusterIP pods via IP target group

# expense-mln.daws100s.online → NodePort pods via instance target group

module "ingress_alb" {
  source = "terraform-aws-modules/alb/aws"

  internal = false
  name     = local.resource_name # expense-dev-ingress-alb
  vpc_id   = local.vpc_id
  subnets  = local.public_subnet_ids

  security_groups       = [local.ingress_alb_sg_id]
  create_security_group = false
  enable_deletion_protection = false
  tags = merge(
    var.common_tags,
    # var.ingress_alb_tags,
    {
      Name = local.resource_name
    }
  )
}

# ingress alb listener http
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.ingress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action { # action means rule
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from INGRESS ALB http</h1>"
      status_code  = "200"
    }
  }
}

# ingress alb listner https
resource "aws_lb_listener" "https" {
  load_balancer_arn = module.ingress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_ssm_parameter.https_certificate_arn.value

  default_action { # action means rule
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>Hello, I am from INGRESS ALB https</h1>"
      status_code  = "200"
    }
  }
}

# creating route53 record for ingress alb dns name
module "zone" {
  source = "terraform-aws-modules/route53/aws"

  name        = var.zone_name
  create_zone = false

  records = {
    app_wildcard = {
      name = "expense-${var.environment}" # expense-dev.daws100s.online
      type = "A"
      alias = {
        name    = module.ingress_alb.dns_name # ingress loadbalancer name
        zone_id = module.ingress_alb.zone_id # ingress loadbalancer zone_id
      }
      allow_overwrite = true 
    }

    # expense-mln.daws100s.online -> Instance mode
    expense_mln = {
      name = "expense-mln" # expense-mln.daws100s.online
      type = "A"
      alias = {
        name    = module.ingress_alb.dns_name
        zone_id = module.ingress_alb.zone_id
      }
      allow_overwrite = true
    }

    expense_catalogue = {
      name = "expense-catalogue" # expense-mln.daws100s.online
      type = "A"
      alias = {
        name    = module.ingress_alb.dns_name
        zone_id = module.ingress_alb.zone_id
      }
      allow_overwrite = true
    }
  }

  tags = merge(
    var.common_tags,
    var.route53_tags,
    {
      Name = local.resource_name
    }
  )
}



# changing when new service comes up
resource "aws_lb_target_group" "expense" {
  name     = local.resource_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 5
    matcher = "200-299"
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 4
  }
}

# target group for expense-mln.daws100s.online
resource "aws_lb_target_group" "expense_mln" {
  name     = "${local.resource_name}-mln"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 5
    matcher = "200-299"
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 4
  }
}

resource "aws_lb_target_group" "expense_catalogue" {
  name     = "${local.resource_name}-cat"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 5
    matcher = "200-299"
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 4
  }
}


# listener rule only changing for new services comes up
resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100 # low priority will be evaluated first

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.expense.arn
  }

  condition {
    host_header {
      values = ["expense-${var.environment}.${var.zone_name}"] #expense-dev.daws81s.online
    }
  }
}

# listener rule for expense-mln
resource "aws_lb_listener_rule" "frontend_mln" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 99 # low priority will be evaluated first

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.expense_mln.arn
  }

  condition {
    host_header {
      values = ["expense-mln.${var.zone_name}"] #expense-dev.daws81s.online
    }
  }
}

resource "aws_lb_listener_rule" "frontend_catalogue" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 98 # low priority will be evaluated first

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.expense_catalogue.arn
  }

  condition {
    host_header {
      values = ["expense-catalogue.${var.zone_name}"] #expense-dev.daws81s.online
    }
  }
}