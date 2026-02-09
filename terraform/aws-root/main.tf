module "network" {
  source = "../modules/aws-network"
  admin_cidr        = var.admin_cidr
}

module "k3s_node" {
  source            = "../modules/aws-k3s-node"
  subnet_id         = module.network.aws_subnet_id
  sg_id             = module.network.aws_sg_id
  vpc_id            = module.network.aws_vpc_id
  availability_zone = var.availability_zone
  prefix            = var.prefix
  ssh_key_name       = var.ssh_key_name
  aws_region        = var.aws_region

}