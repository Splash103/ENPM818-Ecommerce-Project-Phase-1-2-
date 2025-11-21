# --------------------------------------------------------
# Enforce SSL connections for RDS MySQL
# --------------------------------------------------------

# rds_encryption.tf

# Parameter group that enforces SSL for MySQL 8
resource "aws_db_parameter_group" "mysql_secure" {
  name        = "${var.project_name}-mysql-secure"
  family      = var.rds_engine_family # "mysql8.0"
  description = "Enforce SSL (require_secure_transport=ON)"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  tags = {
    Project = var.project_name
    Owner   = var.owner_tag
  }
}
