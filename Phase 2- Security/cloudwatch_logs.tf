########################################
# CloudWatch Logs for AWS WAF
########################################

data "aws_caller_identity" "current" {}

# Log group name MUST start with aws-waf-logs-
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "aws-waf-logs-enpm818-group1"
  retention_in_days = 14
}

# Allow WAF to write to CloudWatch Logs
resource "aws_cloudwatch_log_resource_policy" "waf_logging_policy" {
  policy_name = "AWS-WAF-Logging-Policy"

  policy_document = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSWAFLoggingPermissions",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "waf.amazonaws.com",
          "waf-regional.amazonaws.com"
        ]
      },
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:aws-waf-logs-enpm818-group1:*"
    }
  ]
}
POLICY
}

# Enable WAF Logging
resource "aws_wafv2_web_acl_logging_configuration" "group1_waf_logging" {
  resource_arn = aws_wafv2_web_acl.group1_waf.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group.arn
  ]

  depends_on = [
    aws_cloudwatch_log_group.waf_log_group,
    aws_cloudwatch_log_resource_policy.waf_logging_policy,
    aws_wafv2_web_acl.group1_waf
  ]
}
