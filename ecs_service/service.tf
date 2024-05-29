resource "aws_ecr_repository" "ecr" {
  name         = var.service_name
  force_delete = true
}

resource "aws_cloudwatch_log_group" "svc_log" {
  name = "/ecs/${var.service_name}"
}

resource "aws_ecs_task_definition" "task_definition" {
  family = var.service_name

  volume {
    name      = "docker_sock"
    host_path = "/var/run/docker.sock"
  }

  container_definitions = jsonencode([
    {
      name              = var.service_name
      image             = "jwilder/nginx-proxy" # to verify the deployment, it can be updated by CD pipeline
      memoryReservation = 128
      essential         = true
      cpu               = 0
      environment       = [{ name = "VIRTUAL_PORT", value = tostring(var.port) }]
      mountPoints = [
        {
          sourceVolume  = "docker_sock"
          containerPath = "/tmp/docker.sock"
          readOnly      = true
        }
      ]
      portMappings = [
        {
          containerPort = var.port,
          hostPort      = 0,
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group  = "${aws_cloudwatch_log_group.svc_log.name}"
          awslogs-region = local.region
        }
      }
    }
  ])
  # other attributes can be updated by Actions during deployment
}

resource "aws_lb_target_group" "tg" {
  name                          = "${var.service_name}-ecs"
  port                          = 80
  protocol                      = "HTTP"
  load_balancing_algorithm_type = "least_outstanding_requests"
  deregistration_delay          = 60
  vpc_id                        = var.vpc_id

  health_check {
    path    = var.health_path
    matcher = "200,404"
  }
}

resource "aws_lb_listener_rule" "service_route" {
  count        = var.route != "" ? 1 : 0
  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    path_pattern {
      values = [var.route]
    }
  }
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.service_name
    container_port   = var.port
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [
    aws_lb_listener_rule.service_route
  ]
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = local.max_count
  min_capacity       = 1
  resource_id        = "service/${var.cluster}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name               = "${var.service_name}-ecs"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}
