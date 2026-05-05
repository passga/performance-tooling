
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

resource "null_resource" "wait_for_traefik_load_balancer_hostname" {
  depends_on = [kubernetes_manifest.rke2_traefik_config]

  triggers = {
    kubeconfig_path = local.kubeconfig_path
    namespace       = "kube-system"
    service_name    = "rke2-traefik"
    timeout_seconds = "600"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG      = self.triggers.kubeconfig_path
      SERVICE_NS      = self.triggers.namespace
      SERVICE_NAME    = self.triggers.service_name
      TIMEOUT_SECONDS = self.triggers.timeout_seconds
    }

    command = <<-EOT
set -euo pipefail

echo "Waiting for $${SERVICE_NS}/$${SERVICE_NAME} LoadBalancer hostname..."

deadline=$((SECONDS + TIMEOUT_SECONDS))

while true; do
  hostname="$(kubectl --kubeconfig "$KUBECONFIG" -n "$SERVICE_NS" get service "$SERVICE_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

  if [ -n "$hostname" ]; then
    echo "LoadBalancer hostname is available: $hostname"
    exit 0
  fi

  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "Timed out after $${TIMEOUT_SECONDS}s waiting for $${SERVICE_NS}/$${SERVICE_NAME} to report status.loadBalancer.ingress[0].hostname" >&2
    exit 1
  fi

  sleep 5
done
EOT
  }
}
