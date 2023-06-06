resource "aws_msk_cluster" "external_msk" {
  cluster_name           = var.name
  kafka_version          = "3.3.2"
  number_of_broker_nodes = var.no_of_nodes

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = local.subnet_ids
    security_groups = [aws_security_group.msk.id]
    storage_info {
      ebs_storage_info {
        volume_size = var.volume_size
      }
    }
    connectivity_info {
      public_access {
        type = var.make_public ? "SERVICE_PROVIDED_EIPS" : "DISABLED" # msk doesn't allow public access during creation
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.config.arn
    revision = aws_msk_configuration.config.latest_revision
  }

  client_authentication {
    sasl {
      scram = true
      iam   = true
    }
    tls {}
    unauthenticated = !var.make_public
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.make_public ? "TLS" : "TLS_PLAINTEXT" # cannot be plaintext if public
    }
  }
}

resource "aws_security_group" "msk" {
  name   = "${var.name}-msk"
  vpc_id = var.vpc_id

  ingress {
    from_port        = 9196
    to_port          = 9196
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "For SCRAM auth"
  }

  ingress {
    from_port        = 9198
    to_port          = 9198
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "For IAM auth"
  }

  ingress {
    from_port        = 9092
    to_port          = 9092
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "For VPC Plaintext"
  }

  ingress {
    from_port        = 9098
    to_port          = 9098
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "For IAM on VPC"
  }
}

resource "aws_cloudwatch_log_group" "msk" {
  name = "msk/brokers/${var.name}"
}

resource "aws_msk_configuration" "config" {
  name              = var.name
  server_properties = <<EOF
min.insync.replicas=1
num.io.threads=8
num.network.threads=5
num.partitions=1
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
allow.everyone.if.no.acl.found=false
auto.create.topics.enable=true
default.replication.factor=2
EOF

}
