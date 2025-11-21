# ------------------------------------------------
# AWS Certificate Manager - SSL/TLS Certificate
# ------------------------------------------------

resource "aws_acm_certificate" "group1_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }
}

resource "aws_route53_record" "group1_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.group1_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
  
  #prevent destroy
  lifecycle {                           
    prevent_destroy = true
  }
}

resource "aws_acm_certificate_validation" "group1_cert_validation_complete" {
  certificate_arn         = aws_acm_certificate.group1_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.group1_cert_validation : record.fqdn]
}
