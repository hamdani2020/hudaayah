variable "name" {
  description = "Name prefix for IAM resources."
  type        = string
}

variable "github_owner" {
  description = "GitHub org/user that owns the repo (e.g. hamdani2020)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. hudaayah)."
  type        = string
}

variable "allowed_ref" {
  description = "Git ref the deploy role may be assumed from (e.g. refs/heads/main). '*' allows any ref in the repo."
  type        = string
  default     = "refs/heads/main"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if token.actions.githubusercontent.com already exists in the account."
  type        = bool
  default     = true
}

variable "deploy_instance_arns" {
  description = "ARNs of EC2 instances the deploy role may target via SSM SendCommand."
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region (used to scope SSM document ARNs)."
  type        = string
}

variable "account_id" {
  description = "AWS account ID (used to scope SSM document ARNs)."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
