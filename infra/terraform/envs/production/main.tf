provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  name       = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id

  # Runtime secrets for the backend live under this SSM path as SecureString
  # params (DJANGO_SECRET_KEY, POSTGRES_*, QF_*, GOOGLE_CLIENT_IDS, ...).
  # Populate them out-of-band — see envs/production/README-SSM.md.
  ssm_parameter_prefix = "/${var.project}/${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
  }
}

module "network" {
  source = "../../modules/network"

  name = local.name
  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name              = local.name
  vpc_id            = module.network.vpc_id
  ssh_ingress_cidrs = var.ssh_ingress_cidrs
  app_ingress_cidrs = var.app_ingress_cidrs
  tags              = local.common_tags
}

module "ec2" {
  source = "../../modules/ec2"

  name                 = local.name
  subnet_id            = module.network.public_subnet_id
  security_group_ids   = [module.security.security_group_id]
  instance_type        = var.instance_type
  key_name             = var.key_name
  aws_region           = var.aws_region
  app_port             = var.app_port
  git_repo_url         = var.git_repo_url
  git_branch           = var.github_branch
  ssm_parameter_prefix = local.ssm_parameter_prefix
  tags                 = local.common_tags
}

module "github_oidc" {
  source = "../../modules/iam_github_oidc"

  name                 = local.name
  github_owner         = var.github_owner
  github_owner_id      = var.github_owner_id
  github_repo          = var.github_repo
  github_repo_id       = var.github_repo_id
  allowed_ref          = var.github_allowed_ref
  github_environment   = var.github_environment
  create_oidc_provider = var.create_oidc_provider
  deploy_instance_arns = [module.ec2.instance_arn]
  aws_region           = var.aws_region
  account_id           = local.account_id
  tags                 = local.common_tags
}
