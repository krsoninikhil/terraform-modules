resource "aws_launch_template" "template" {
  name          = "${var.cluster_name}-ecs"
  instance_type = var.instance_type
  image_id      = var.ami_id
  key_name      = aws_key_pair.instance_key.key_name
  user_data = base64encode(<<EOF
#!/bin/bash
sudo mkdir -p /etc/ecs && sudo touch /etc/ecs/ecs.config
sudo echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
sudo echo 'ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs","fluentd","journald"]' >> /etc/ecs/ecs.config
EOF
  )

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.iam_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = true # ecs requires public ip, todo: setup NAT Gateway to avoid public ips
    security_groups             = [aws_security_group.ecs_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.cluster_name}-ecs" }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.cluster_name}-ecs"
  max_size            = var.max_instances
  min_size            = var.min_instances
  vpc_zone_identifier = data.aws_subnets.subnets.ids

  launch_template {
    id      = aws_launch_template.template.id
    version = aws_launch_template.template.latest_version # using '$Latest' doesn't trigger refresh
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
    }
  }

  lifecycle {
    ignore_changes = [
      tag,
    ]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_ecs_capacity_provider" "cp" {
  name = "${var.cluster_name}-ecs"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.asg.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "ccp" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = [aws_ecs_capacity_provider.cp.name]
}
