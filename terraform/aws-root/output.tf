output "public_ip" {
  value = module.k3s_node.public_ip
}

output "hostname" {
  value = module.k3s_node.k3s_hostname
}

output "fetch_kubeconfig_command" {
  value = module.k3s_node.fetch_kubeconfig_command
}

