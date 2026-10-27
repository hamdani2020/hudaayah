variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix for all resources."
  type        = string
  default     = "hudaayah"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
}

variable "app_port" {
  description = "Host port the backend container is published on."
  type        = number
  default     = 80
}

# ── GitHub OIDC ────────────────────────────────────────────────────────────────
variable "github_owner" {
  description = "GitHub org/user that owns the repo."
  type        = string
  default     = "hamdani2020"
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "hudaayah"
}

variable "github_branch" {
  description = "Branch the instance checks out and deploys."
  type        = string
  default     = "main"
}

variable "git_repo_url" {
  description = "HTTPS clone URL the instance pulls source from (public repo; no creds)."
  type        = string
  default     = "https://github.com/hamdani2020/hudaayah.git"
}

variable "github_allowed_ref" {
  description = "Git ref allowed to deploy (e.g. refs/heads/main)."
  type        = string
  default     = "refs/heads/main"
}

variable "github_environment" {
  description = "GitHub Actions environment the deploy job uses. Must match `environment:` in deploy.yml so the OIDC trust policy allows the environment subject claim. Set empty if the job has no environment."
  type        = string
  default     = "production"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider (false if it already exists in the account)."
  type        = bool
  default     = true
}

# ── Access control ───────────────────────────────────────────────────────────
variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH. Empty = SSH closed (use SSM Session Manager)."
  type        = list(string)
  default     = []
}

variable "app_ingress_cidrs" {
  description = "CIDRs allowed to reach the Django app port (8000). Empty = closed."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH."
  type        = string
  default     = ""
}
