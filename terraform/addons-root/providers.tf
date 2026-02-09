provider "kubernetes" {

  config_path = abspath(var.kubeconfig_path)
}

provider "helm" {
  kubernetes = {
    config_path = abspath(var.kubeconfig_path)
  }
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = local.rancher_api_url
  bootstrap = true
  insecure  = var.rancher_bootstrap_insecure
}

