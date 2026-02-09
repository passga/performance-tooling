locals {

  le_env  = var.letsencrypt_environment
  le_name = "letsencrypt-${local.le_env}"

  le_server_url = (
    local.le_env == "production"
    ? "https://acme-v02.api.letsencrypt.org/directory"
    : "https://acme-staging-v02.api.letsencrypt.org/directory"
  )
}

locals {
  # Accept either a bare hostname (recommended) or a full URL.
  rancher_api_url = startswith(var.rancher_hostname, "http") ? var.rancher_hostname : "https://${var.rancher_hostname}"
}