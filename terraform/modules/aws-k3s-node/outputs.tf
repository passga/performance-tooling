

output "public_ip" {
  value = aws_eip.k3s.public_ip
}

output "ssh_command" {
  value = "ssh -i <YOUR_KEY> ubuntu@${aws_eip.k3s.public_ip}"
}

output "k3s_hostname" {
  value = "rancher.${aws_eip.k3s.public_ip}.nip.io"
}

output "fetch_kubeconfig_command" {
  description = "Fetch k3s kubeconfig and rewrite API endpoint to the public IP."
  value = join(" ", [
    "scp -i <YOUR_KEY> -o StrictHostKeyChecking=no ubuntu@${aws_eip.k3s.public_ip}:/etc/rancher/k3s/k3s.yaml terraform/kube/k3s.yaml",
    "&&",
    "sed -i 's#^\\s*server:.*#server: https://${aws_eip.k3s.public_ip}:6443#' terraform/kube/k3s.yaml",
    "&&",
    "chmod 600 terraform/kube/k3s.yaml",
  ])
}
