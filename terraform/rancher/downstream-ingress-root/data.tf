data "terraform_remote_state" "aws_root" {
  count   = local.use_aws_root_remote_state ? 1 : 0
  backend = "local"

  config = {
    path = "../../aws-root/terraform.tfstate"
  }
}

data "terraform_remote_state" "downstream_rke2" {
  backend = "local"

  config = {
    path = "../downstream-rke2-root/terraform.tfstate"
  }
}

data "kubernetes_service" "rke2_traefik" {
  metadata {
    name      = "rke2-traefik"
    namespace = "kube-system"
  }

  depends_on = [kubernetes_manifest.rke2_traefik_config]
}

data "aws_lb" "traefik" {
  tags = {
    "kubernetes.io/service-name" = "kube-system/rke2-traefik"
  }

  depends_on = [data.kubernetes_service.rke2_traefik]
}
