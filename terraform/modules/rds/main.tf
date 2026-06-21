resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "petclinic/${var.environment}/rds-credentials"
  description = "RDS master credentials for ${var.environment} environment"

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "petclinic"
    password = random_password.rds_password.result
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "petclinic-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_db_parameter_group" "main" {
  name   = "petclinic-${var.environment}-mysql-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_db_instance" "main" {
  identifier           = "petclinic-${var.environment}-mysql"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name              = "petclinic"
  username             = "petclinic"
  password             = random_password.rds_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name    = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  multi_az               = var.multi_az
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection

  tags = merge({
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}
