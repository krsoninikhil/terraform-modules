variable "name" {}
variable "vpc_id" {}
variable "no_of_nodes" {}
variable "instance_type" {}
variable "make_public" {
  description = "must be false if running first time, can only be updated to true"
}

variable "scram_users" {
  type = list(object({
    username = string
    password = string
  }))
  sensitive = true
}

variable "volume_size" {
  default = 8
}

locals {
  subnet_ids = data.aws_subnets.subnets.ids
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  lifecycle {
    postcondition {
      condition     = length(self.ids) > 1
      error_message = "VPC should have at least 2 subnets in different availability zones"
    }
  }
}
