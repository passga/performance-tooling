variable "aws_region" {
  type        = string
  description = "Dedicated AWS region for platform-public-dns-root. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "hosted_zone_name" {
  type        = string
  description = "Delegated public Route53 hosted zone name to keep persistent for downstream applications."
  default     = "infra.garciapass.fr"
}

variable "app_records" {
  description = "Alias A records to manage in the delegated hosted zone."
  type = map(object({
    fqdn            = string
    target_dns_name = string
    target_zone_id  = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.app_records) : (
        trimsuffix(record.fqdn, ".") == trimsuffix(var.hosted_zone_name, ".") ||
        endswith(
          trimsuffix(record.fqdn, "."),
          ".${trimsuffix(var.hosted_zone_name, ".")}"
        )
      )
    ])
    error_message = "Every app_records.fqdn value must stay within hosted_zone_name."
  }
}
