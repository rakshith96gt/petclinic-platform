locals {
  cluster_name = "petclinic-${var.environment}"
}

# --- Cluster IAM Role ---
resource "aws_iam_role" "cluster_role" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "this" {
  count    = 1
  name     = local.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids       = [var.cluster_sg_id]
    endpoint_public_access   = true
    endpoint_private_access  = true
    public_access_cidrs     = var.cluster_public_access_cidrs
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = merge(var.tags, {
    Name = local.cluster_name
  })
}

# --- OIDC Provider for IRSA ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this[0].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = 1
  url   = aws_eks_cluster.this[0].identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

# --- Node IAM Role ---
resource "aws_iam_role" "node_role" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-node-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# --- Managed Node Group ---
resource "aws_eks_node_group" "this" {
  count = 1
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types
  ami_type       = var.node_ami_type
  disk_size      = var.node_disk_size
  remote_access {
    ec2_ssh_key = null # No SSH access by default for security
  }

  labels = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
  ]
}

# --- Kubectl Access Configuration ---
resource "aws_eks_access_entry" "deployer" {
  count       = 1
  cluster_name = aws_eks_cluster.this[0].name
  principal_arn = var.deployer_arn
  type         = "STANDARD"
}

resource "aws_eks_access_policy_association" "deployer_admin" {
  count        = 1
  cluster_name = aws_eks_cluster.this[0].name
  principal_arn = var.deployer_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# --- EKS Managed Add-ons ---
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  count            = 1
  cluster_name     = aws_eks_cluster.this[0].name
  addon_name       = "vpc-cni"
  addon_version    = data.aws_eks_addon_version.vpc_cni.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  count            = 1
  cluster_name     = aws_eks_cluster.this[0].name
  addon_name       = "kube-proxy"
  addon_version    = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  count            = 1
  cluster_name     = aws_eks_cluster.this[0].name
  addon_name       = "coredns"
  addon_version    = data.aws_eks_addon_version.coredns.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# --- EBS CSI Driver & IRSA ---
resource "aws_iam_role" "ebs_csi_role" {
  name = "${local.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.this[0].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.this[0].url}:sub" = "system:serviceaccount:kube-system/ebs-csi-controller-sa"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-ebs-csi-role"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count            = 1
  cluster_name     = aws_eks_cluster.this[0].name
  addon_name       = "aws-ebs-csi-driver"
  addon_version    = data.aws_eks_addon_version.ebs_csi.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}

