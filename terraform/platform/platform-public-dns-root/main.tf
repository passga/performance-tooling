resource "aws_route53_zone" "public" {
  name = trimsuffix(var.hosted_zone_name, ".")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "app_alias_a" {
  for_each = local.normalized_app_records

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.fqdn
  type    = "A"

  alias {
    name                   = each.value.target_dns_name
    zone_id                = each.value.target_zone_id
    evaluate_target_health = false
  }
}
