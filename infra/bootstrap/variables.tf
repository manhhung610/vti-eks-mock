variable "project_name" {
  description = "Project name used for backend resource names."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the backend resources."
  type        = string
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state."
  type        = string
}

