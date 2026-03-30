resource "helm_release" "aws_load_balancer_controller" {
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false
  version          = var.aws_load_balancer_controller_chart_version
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 600

  set = [
    {
      name  = "clusterName"
      value = data.terraform_remote_state.downstream_rke2.outputs.cluster_name
    },
    {
      name  = "region"
      value = data.terraform_remote_state.downstream_rke2.outputs.aws_region
    },
    {
      name  = "vpcId"
      value = data.terraform_remote_state.downstream_rke2.outputs.aws_vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
  ]
}

resource "kubernetes_manifest" "rke2_traefik_config" {
  depends_on = [helm_release.aws_load_balancer_controller]

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
            service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
            service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
            service.beta.kubernetes.io/aws-load-balancer-subnets: ${data.terraform_remote_state.downstream_rke2.outputs.aws_subnet_id}
          spec:
            loadBalancerClass: service.k8s.aws/nlb
      EOT
    }
  }
}
