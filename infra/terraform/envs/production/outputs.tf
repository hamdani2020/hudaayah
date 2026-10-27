# Paste these into the GitHub Actions workflow env block (.github/workflows/deploy.yml).

output "aws_region" {
  description = "AWS region."
  value       = var.aws_region
}

output "deploy_role_arn" {
  description = "IAM role ARN GitHub Actions assumes via OIDC (AWS_ROLE_ARN)."
  value       = module.github_oidc.deploy_role_arn
}

output "ec2_instance_id" {
  description = "EC2 instance ID (SSM deploy target)."
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the backend instance."
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the backend instance."
  value       = module.ec2.public_dns
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store path to populate with the app's runtime secrets."
  value       = local.ssm_parameter_prefix
}
