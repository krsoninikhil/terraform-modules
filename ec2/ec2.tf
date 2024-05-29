resource "aws_security_group" "instance_sg" {
  name        = var.name
  description = "sg for direct instance"
  vpc_id      = var.vpc_id
  # ingress = []

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_sg_in" {
  for_each = { for v in var.connections : v.port => v if v.from_cidr_ipv4 != "" }

  security_group_id = aws_security_group.instance_sg.id
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value.from_cidr_ipv4
}

resource "aws_key_pair" "instance_key" {
  key_name   = var.name
  public_key = var.public_key
}

resource "aws_launch_template" "template" {
  name          = var.name
  instance_type = var.instance_type
  image_id      = local.ami_id
  key_name      = aws_key_pair.instance_key.key_name
  # vpc_security_group_ids = [ aws_security_group.instance_sg.id ]
  user_data = base64encode(local.user_data)

  network_interfaces {
    associate_public_ip_address = true # can be removed if bastion is setup for ssh
    security_groups             = [aws_security_group.instance_sg.id]
    subnet_id                   = data.aws_subnets.subnets.ids[0]
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = var.name }
  }
}

resource "aws_lb_target_group" "tgs" {
  for_each = { for v in var.connections : v.port => v }

  name     = var.name
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags     = each.value.sub_domain != "" ? { domain = "${each.value.sub_domain}.${var.domain}" } : {}

  health_check {
    path    = each.value.health_path
    matcher = "200,404"
  }
}

resource "aws_autoscaling_group" "instance_asg" {
  count               = var.autoscaling.enabled ? 1 : 0
  
  name                = var.name
  max_size            = var.autoscaling.max_size
  min_size            = var.autoscaling.min_size
  vpc_zone_identifier = data.aws_subnets.subnets.ids
  target_group_arns   = [for tg in aws_lb_target_group.tgs : tg.arn]

  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
    }
  }
}

# without autoscaling
resource "aws_instance" "instance" {
  count = var.autoscaling.enabled ? 0 : 1
  tags  = { Name = var.name }

  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version
  }
}

# attach an elastic ip if autoscaling is not used
resource "aws_eip" "instance_eip" {
  count = length(aws_instance.instance)

  vpc      = true
  instance = aws_instance.instance[count.index].id
  tags     = { Name = var.name }
}

resource "aws_lb_target_group_attachment" "instance_tgs_attach" {
  for_each = length(aws_instance.instance) > 0 ? aws_lb_target_group.tgs : {}

  target_group_arn = each.value.arn
  target_id        = aws_instance.instance[0].id
  port             = each.key
}

module "connect_elb" {
  source = "./connect"
  count  = var.domain != "" ? 1 : 0

  name              = var.name
  vpc_id            = var.vpc_id
  connections       = var.connections
  listener_arn      = var.listener_arn
  domain            = var.domain
  instance_sg_id    = aws_security_group.instance_sg.id
  target_group_arns = [for k, v in aws_lb_target_group.tgs : { port = k, arn = v.arn }]
}
