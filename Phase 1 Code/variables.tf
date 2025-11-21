variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for resource names"
  type        = string
  default     = "enpm818n"
}

variable "owner_tag" {
  description = "Owner tag to help identify resources"
  type        = string
  default     = "student"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must be at least 2 for ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must be at least 2 for ASG/RDS)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to access the ALB over HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "db_username" {
  description = "Username for the RDS MySQL instance"
  type        = string
  sensitive   = true
  default     = "appuser"
}

variable "db_password" {
  description = "Password for the RDS MySQL instance"
  type        = string
  sensitive   = true
  default     = "ChangeMeStrong!123"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name to create on RDS (should match ecommerce_1.sql)"
  type        = string
  default     = "ecommerce_1"
}

variable "enable_multi_az" {
  description = "Enable Multi-AZ deployment for RDS (set true for final submission)"
  type        = bool
  default     = false
}

variable "github_repo_url" {
  description = "Git repository URL for the ENPM818N E-Commerce application"
  type        = string
  default     = "https://github.com/edaviage/818N-E_Commerce_Application.git"
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair to allow SSH access"
  type        = string
}

# -------------------------------
# Phase 2 (Security Integration)
# -------------------------------

variable "domain_name" {
  description = "Domain name for HTTPS certificate"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for domain validation"
}

variable "rds_engine_family" {
  description = "RDS parameter group family for SSL enforcement"
  default     = "mysql8.0"
}

# Optional passthroughs if Phase 2 is a separate module
#variable "alb_arn" {}
#variable "target_group_arn" {}

