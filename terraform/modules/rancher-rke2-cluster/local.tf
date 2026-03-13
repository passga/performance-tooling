# Local resources

# Save kubeconfig locally without storing the content in plaintext state.
resource "local_sensitive_file" "kube_config_workload_yaml" {
  filename = format("%s/%s", path.root, "kube_config_workload.yaml")
  content  = rancher2_cluster_v2.cluster.kube_config
}

locals {
  control_plane_pool = {
    name                = "${var.prefix}-control-plane"
    quantity            = 1
    control_plane_role  = true
    etcd_role           = true
    worker_role         = false
  }

  worker_pool = {
    name                = "${var.prefix}-worker"
    quantity            = 1
    control_plane_role  = false
    etcd_role           = false
    worker_role         = true
  }

  rke_network_plugin = var.windows_prefered_cluster ? "flannel" : "canal"

}
