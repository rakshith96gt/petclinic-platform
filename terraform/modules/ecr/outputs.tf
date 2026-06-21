output "repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = { for s in var.service_names : s => aws_ecr_repository.this[s].repository_url }
}

output "repository_arns" {
  description = "Map of service name to ECR repository ARN"
  value       = { for s in var.service_names : s => aws_ecr_repository.this[s].arn }
}
