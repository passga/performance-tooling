

output "rancher_node_ip" {
  value = aws_eip_association.rancher_server.public_ip
}

output "rancher_server_ec2_instance_id" {
  value = aws_eip_association.rancher_server.instance_id
}


output "rancher_server_subnet_id" {
  value     = aws_instance.rancher_server.subnet_id
  sensitive = true
}

output "rancher_server_availability_zone" {
  value     = aws_instance.rancher_server.availability_zone
  sensitive = true
}

output "public_ip" {
  value = aws_eip.rancher_server.public_ip
}

output "ssh_command" {
  value = "ssh -i <YOUR_KEY> ubuntu@${aws_eip.rancher_server.public_ip}"
}

output "fetch_kubeconfig_command" {
  description = "Command to fetch the kubeconfig from the server and rewrite the API server endpoint to the public IP."
  value       = "scp -i <YOUR_KEY> ubuntu@${aws_eip.rancher_server.public_ip}:/etc/rancher/k3s/k3s.yaml ./k3s.yaml && sed -i 's/127.0.0.1/${aws_eip.rancher_server.public_ip}/' ./k3s.yaml"
}

output "rancher_hostname" {
  value = "rancher.${aws_eip.rancher_server.public_ip}.nip.io"
}

