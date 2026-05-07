module "networking" {
  source = "./modules/networking"
  count  = var.enabled_modules.networking ? 1 : 0

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.networking.vpc_cidr
  availability_zones       = var.networking.availability_zones
  public_subnet_cidrs      = var.networking.public_subnet_cidrs
  private_app_subnet_cidrs = var.networking.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.networking.private_db_subnet_cidrs
  single_nat_gateway       = var.networking.single_nat_gateway
  tags                     = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"
  count  = var.enabled_modules.ecr ? 1 : 0

  name_prefix  = local.name_prefix
  repositories = var.ecr_repositories
  tags         = local.common_tags
}

module "eks" {
  source = "./modules/eks"
  count  = var.enabled_modules.eks ? 1 : 0

  name_prefix             = local.name_prefix
  kubernetes_version      = var.eks.kubernetes_version
  endpoint_public_access  = var.eks.endpoint_public_access
  endpoint_private_access = var.eks.endpoint_private_access
  vpc_id                  = module.networking[0].vpc_id
  subnet_ids              = module.networking[0].private_app_subnet_ids
  node_group              = var.eks.node_group
  tags                    = local.common_tags

  depends_on = [module.networking]
}

module "rds" {
  source = "./modules/rds"
  count  = var.enabled_modules.rds ? 1 : 0

  name_prefix                 = local.name_prefix
  vpc_id                      = module.networking[0].vpc_id
  subnet_ids                  = module.networking[0].private_db_subnet_ids
  app_security_group_ids      = module.eks[0].node_security_group_ids
  engine_version              = var.rds.engine_version
  instance_class              = var.rds.instance_class
  allocated_storage           = var.rds.allocated_storage
  max_allocated_storage       = var.rds.max_allocated_storage
  db_name                     = var.rds.db_name
  username                    = var.rds.username
  manage_master_user_password = var.rds.manage_master_user_password
  password                    = var.rds.manage_master_user_password ? null : var.rds_password
  backup_retention_period     = var.rds.backup_retention_period
  multi_az                    = var.rds.multi_az
  deletion_protection         = var.rds.deletion_protection
  skip_final_snapshot         = var.rds.skip_final_snapshot
  tags                        = local.common_tags

  depends_on = [module.networking, module.eks]
}

module "dns_acm" {
  source = "./modules/dns-acm"
  count  = var.enabled_modules.dns_acm && var.dns_acm.enabled ? 1 : 0

  name_prefix = local.name_prefix
  domain_name = var.dns_acm.domain_name
  zone_id     = var.dns_acm.zone_id
  tags        = local.common_tags
}
