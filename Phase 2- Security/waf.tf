########################################
# AWS WAF Web ACL (Common + SQLi/XSS + Admin Protection)
########################################

resource "aws_wafv2_web_acl" "group1_waf" {
  name        = "group1-waf-final"
  scope       = "REGIONAL" # For ALB, not CLOUDFRONT
  description = "WAF for ALB protecting against common exploits, SQLi, and XSS attacks"

  default_action {
    allow {}
  }

  # --- Common Protection (includes SQLi + XSS) ---
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # --- Known Bad Inputs (extra layer) ---
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # --- Admin Page Protection (optional but useful) ---
  rule {
    name     = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AdminProtectionRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # --- General visibility for the Web ACL ---
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "group1-waf"
    sampled_requests_enabled   = true
  }

  #prevent destroy
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_lb.app_lb,
    aws_cloudwatch_log_group.waf_log_group
  ]
}

########################################
# Associate WAF with ALB
########################################

resource "aws_wafv2_web_acl_association" "group1_waf_association" {
  resource_arn = aws_lb.app_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.group1_waf.arn

  #prevent destroy
  lifecycle {
    prevent_destroy = true
  }
}

########################################
# WAF Logging (to CloudWatch)
########################################

