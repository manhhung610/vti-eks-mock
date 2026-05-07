locals {
  create_aws_load_balancer_controller_irsa = var.environment == "dev" && var.enabled_modules.eks
  eks_oidc_provider_url_without_scheme     = local.create_aws_load_balancer_controller_irsa ? replace(module.eks[0].oidc_provider_url, "https://", "") : ""
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  count = local.create_aws_load_balancer_controller_irsa ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks[0].oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_url_without_scheme}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_provider_url_without_scheme}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = local.create_aws_load_balancer_controller_irsa ? 1 : 0

  name        = "${local.name_prefix}-aws-load-balancer-controller"
  description = "IAM permissions for AWS Load Balancer Controller in ${local.name_prefix}."
  policy      = file("${path.module}/../aws-load-balancer-controller-iam-policy.json")

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller"
  })
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  count = local.create_aws_load_balancer_controller_irsa ? 1 : 0

  name               = "${local.name_prefix}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller"
  })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = local.create_aws_load_balancer_controller_irsa ? 1 : 0

  role       = aws_iam_role.aws_load_balancer_controller[0].name
  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
}
