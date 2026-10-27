# ── GitHub OIDC provider ──────────────────────────────────────────────────────
# One provider per AWS account. Reuse it across repos; set create_oidc_provider=false
# if it already exists.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC uses a certificate chain anchored by a well-known root CA.
  # AWS validates the chain against its trust store, but a thumbprint is still
  # required by the API; this is GitHub's documented intermediate thumbprint.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"

  repo_prefix = "repo:${var.github_owner}/${var.github_repo}"

  # The ref-based subject GitHub sends for push / workflow_dispatch on a branch.
  ref_subject = var.allowed_ref == "*" ? "${local.repo_prefix}:*" : "${local.repo_prefix}:ref:${var.allowed_ref}"

  # When the job sets `environment:`, GitHub instead sends
  # sub=repo:OWNER/REPO:environment:ENV. Allow it too when configured.
  env_subject = var.github_environment != "" ? ["${local.repo_prefix}:environment:${var.github_environment}"] : []

  subject_claims = concat([local.ref_subject], local.env_subject)
}

# ── Trust policy: only this repo (and ref) may assume the role via OIDC ─────────
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subject_claims
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

# ── Permissions the deploy pipeline needs ───────────────────────────────────────
# Trigger the rollout on the instance via SSM. No ECR, no SSH key in GitHub.
data "aws_iam_policy_document" "deploy" {
  # Trigger the deploy on the instance — no SSH key in GitHub.
  statement {
    sid       = "SsmSendCommand"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = concat(var.deploy_instance_arns, ["arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"])
  }

  # Poll command status / fetch output.
  statement {
    sid    = "SsmReadStatus"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.name}-github-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
