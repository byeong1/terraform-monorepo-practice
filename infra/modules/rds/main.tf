# DB 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS MySQL 인스턴스
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  multi_az            = false
  skip_final_snapshot = true
  backup_retention_period = 0
  monitoring_interval     = 0
  storage_encrypted       = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
