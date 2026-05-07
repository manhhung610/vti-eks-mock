output "environment" {
  description = "Selected environment."
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID for the selected environment."
  value       = try(module.networking[0].vpc_id, null)
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = try(module.eks[0].cluster_name, null)
}

output "ecr_repository_urls" {
  description = "ECR repository URLs."
  value       = try(module.ecr[0].repository_urls, {})
}

output "rds_endpoint" {
  description = "RDS endpoint."
  value       = try(module.rds[0].endpoint, null)
  sensitive   = true
}

output "rds_master_user_secret_arn" {
  description = "Secrets Manager secret ARN for the RDS managed master user password."
  value       = try(module.rds[0].master_user_secret_arn, null)
  sensitive   = true
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN."
  value       = try(module.dns_acm[0].certificate_arn, null)
}

output "github_actions_app_ci_role_arn" {
  description = "IAM role ARN used by GitHub Actions to build and push dev application images."
  value       = try(aws_iam_role.github_actions_app_ci[0].arn, null)
}

output "github_actions_terraform_role_arn" {
  description = "IAM role ARN used by GitHub Actions to plan and apply Terraform."
  value       = try(aws_iam_role.github_actions_terraform[0].arn, null)
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN used by AWS Load Balancer Controller service account."
  value       = try(aws_iam_role.aws_load_balancer_controller[0].arn, null)
}
