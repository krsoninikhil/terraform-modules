variable "listener_arn" {}
variable "domain" {}
variable "name" {}
variable "vpc_id" {}
variable "instance_sg_id" {}
variable "connections" {
  type = list(object({
    port           = number
    from_cidr_ipv4 = string
    sub_domain     = string
    health_path    = string
    routes         = list(string)
  }))
}

variable "target_group_arns" {
  type = list(object({
    port = number
    arn  = string
  }))
}

locals {
  target_group_arns = { for v in var.target_group_arns : v.port => v.arn }
  lb_sg_id          = length(data.aws_lb.lb.security_groups) > 0 ? tolist(data.aws_lb.lb.security_groups)[0] : ""
}

data "aws_lb_listener" "listner" {
  arn = var.listener_arn

  lifecycle {
    precondition {
      condition     = var.listener_arn != ""
      error_message = "listener arn is required for finding the elb for domain to point to"
    }
  }
}

data "aws_lb" "lb" {
  arn = data.aws_lb_listener.listner.load_balancer_arn
}
