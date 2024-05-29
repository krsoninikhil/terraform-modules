variable "service_name" {}
variable "cluster" {}
variable "listener_arn" {}
variable "vpc_id" {}
variable "port" {}
variable "desired_count" {}

variable "route" {
  description = "path pattern to access the service on, leave empty to avoid attaching to LB"
  default     = ""
}

variable "health_path" {
  default = "/ping"
}
variable "health_port" {
  default = 0
}

locals {
  region    = "ap-south-1"
  max_count = var.desired_count * 2
}
