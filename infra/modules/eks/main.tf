data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name_prefix}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ])

  role       = aws_iam_role.cluster.name
  policy_arn = each.value
}

resource "aws_iam_role" "node" {
  name               = "${var.name_prefix}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks"
  })

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-oidc"
  })
}

resource "aws_eks_addon" "this" {
  for_each = toset([
    "vpc-cni",
    "kube-proxy",
    "coredns",
    "eks-pod-identity-agent"
  ])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value}"
  })

  depends_on = [aws_eks_node_group.baseline]
}

resource "aws_eks_node_group" "baseline" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-baseline"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_group.instance_types
  disk_size       = var.node_group.disk_size

  scaling_config {
    min_size     = var.node_group.min_size
    desired_size = var.node_group.desired_size
    max_size     = var.node_group.max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "baseline"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-baseline"
  })

  depends_on = [aws_iam_role_policy_attachment.node]
}
