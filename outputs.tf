output "transfer_hostname" {
  description = "AWS Transfer Server hostname"
  value       = aws_transfer_server.test.endpoint
}

output "transfer_user" {
  description = "AWS Transfer Server user"
  value       = aws_transfer_user.transfer_user.user_name
}
