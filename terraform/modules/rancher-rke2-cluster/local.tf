# Local resources

# Save kubeconfig file for interacting with the RKE cluster on your local machine
resource "local_file" "kube_config_workload_yaml" {
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
local = {
  source  = "hashicorp/local"
  version = "~> 2.5"
}