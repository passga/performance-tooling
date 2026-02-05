# AWS stack — k3s on a single EC2

This Terraform stack provisions a minimal AWS environment for the POC:

- VPC + public subnet + IGW + route table
- Security group (SSH/HTTPS/Kubernetes API + optional HTTP for Let's Encrypt)
- EC2 (Ubuntu) + EIP
- cloud-init installs **k3s** and configures `tls-san` with the public IP

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform apply
```

After apply, use the `fetch_kubeconfig_command` output to retrieve the kubeconfig from the instance.

## Security

For a trusted Rancher TLS certificate (Let's Encrypt HTTP-01), inbound port **80** must be reachable.
By default `allow_http_01=true` opens port 80 to `http_01_cidr` (default: `0.0.0.0/0`).
