resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow PostgreSQL from EKS workloads"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_app" {
  for_each = {
    for index, security_group_id in var.app_security_group_ids : index => security_group_id
  }

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-from-app"
  })
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-egress"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnets"
  })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-postgres-params"
  family = "postgres${split(".", var.engine_version)[0]}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-params"
  })
}

resource "random_password" "master" {
  count = var.manage_master_user_password || var.password != null ? 0 : 1

  length  = 24
  special = false
}

locals {
  generated_password = try(random_password.master[0].result, null)
}

resource "aws_db_instance" "this" {
  identifier                  = "${var.name_prefix}-postgres"
  engine                      = "postgres"
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  db_name                     = var.db_name
  username                    = var.username
  password                    = var.manage_master_user_password ? null : coalesce(var.password, local.generated_password)
  manage_master_user_password = var.manage_master_user_password ? true : null
  port                        = 5432
  db_subnet_group_name        = aws_db_subnet_group.this.name
  parameter_group_name        = aws_db_parameter_group.this.name
  vpc_security_group_ids      = [aws_security_group.this.id]
  backup_retention_period     = var.backup_retention_period
  multi_az                    = var.multi_az
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  publicly_accessible         = false
  storage_encrypted           = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
