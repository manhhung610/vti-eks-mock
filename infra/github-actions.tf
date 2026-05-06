data "aws_caller_identity" "current" {}

locals {
  create_github_actions_app_role = var.environment == "dev" && var.enabled_modules.ecr
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = local.create_github_actions_app_role ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-oidc"
  })
}

data "aws_iam_policy_document" "github_actions_app_assume_role" {
  count = local.create_github_actions_app_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_app_ci" {
  count = local.create_github_actions_app_role ? 1 : 0

  name               = "${local.name_prefix}-github-actions-app-ci"
  assume_role_policy = data.aws_iam_policy_document.github_actions_app_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-app-ci"
  })
}

data "aws_iam_policy_document" "github_actions_app_ci" {
  count = local.create_github_actions_app_role ? 1 : 0

  statement {
    sid = "GetEcrAuthorizationToken"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid = "PushDevApplicationImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.name_prefix}-frontend",
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.name_prefix}-backend"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_app_ci" {
  count = local.create_github_actions_app_role ? 1 : 0

  name   = "${local.name_prefix}-github-actions-app-ci"
  role   = aws_iam_role.github_actions_app_ci[0].id
  policy = data.aws_iam_policy_document.github_actions_app_ci[0].json
}

