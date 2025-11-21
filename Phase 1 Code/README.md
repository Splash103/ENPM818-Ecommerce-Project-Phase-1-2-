# ENPM818N Phase 1 – Terraform (Clean Version)

This Terraform project builds **Phase 1** of the ENPM818N Scalable & Secure E‑Commerce Platform on AWS and automatically deploys the GitHub application:

- GitHub repo: `https://github.com/edaviage/818N-E_Commerce_Application`
- Web tier: Ubuntu + Apache2 + PHP + app cloned in **user_data**
- DB tier: Amazon RDS MySQL
- Networking: Custom VPC, public + private subnets, NAT, ALB, ASG
- Security: IMDSv2 enforced, security groups only allowing necessary flows
- Scaling: Target-tracking CPU policy (CloudWatch alarms are created automatically by AWS)

## What this fixes compared to the old setup

- Eliminates 502 Bad Gateway by:
  - Putting EC2 instances in private subnets with a NAT gateway
  - Using an ALB target group with a dedicated `/healthcheck.php` endpoint
  - Making sure Apache + PHP + app are installed and running via **user_data**
- Deploys the **exact ENPM818N GitHub app** on every EC2 instance
- Enforces **IMDSv2** on the launch template
- Adds an RDS MySQL instance with encryption and proper security groups
- Makes Multi‑AZ configurable with a variable (default = `false` so you can test cheaply)

When you are ready for your final submission, just set:

```hcl
enable_multi_az = true
```

in `terraform.tfvars` (or via `-var enable_multi_az=true`) and re‑apply.

## Files

- `versions.tf` – Terraform & provider requirements
- `provider.tf` – AWS provider config + default tags
- `variables.tf` – All tunables (region, CIDRs, ASG sizes, DB settings, key pair, etc.)
- `main.tf` – VPC, subnets, NAT, ALB, ASG, Launch Template, RDS, scaling policy
- `outputs.tf` – ALB DNS name and DB endpoint
- `user_data.sh.tpl` – Startup script that installs Apache/PHP, clones the GitHub repo, and fixes `includes/connect.php`

## How user_data matches the ENPM818N manual steps

The manual document says to:

1. Update the EC2 instance
2. Install Apache2
3. Start Apache2 and verify with the public IP
4. Install PHP + `libapache2-mod-php` + `php-mysql`
5. Edit `dir.conf` so `index.php` is first
6. Remove default `/var/www/html/index.html`
7. Move the project files into `/var/www/html`
8. Create a database `ecommerce_1`
9. Update `includes/connect.php` with the RDS connection details
10. Browse to `http://<public-ip>/index.php` to test

The **user_data script** in `user_data.sh.tpl` automates steps **1–7 and 9**:

- `apt-get update` and package installs (`apache2`, `php`, `libapache2-mod-php`, `php-mysql`, `git`, `rsync`)
- Starts and enables the Apache2 service
- Edits `/etc/apache2/mods-enabled/dir.conf` so `index.php` comes first
- Deletes the default `/var/www/html/index.html`
- Clones `https://github.com/edaviage/818N-E_Commerce_Application.git` into `/tmp/ecommerce_app`
- Rsyncs everything into `/var/www/html`
- Creates `/var/www/html/healthcheck.php` for the ALB
- Overwrites `/var/www/html/includes/connect.php` so it uses the **RDS endpoint, username, password, and DB name** provided by Terraform

You still need to import the database schema using the provided SQL file.

## How to use

1. **Create / choose an EC2 key pair** in your AWS account (for SSH).
2. In this folder, create `terraform.tfvars` with at least:

```hcl
aws_region  = "us-east-1"
key_name    = "YOUR_KEYPAIR_NAME"
db_username = "appuser"
db_password = "A_Strong_Password_123!"
```

(You can also override VPC subnets, instance type, etc. if needed.)

3. Initialize and deploy:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

4. After apply completes, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Paste that DNS name into your browser (HTTP, port 80). You should see the ENPM818N e‑commerce site instead of a 502 error.

## Database setup (matches assignment)

1. Get the DB endpoint:

```bash
terraform output db_endpoint
terraform output db_name
```

2. Using MySQL Workbench (or CLI), connect to the RDS instance with:

- Host: `db_endpoint` output
- Port: `3306`
- User: `db_username` you set in `terraform.tfvars`
- Password: `db_password` you set in `terraform.tfvars`

3. Confirm that database `ecommerce_1` already exists (Terraform creates it).
4. From the GitHub repo (`Database/ecommerce_1.sql`), run the SQL script against that DB.
5. Reload the ALB DNS URL in your browser – the app should now show products instead of DB errors.

## Notes for security & grading

- **IMDSv2** is enforced in the launch template via `metadata_options { http_tokens = "required" }`.
- EC2 instances live in **private subnets** and reach the internet via a **NAT gateway**.
- The ALB is in **public subnets** and only exposes port 80 (you can add ACM/HTTPS later).
- RDS is **not publicly accessible** and only allows MySQL from the EC2 security group.
- **Multi‑AZ** is controlled by `enable_multi_az`. Keep it `false` while testing to save cost, then set to `true` before your final run/screenshot if your rubric explicitly requires Multi‑AZ.

This should give you a clean, reproducible Phase 1 deployment that avoids the earlier 502 issues and lines up with the ENPM818N assignment.
