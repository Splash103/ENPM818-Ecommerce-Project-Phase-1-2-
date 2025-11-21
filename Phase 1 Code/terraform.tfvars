# --- Region / basic tags ---
aws_region = "us-east-1"

project_name = "enpm818n"
owner_tag    = "ENPM818N-GroupProject" # or "ENPM818N-Team1", if we wanna go based off that"

# --- EC2 SSH key pair ---
key_name = "Secret"

# --- Database settings ---
db_username = "appuser"
db_password = "Ow0_StrongPass!2025"
db_name     = "ecommerce_1"

# --- Networking ---
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# --- Auto Scaling ---
asg_min_size         = 1
asg_desired_capacity = 1
asg_max_size         = 3

# --- RDS Multi-AZ ---
enable_multi_az = false

# --- Domain / SSL setup ---
domain_name    = "enpm818-group1.xyz"
hosted_zone_id = "Z0587302KCJI3CIHZU6O"
