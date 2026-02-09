module "k8s_cert_manager" {
  source               = "../modules/k8s-cert-manager"
  kubeconfig_path      = var.kubeconfig_path
  cert_manager_version = var.cert_manager_version
}

resource "null_resource" "wait_certmanager_crds" {
  depends_on = [module.k8s_cert_manager]

  provisioner "local-exec" {
    command = <<EOT
set -e
for i in $(seq 1 60); do
  kubectl --kubeconfig "${var.kubeconfig_path}" get crd clusterissuers.cert-manager.io >/dev/null 2>&1 && exit 0
  echo "Waiting cert-manager CRDs... ($i/60)"
  sleep 5
done
echo "cert-manager CRDs not ready"
exit 1
EOT
  }

}

module "k8s_rancher_server" {
  depends_on              = [null_resource.wait_certmanager_crds]
  source                  = "../modules/k8s-rancher-server"
  rancher_version         = var.rancher_version
  kubeconfig_path         = var.kubeconfig_path
  rancher_hostname        = var.rancher_hostname
  letsencrypt_environment = var.letsencrypt_environment
  letsencrypt_email       = var.letsencrypt_email

}