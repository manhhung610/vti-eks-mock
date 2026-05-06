variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment. Supported values: dev, prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either dev or prod."
  }
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

variable "enabled_modules" {
  description = "Feature flags controlling which modules are active for the selected environment."
  type = object({
    networking = bool
    ecr        = bool
    eks        = bool
    rds        = bool
    dns_acm    = bool
  })
}

variable "networking" {
  description = "VPC and subnet configuration."
  type = object({
    vpc_cidr                 = string
    availability_zones       = list(string)
    public_subnet_cidrs      = list(string)
    private_app_subnet_cidrs = list(string)
    private_db_subnet_cidrs  = list(string)
    single_nat_gateway       = bool
  })
}

variable "ecr_repositories" {
  description = "Container repositories to create in ECR."
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
  }))
  default = {}
}

variable "eks" {
  description = "EKS cluster configuration."
  type = object({
    kubernetes_version      = string
    endpoint_public_access  = bool
    endpoint_private_access = bool
    node_group = object({
      instance_types = list(string)
      min_size       = number
      desired_size   = number
      max_size       = number
      disk_size      = number
    })
  })
}

variable "rds" {
  description = "RDS PostgreSQL configuration."
  type = object({
    engine_version          = string
    instance_class          = string
    allocated_storage       = number
    max_allocated_storage   = number
    db_name                 = string
    username                = string
    backup_retention_period = number
    multi_az                = bool
    deletion_protection     = bool
    skip_final_snapshot     = bool
  })
}

variable "rds_password" {
  description = "Master password for the RDS PostgreSQL instance. Provide via TF_VAR_rds_password."
  type        = string
  sensitive   = true
}

variable "dns_acm" {
  description = "Route53 and ACM configuration."
  type = object({
    enabled     = bool
    domain_name = string
    zone_id     = string
  })
}

variable "github_repository" {
  description = "GitHub repository allowed to assume CI IAM roles, in owner/repo format."
  type        = string
  default     = "manhhung610/vti-eks-mock"
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
