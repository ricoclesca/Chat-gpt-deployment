output "web_instance_public_ip" {
  description = "The public IP address of the web instance"
  value       = aws_instance.web.public_ip
}
output "web_instance_private_ip" {
  description = "The private IP address of the web instance"
  value       = aws_instance.web.private_ip
}
output "web2_instance_public_ip" {
  description = "The public IP address of the web2 instance"
  value       = aws_instance.web2.public_ip
}
output "web2_instance_private_ip" {
  description = "The private IP address of the web2 instance"
  value       = aws_instance.web2.private_ip
}