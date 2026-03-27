locals {
  using_explicit_aws_region = var.aws_region != null && trimspace(var.aws_region) != ""
  use_aws_root_remote_state = !local.using_explicit_aws_region
  aws_region                = local.using_explicit_aws_region ? var.aws_region : data.terraform_remote_state.aws_root[0].outputs.aws_region
  kubeconfig_path = (
    var.kubeconfig_path_override != null && trimspace(var.kubeconfig_path_override) != ""
    ? abspath(var.kubeconfig_path_override)
    : abspath("${path.module}/../downstream-rke2-root/${basename(data.terraform_remote_state.downstream_rke2.outputs.kubeconfig_path)}")
  )
}

provider "aws" {
  region = local.aws_region
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
  insecure    = true
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
    insecure    = true
  }
}
