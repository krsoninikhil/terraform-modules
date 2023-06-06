output "broker_connection_strings" {
  value = {
    tls_iam       = aws_msk_cluster.external_msk.bootstrap_brokers_public_sasl_iam
    tls_scram     = aws_msk_cluster.external_msk.bootstrap_brokers_public_sasl_scram
    plaintext_vpc = aws_msk_cluster.external_msk.bootstrap_brokers
  }
  depends_on = [aws_msk_cluster.external_msk]
}
