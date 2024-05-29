resource "aws_security_group" "ecs_sg" {
  name        = "${var.cluster_name}-ecs"
  description = "for ecs cluster instance"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.cluster_name}-ecs" }
  # ingress = [] # remove any rules added externally

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_in" {
  count = length(var.connect_from)

  security_group_id            = aws_security_group.ecs_sg.id
  from_port                    = 1
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.connect_from[count.index]
}

# add ingres from bastian

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_iam_role" "instance_role" {
  name        = "${var.cluster_name}-ecs"
  description = "allows cluster instance to register as ecs container instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
  ]
}

# takes time create, resource using it might fail the first time
# ref: https://stackoverflow.com/a/66719677/3504244
resource "aws_iam_instance_profile" "iam_profile" {
  name = "${var.cluster_name}-ecs"
  role = aws_iam_role.instance_role.name
}

# create keys https://stackoverflow.com/questions/49743220/how-do-i-create-an-ssh-key-in-terraform
resource "aws_key_pair" "instance_key" {
  key_name   = "${var.cluster_name}-ecs"
  public_key = var.ssh_public_key
}