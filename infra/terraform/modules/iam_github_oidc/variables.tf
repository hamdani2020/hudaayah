variable "name" {
  description = "Name prefix for IAM resources."
  type        = string
}

variable "github_owner" {
  description = "GitHub org/user that owns the repo (e.g. hamdani2020)."
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub account ID of the owner. With GitHub's immutable OIDC, the token sub is repo:OWNER@OWNER_ID/REPO@REPO_ID:... Find it in the decoded token sub, or GET https://api.github.com/users/<owner> (field `id`)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (e.g. hudaayah)."
  type        = string
}

variable "github_repo_id" {
  description = "Immutable numeric GitHub repository ID. From the decoded token sub, or GET https://api.github.com/repos/<owner>/<repo> (field `id`)."
  type        = string
}

variable "allowed_ref" {
  description = "Git ref the deploy role may be assumed from (e.g. refs/heads/main). '*' allows any ref in the repo."
  type        = string
  default     = "refs/heads/main"
}

variable "github_environment" {
  description = "GitHub Actions environment used by the deploy job. When set, GitHub issues OIDC tokens with sub=repo:OWNER/REPO:environment:ENV, so the trust policy must allow it. Empty = no environment claim allowed."
  type        = string
  default     = ""
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
