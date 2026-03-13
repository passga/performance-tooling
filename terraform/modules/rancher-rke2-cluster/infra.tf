# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "node" {
  count       = var.cloud_credential_id == null ? 1 : 0
  name        = "${var.workload_cluster_name}-node"
  description = "Terraform cloudCredential performance test"
  amazonec2_credential_config {
    access_key = var.access_key
    secret_key = var.secret_key
  }
}

locals {
  cloud_credential_id = var.cloud_credential_id != null ? var.cloud_credential_id : rancher2_cloud_credential.node[0].id
}

resource "rancher2_cluster_v2" "cluster" {
    name        = var.workload_cluster_name
    enable_network_policy = false

    rke_config {
      machine_global_config = yamlencode({
        cni = local.rke_network_plugin
      })

      machine_pools {
        name     = local.control_plane_pool.name
        quantity = local.control_plane_pool.quantity

        control_plane_role = local.control_plane_pool.control_plane_role
        etcd_role          = local.control_plane_pool.etcd_role
        worker_role        = local.control_plane_pool.worker_role

        cloud_credential_secret_name = local.cloud_credential_id

        machine_config {
          kind = rancher2_machine_config_v2.cluster_template_ec2.kind
          name = rancher2_machine_config_v2.cluster_template_ec2.name
        }
      }

      machine_pools {
        name     = local.worker_pool.name
        quantity = local.worker_pool.quantity

        control_plane_role = local.worker_pool.control_plane_role
        etcd_role          = local.worker_pool.etcd_role
        worker_role        = local.worker_pool.worker_role

        cloud_credential_secret_name = local.cloud_credential_id

        machine_config {
          kind = rancher2_machine_config_v2.cluster_template_ec2.kind
          name = rancher2_machine_config_v2.cluster_template_ec2.name
        }
      }
    }
  kubernetes_version = var.workload_kubernetes_version
}


# Create a new rancher2 Node Template
resource "rancher2_machine_config_v2" "cluster_template_ec2" {
  generate_name = "${var.workload_cluster_name}-"

  amazonec2_config {
    ami            = data.aws_ami.ubuntu.id
    instance_type  = var.instance_type
    region         = var.aws_region
    subnet_id      = var.aws_subnet_id
    root_size      = 16
    security_group = [var.ec2_security_group_name]
    vpc_id         = var.aws_vpc_id
    zone           = var.aws_zone


  }

}



# Create a new rancher2 Project
resource "rancher2_project" "init_project" {
  name        = var.prefix
  cluster_id  = rancher2_cluster_v2.cluster.id
  description = "${var.prefix} project for running of performance tests"
}

# Create a new rancher2 Namespace
resource "rancher2_namespace" "init_namespace" {
  name        = var.prefix
  project_id  = rancher2_project.init_project.id
  description = "${var.prefix} namespace for running of performance tests"
}
