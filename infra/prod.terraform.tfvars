project_name = "mock-eks"
environment  = "prod"
aws_region   = "ap-southeast-1"

enabled_modules = {
  networking = true
  ecr        = true
  eks        = true
  rds        = true
  dns_acm    = false
}

networking = {
  vpc_cidr                 = "10.156.0.0/16"
  availability_zones       = ["ap-southeast-1a", "ap-southeast-1b"]
  public_subnet_cidrs      = ["10.156.0.0/24", "10.156.1.0/24"]
  private_app_subnet_cidrs = ["10.156.10.0/24", "10.156.11.0/24"]
  private_db_subnet_cidrs  = ["10.156.20.0/24", "10.156.21.0/24"]
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
    instance_types = ["t3.small"]
    min_size       = 1
    desired_size   = 1
    max_size       = 2
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
  backup_retention_period = 1
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
