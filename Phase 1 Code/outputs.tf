output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "db_endpoint" {
  description = "Endpoint of the RDS MySQL instance"
  value       = aws_db_instance.app_db.address
}

output "db_name" {
  description = "Database name created on the RDS instance"
  value       = aws_db_instance.app_db.db_name
}

# -------------------------------
# Phase 2 Outputs
# -------------------------------
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app_lb.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group attached to the ALB"
  value       = aws_lb_target_group.app_tg.arn
}

output "rds_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.app_db.identifier
}

output "certificate_arn" {
  description = "ARN of the ACM SSL certificate once issued"
  value       = try(aws_acm_certificate_validation.group1_cert_validation_complete.certificate_arn, null)
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = try(aws_lb_listener.https_listener.arn, null)
}

output "waf_arn" {
  description = "ARN of the WAF Web ACL protecting the ALB"
  value       = try(aws_wafv2_web_acl.group1_waf.arn, null)
}

output "waf_log_group" {
  description = "Name of the CloudWatch log group for WAF logs"
  value       = try(aws_cloudwatch_log_group.waf_log_group.name, null)
}