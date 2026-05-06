locals {
  owner_code  = "hungnm-de000155"
  name_prefix = "${local.owner_code}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = local.owner_code
      Terraform   = "true"
    }
  )
}
