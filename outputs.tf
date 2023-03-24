output "transfer_hostname" {
  description = "AWS Transfer Server hostname"
  value       = aws_transfer_server.test.endpoint
}
