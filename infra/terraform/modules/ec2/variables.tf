variable "name" {
  description = "Name prefix for EC2 resources."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet the instance launches into."
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the instance."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "key_name" {
  description = "Optional EC2 key pair for SSH. Leave empty to rely on SSM Session Manager only."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "app_port" {
  description = "Host port the backend container is published on."
  type        = number
  default     = 8000
}

variable "git_repo_url" {
  description = "HTTPS clone URL the instance pulls source from (public repo; no creds)."
  type        = string
}

variable "git_branch" {
  description = "Branch the instance checks out and deploys."
  type        = string
  default     = "main"
}

variable "ssm_parameter_prefix" {
  description = "SSM Parameter Store path holding the app's runtime env (SecureString params)."
  type        = string
}

variable "tags" {
  description = "Tags applied to EC2 resources."
  type        = map(string)
  default     = {}
}
