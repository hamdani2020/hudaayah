output "instance_id" {
  description = "ID of the EC2 instance (SSM deploy target)."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "public_ip" {
  description = "Public IP of the instance."
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance."
  value       = aws_instance.this.public_dns
}

output "instance_role_arn" {
  description = "ARN of the instance IAM role."
  value       = aws_iam_role.instance.arn
}
