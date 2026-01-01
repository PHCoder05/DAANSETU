output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_eip.backend.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.backend.id
}

output "api_url" {
  description = "API URL"
  value       = "http://${aws_eip.backend.public_ip}"
}

output "swagger_url" {
  description = "Swagger documentation URL"
  value       = "http://${aws_eip.backend.public_ip}/api-docs"
}

output "ssh_command" {
  description = "SSH command to connect to instance"
  value       = "ssh -i ~/.ssh/daansetu-key.pem ubuntu@${aws_eip.backend.public_ip}"
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.backend.id
}

