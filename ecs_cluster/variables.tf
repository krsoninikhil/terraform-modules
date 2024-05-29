variable "cluster_name" {}
variable "instance_type" {}
variable "min_instances" {}
variable "max_instances" {}
variable "vpc_id" {}
variable "ssh_public_key" {}

variable "connect_from" {
  type        = list(string)
  description = "source security group id to allow traffic from"
}

variable "zones" {
  type = list(string)
}

variable "ami_id" {
  default = "ami-0197f82bc4ce1c3fd" // needs to ecs compatible, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
}
