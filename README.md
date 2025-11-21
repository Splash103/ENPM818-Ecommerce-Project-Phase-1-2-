# ENPM818N – E-Commerce Application (Phase 1 & Phase 2)

This repository contains an e-commerce web application deployed on AWS as part of the ENPM818N Cloud Engineering course project.

This README explains the **Phase 1 (Networking & Compute)** and **Phase 2 (Database & SSL)** portions of the implementation: what we built, how it fits together, and how to validate that it’s working.

---

## High-Level Architecture

The application is a classic 3-tier web architecture:

- **Presentation / Web Tier**
  - Application Load Balancer (ALB) in **public subnets**.
  - Auto Scaling Group (ASG) of **EC2 web servers** in **private app subnets**.
  - Apache + PHP serving this repository’s PHP code.

- **Database Tier**
  - **Amazon RDS for MySQL**, Multi-AZ, with **KMS encryption at rest**.
  - RDS in **private DB subnets**, not directly accessible from the internet.
  - EC2 ↔ RDS communication over **port 3306** locked down by Security Groups.
  - **SSL/TLS** enabled on the PHP → RDS connection via `connect.php`.

- **Networking**
  - Custom **VPC** spanning two Availability Zones.
  - Public subnets for ALB / NAT, private subnets for EC2, private DB subnets for RDS.
  - **Internet Gateway (IGW)** for outbound internet from public subnets.
  - **NAT Gateway** so private EC2 instances can reach the internet (e.g., `apt`, `git`).

---

## Phase 1 – Networking & Compute

### 1. Custom VPC and Subnets

**Goal:** Isolate the environment and support a proper multi-tier layout.

We created a **custom VPC** (e.g., `10.0.0.0/16`) with:

- **Public Subnets** (one per AZ)
  - Hosts:
    - Application Load Balancer
    - NAT Gateway
  - Route table:
    - Default route `0.0.0.0/0` → **Internet Gateway**

- **Private App Subnets** (one per AZ)
  - Hosts:
    - EC2 instances managed by an Auto Scaling Group (web/app servers)
  - Route table:
    - Default route `0.0.0.0/0` → **NAT Gateway**
    - No direct route to IGW

This separation lets us keep application servers off the public internet while still allowing them to reach OS/package repositories through the NAT.

---

### 2. Internet Access: IGW and NAT

- **Internet Gateway (IGW)** is attached to the VPC and used by public subnets.
- **NAT Gateway** sits in one public subnet and is used by the **private app subnets**:
  - EC2 instances can:
    - Run `apt update`, install Apache/PHP.
    - Clone this GitHub repo.
  - But they remain inaccessible from the internet except through the ALB.

---

### 3. Application Load Balancer (ALB)

**Purpose:** Front-end entry point for all HTTP/HTTPS traffic.

- ALB is deployed in **both public subnets**, providing:
  - High availability across multiple AZs.
  - A single DNS endpoint for users/evaluators.

- **Listeners & target groups:**
  - HTTP (80) and/or HTTPS (443) listeners.
  - Target group of **EC2 instances** (private subnets) on port 80.
  - Health checks configured (e.g., `/healthcheck.php` or `/index.php`):
    - We had to align the **health check path** and Apache DocumentRoot correctly so ALB would mark targets as **healthy**.
    - Misalignment here earlier caused targets to be seen as unhealthy even though Apache was running.

---

### 4. Auto Scaling Group & Launch Template

**Goal:** Ensure the application scales and recovers automatically.

- **Launch Template** defines:
  - AMI (Ubuntu Server).
  - Instance type (e.g., `t3.micro`).
  - Security Group(s).
  - **User Data script** that:
    - Installs Apache, PHP, and required extensions.
    - Clones the e-commerce repo from GitHub.
    - Copies files into `/var/www/html`.
    - Enables and starts Apache, sets correct permissions.

- **Auto Scaling Group (ASG):**
  - Spans the **private app subnets** in two AZs.
  - Uses the ALB target group for health checks.
  - Parameters:
    - Minimum capacity (e.g., 1).
    - Desired capacity (e.g., 1–2).
    - Maximum capacity (e.g., 3).
  - Integrated with **CloudWatch alarms** (later phases) so CPU or latency alarms can trigger scaling events.

**Key challenge in Phase 1:**  
At one point, misconfigured ALB/ASG settings and/or Terraform caused **hundreds of EC2 instances** to spin up. This was fixed by:

- Correcting the ASG and scaling policies.
- Ensuring healthy ALB targets and proper health check paths.
- Cleaning up orphaned resources and locking down Terraform state.

---

### 5. EC2 Web Server Configuration

On first boot, each EC2 instance:

1. Runs the **user data script**.
2. Installs:
   - `apache2`
   - `php` / `libapache2-mod-php`
   - Required PHP extensions (e.g., `php-mysql`).
3. Clones this repository and places files into `/var/www/html`.
4. Enables the site and starts/restarts Apache.

Because this is automated via ASG + Launch Template, we can fully rebuild the web tier by simply terminating instances; new instances come up pre-configured.

---

### 6. Security Groups (Phase 1)

**ALB Security Group:**

- Inbound:
  - `80` (HTTP) and/or `443` (HTTPS) from `0.0.0.0/0`.
- Outbound:
  - To EC2 Security Group on port `80`.

**EC2 Security Group:**

- Inbound:
  - `80` from the ALB Security Group only.
- Optional: `22` from a bastion host or specific admin IP (if used).
- Outbound:
  - Unrestricted or limited to what’s needed (e.g., NAT → internet).

This ensures:

- End users never talk directly to EC2.
- All public access is funneled through the ALB.

---

## Phase 2 – Database & SSL Integration

Phase 2 focuses on building a secure **database tier** and integrating the PHP application with **RDS over SSL**.

### 1. RDS MySQL – Multi-AZ + KMS Encryption

We created an **Amazon RDS for MySQL** instance with:

- **Multi-AZ deployment**:
  - Primary DB in one AZ.
  - Standby in a second AZ.
  - Automatic failover if the primary goes down.
- **KMS encryption at rest**:
  - Data, logs, and snapshots are encrypted using an AWS KMS CMK.
- **DB Subnet Group**:
  - Uses **private DB subnets** across at least two AZs.
- **RDS Security Group**:
  - Inbound: `3306` only from the **EC2 Security Group**.
  - No public access.

This delivers a resilient and encrypted database layer fully isolated from the public internet.

---

### 2. Loading the E-Commerce Schema and Seed Data

The repository contains the schema and seed data file:

- `Database/ecommerce_1.sql`

From the EC2 instance, after RDS is up:

```bash
mysql -h <RDS_ENDPOINT> \
  -u appuser -p ecommerce_1 \
  < Database/ecommerce_1.sql
