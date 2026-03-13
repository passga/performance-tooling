output "public_ip" {
  value = module.k3s_node.public_ip
}

output "aws_region" {
  value = var.aws_region
}

output "aws_zone" {
  value = var.availability_zone
}

output "aws_vpc_id" {
  value = module.network.aws_vpc_id
}

output "aws_subnet_id" {
  value = module.network.aws_subnet_id
}

output "ec2_security_group_name" {
  value = module.network.aws_sg_name
}

output "hostname" {
  value = module.k3s_node.k3s_hostname
}

output "kubeconfig_path" {
  value = local.kubeconfig_path
}
