![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# terraform

## Purpose

This directory contains the staged Terraform roots used to execute the validated platform workflow in this repository.

This README is intentionally operational:

- it documents which Terraform roots to run
- it documents the required execution order
- it documents the downstream IAM prerequisite
- it documents the validated ingress and NLB behavior

For the high-level architecture and project outcomes, use the repository root README.

## Terraform Roots

### `terraform/aws-root`

Creates the base AWS infrastructure for the bootstrap path and provisions the bootstrap EC2 node that installs k3s.

Main outcome:

- AWS network resources
- bootstrap EC2 instance
- retrieved kubeconfig for the bootstrap k3s cluster

### `terraform/platform/platform-cert-manager-root`

Installs cert-manager into the bootstrap k3s cluster.

Main outcome:

- cert-manager controllers running on the bootstrap cluster

### `terraform/platform/platform-issuer-root`

Creates the Let's Encrypt `ClusterIssuer` used for Rancher TLS on the bootstrap cluster.

Main outcome:

- bootstrap cluster `ClusterIssuer` ready for Rancher certificate issuance

### `terraform/rancher/rancher-server-root`

Installs Rancher on the bootstrap cluster, creates the Rancher TLS certificate, waits for trusted API readiness, and bootstraps the Rancher admin/API state.

Main outcome:

- Rancher reachable on the bootstrap cluster
- Rancher API bootstrapped and ready for downstream provisioning

### `terraform/rancher/downstream-rke2-root`

Creates the Rancher-managed downstream RKE2 cluster on AWS.

Validated downstream behavior:

- `machine_global_config` includes `cloud-provider-name = "aws"`
- control-plane selector uses `disable-cloud-controller = true`
- control-plane selector uses `kube-controller-manager-arg = ["cloud-provider=external"]`
- control-plane selector uses `kubelet-arg = ["cloud-provider=external"]`
- worker selector uses `kubelet-arg = ["cloud-provider=external"]`
- `aws-cloud-controller-manager` is installed as part of the downstream cluster path

This is the current validated AWS cloud-provider configuration for the downstream cluster.

### `terraform/rancher/downstream-ingress-root`

Customizes the packaged RKE2 Traefik deployment in the downstream cluster.

Validated behavior:

- uses `HelmChartConfig` named `rke2-traefik` in `kube-system`
- sets `service.type = LoadBalancer`
- applies AWS NLB annotations to the Traefik Service

Main outcome:

- Traefik exposed through a Kubernetes `LoadBalancer` Service
- AWS NLB created for that Service

### `terraform/platform/platform-argocd-root`

Deploys Argo CD into the downstream cluster and exposes it through Traefik ingress.

Main outcome:

- Argo CD installed in the downstream cluster
- Argo CD reachable through Traefik once ingress and DNS or host-header testing are in place

### `terraform/rancher/downstream-project-root`

Creates Rancher project and namespace resources after the downstream cluster is ready.

Main outcome:

- post-cluster Rancher project and namespace resources created against the validated downstream cluster

## Recommended Apply Order

Run the Terraform roots in this order:

1. `terraform/aws-root`
2. `terraform/platform/platform-cert-manager-root`
3. `terraform/platform/platform-issuer-root`
4. `terraform/rancher/rancher-server-root`
5. `terraform/rancher/downstream-rke2-root`
6. `terraform/rancher/downstream-ingress-root`
7. `terraform/platform/platform-argocd-root`
8. `terraform/rancher/downstream-project-root`

Before running these roots, create a local `env/dev.tfvars` from the `env/dev.tfvars.example` file present in each root that needs one.

Example execution sequence:

```bash
cd terraform/aws-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/rancher-server-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-rke2-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-ingress-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/platform/platform-argocd-root
terraform init
terraform apply -var-file=env/dev.tfvars

cd terraform/rancher/downstream-project-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

## Recommended Destroy Order

Destroy in reverse order:

1. `terraform/rancher/downstream-project-root`
2. `terraform/platform/platform-argocd-root`
3. `terraform/rancher/downstream-ingress-root`
4. `terraform/rancher/downstream-rke2-root`
5. `terraform/rancher/rancher-server-root`
6. `terraform/platform/platform-issuer-root`
7. `terraform/platform/platform-cert-manager-root`
8. `terraform/aws-root`

Example destroy sequence:

```bash
cd terraform/rancher/downstream-project-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-argocd-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/rancher/downstream-ingress-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/rancher/downstream-rke2-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/rancher/rancher-server-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-issuer-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/platform/platform-cert-manager-root
terraform destroy -var-file=env/dev.tfvars

cd terraform/aws-root
terraform destroy -var-file=env/dev.tfvars
```

## IAM And Instance Profile Prerequisites For Downstream Nodes

Downstream node IAM remains a manual prerequisite for the validated setup.

You must create in AWS before running `terraform/rancher/downstream-rke2-root`:

- one EC2 IAM role for downstream RKE2 nodes
- one EC2 instance profile associated with that role
- the validated custom policy `infra-dev-rke2-cloud-provider-aws` attached to that downstream node role

The Terraform and Rancher code in this repository do not create that downstream node IAM role or instance profile for you.

Operational requirements:

- `downstream_node_instance_profile_name` must be the instance profile name
- do not pass an instance profile ARN
- the AWS identity used by Terraform or by the Rancher cloud credential must have `iam:PassRole` on the downstream node role
- the Terraform AWS identity must have `iam:GetInstanceProfile` on the existing instance profile

Validated practical note:

- the missing permission observed in practice was `ec2:CreateTags` on `security-group/*`
- when that permission was missing, `rke2-traefik` stayed in `EXTERNAL-IP: pending`
- the NLB did not complete reconciliation until that permission was available through `infra-dev-rke2-cloud-provider-aws`

## Notes About Downstream Ingress, Traefik, And The NLB

The validated downstream ingress path is:

```text
Traefik packaged with RKE2
-> customized by HelmChartConfig in terraform/rancher/downstream-ingress-root
-> Service type LoadBalancer
-> aws-cloud-controller-manager / AWS cloud provider integration
-> AWS Network Load Balancer
```

Operational notes:

- do not recreate `kube-system/rke2-traefik` as a separate Terraform-managed `Service`
- customize Traefik through `HelmChartConfig` named `rke2-traefik`
- `aws-cloud-controller-manager` is part of the validated downstream cluster path
- the current validated path does not require any separate controller for this NLB workflow
- a `404` from the NLB before any ingress exists is expected and only means Traefik has no matching route yet

Argo CD is validated on top of that path through `terraform/platform/platform-argocd-root`, where it is exposed by a Traefik ingress in the downstream cluster.

## Troubleshooting Notes

### Downstream nodes are not created by Rancher

Check:

- the instance profile exists in AWS
- `downstream_node_instance_profile_name` is the instance profile name, not an ARN
- the AWS identity used by Terraform or Rancher has `iam:PassRole`
- Terraform can read the instance profile with `iam:GetInstanceProfile`

### `rke2-traefik` stays in `EXTERNAL-IP: pending`

Check:

- the downstream node role has the validated policy `infra-dev-rke2-cloud-provider-aws`
- that policy includes the missing permission seen in practice: `ec2:CreateTags` on `security-group/*`
- `terraform/rancher/downstream-ingress-root` has been applied
- Traefik is still being customized through `HelmChartConfig`, not by replacing the packaged Service

### NLB returns `404`

Check:

- the NLB already points to the Traefik `LoadBalancer` Service
- an ingress exists for the hostname or path you are testing

This is expected before any matching ingress route exists.

### `kube-apiserver` fails with `unknown flag: --cloud-provider`

Do not use:

- `kube-apiserver-arg = ["cloud-provider=external"]`

This is not part of the validated setup and breaks startup.

### `kubelet` fails when worker node labels are forced

Do not use:

- `node-labels=node-role.kubernetes.io/worker=true`

This is not part of the validated setup and caused kubelet startup failure in practice.

### Downstream registration fails even though Rancher is reachable

Check:

- Rancher TLS has been issued successfully
- the Rancher endpoint serves the expected certificate chain
- downstream nodes trust the CA chain served by Rancher

TLS trust between Rancher and downstream nodes still matters for node registration.
