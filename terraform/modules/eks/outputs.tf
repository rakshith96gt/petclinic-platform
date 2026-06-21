output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this[0].name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.this[0].endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)"
  value       = aws_eks_cluster.this[0].certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.this[0].arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = aws_iam_openid_connect_provider.this[0].url
}

output "node_group_name" {
  description = "Managed node group name"
  value       = aws_eks_node_group.this[0].node_group_name
}

output "node_role_arn" {
  description = "Node IAM role ARN"
  value       = aws_iam_role.node_role.arn
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this[0].name}"
}
