
resource "kubernetes_manifest" "rke2_traefik_config" {

  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"

    metadata = {
      name      = "rke2-traefik"
      namespace = "kube-system"
    }

    spec = {
      valuesContent = <<-EOT
        service:
          type: LoadBalancer
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
            service.beta.kubernetes.io/aws-load-balancer-subnets: ${data.terraform_remote_state.downstream_rke2.outputs.aws_subnet_id}
      EOT
    }
  }
}