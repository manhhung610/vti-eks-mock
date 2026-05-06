project_name = "mock-eks"
environment  = "dev"
aws_region   = "ap-southeast-1"

enabled_modules = {
  networking = true
  ecr        = true
  eks        = true
  rds        = true
  dns_acm    = false
}

networking = {
  vpc_cidr                 = "10.155.0.0/16"
  availability_zones       = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnet_cidrs      = ["10.155.0.0/24", "10.155.1.0/24"]
  private_app_subnet_cidrs = ["10.155.10.0/24", "10.155.11.0/24"]
  private_db_subnet_cidrs  = ["10.155.20.0/24", "10.155.21.0/24"]
  single_nat_gateway       = true
}

ecr_repositories = {
  frontend = {}
  backend  = {}
}

eks = {
  kubernetes_version      = "1.35"
  endpoint_public_access  = true
  endpoint_private_access = true
  node_group = {
    instance_types = ["t3.medium"]
    min_size       = 1
    desired_size   = 2
    max_size       = 3
    disk_size      = 20
  }
}

rds = {
  engine_version          = "17.6"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 20
  db_name                 = "mockapp"
  username                = "mockapp"
  backup_retention_period = 0
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
}

dns_acm = {
  enabled     = false
  domain_name = ""
  zone_id     = ""
}

tags = {
  CostCenter = "mock-project"
}
