
module "downstream_rke2" {
  source                  = "../../modules/rancher-rke2-cluster"
  access_key              = var.access_key
  secret_key              = var.secret_key
  cloud_credential_id     = var.cloud_credential_id
  aws_region                  = data.terraform_remote_state.aws_root.outputs.aws_region
  aws_zone                    = data.terraform_remote_state.aws_root.outputs.aws_zone
  aws_vpc_id                  = data.terraform_remote_state.aws_root.outputs.aws_vpc_id
  aws_subnet_id               = data.terraform_remote_state.aws_root.outputs.aws_subnet_id
  ec2_security_group_name     = data.terraform_remote_state.aws_root.outputs.ec2_security_group_name
  instance_type               = var.instance_type
  workload_cluster_name       = var.workload_cluster_name
  workload_kubernetes_version = var.workload_kubernetes_version
  windows_prefered_cluster    = var.windows_prefered_cluster
  prefix                      = var.prefix

}
