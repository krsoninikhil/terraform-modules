resource "aws_lb_listener_rule" "app_route" {
  for_each     = { for v in var.connections : v.port => v if length(v.routes) != 0 || v.sub_domain != "" }
  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = local.target_group_arns[each.value.port]
  }

  dynamic "condition" {
    for_each = { for v in var.connections : v.port => v if length(v.routes) != 0 }
    content {
      path_pattern {
        values = condition.value.routes
      }
    }
  }

  dynamic "condition" {
    for_each = { for v in var.connections : v.port => v if v.sub_domain != "" }
    content {
      host_header {
        values = ["${condition.value.sub_domain}.${var.domain}"]
      }
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_sg_in" {
  for_each = { for v in var.connections : v.port => v }

  security_group_id            = var.instance_sg_id
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.lb_sg_id
}
