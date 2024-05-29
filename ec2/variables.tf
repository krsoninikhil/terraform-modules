variable "vpc_id" {}
variable "name" {}
variable "instance_type" {}
variable "public_key" {}

variable "connections" {
  description = "connections to allow, leave sub_domain and route both empty if elb is not required"
  type = list(object({
    port           = number
    from_cidr_ipv4 = string
    sub_domain     = string
    health_path    = string
    routes         = list(string)
  }))
  default = []
}

variable "user_data" {
  default = ""
}

variable "autoscaling" {
  description = "to disable autoscaling group for instance"
  type = object({
    enabled  = bool
    min_size = number
    max_size = number
  })
  default = {
    enabled  = true
    max_size = 1
    min_size = 1
  }
}

variable "listener_arn" {
  description = "elb listner to attach the instance on, leave empty if elb is not required"
  default     = ""
}

variable "domain" {
  description = "primary domain on which instance should be access"
  default     = ""
}

variable "ami_id" {
  default = ""
}

variable "user_data_template_file" {
  description = "path to user data template file"
  default     = ""
}

locals {
  ami_id    = var.ami_id != "" ? var.ami_id : data.aws_ami.amzn-linux-2023-ami.id
  user_data = var.user_data_template_file != "" ? templatefile(var.user_data_template_file, {}) : var.user_data
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
