output "instance_ip" {
  value = {
    (var.name) = length(aws_eip.instance_eip) > 0 ? aws_eip.instance_eip[0].public_ip : null
  }
}