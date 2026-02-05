output "letsencrypt_environment" {
  value = var.letsencrypt_environment
}

output "rancher_server_url" {
  value       = local.rancher_api_url
  description = "Rancher UI/API base URL."
}

output "rancher_admin_password" {
  description = "Initial Rancher admin password (sensitive)."
  value       = random_password.rancher_admin.result
  sensitive   = true
}

output "rancher_bootstrap_token" {
  description = "Rancher bootstrap token (sensitive)."
  value       = rancher2_bootstrap.admin.token
  sensitive   = true
}

output "rancher_cli_token" {
  description = "Rancher CLI API token (sensitive)."
  value       = rancher2_token.tokenCLI.token
  sensitive   = true
}

