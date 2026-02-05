

# Rancher2 administration provider
provider "rancher2" {
  alias = "admin"
  insecure  = var.rancher_bootstrap_insecure
  api_url   = local.rancher_api_url
  token_key = rancher2_bootstrap.admin.token
}

# Rancher2 bootstrapping provider
provider "rancher2" {
  alias = "bootstrap"
  insecure  = var.rancher_bootstrap_insecure
  api_url    = local.rancher_api_url
  bootstrap  = true
}

provider "kubernetes" {

  config_path = abspath(var.kubeconfig_path)
}

provider "helm" {
  kubernetes = {
    config_path = abspath(var.kubeconfig_path)
  }
}

