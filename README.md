![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# terraform-aws-platform

## Overview

This repository documents a validated platform engineering workflow for building a Rancher-managed Kubernetes platform on AWS with Terraform.

The validated implementation is centered on:

- AWS infrastructure for a bootstrap and downstream cluster path
- a bootstrap k3s cluster
- Rancher installed on the bootstrap cluster
- cert-manager and a Let's Encrypt `ClusterIssuer`
- a downstream RKE2 cluster provisioned by Rancher on AWS
- `aws-cloud-controller-manager` inside the downstream cluster
- Traefik customized through `HelmChartConfig`
- Traefik exposed as `Service` type `LoadBalancer`
- an AWS Network Load Balancer in front of Traefik
- Argo CD exposed through Traefik ingress in the downstream cluster

The execution details, root order, and Terraform commands live in [terraform/README.md](terraform/README.md).

## Validated Architecture

```text
+-----------------------------------------------------------------------------------+
|                                        AWS                                        |
|-----------------------------------------------------------------------------------|
| VPC / subnet / security groups                                                    |
| EC2 bootstrap node for k3s                                                        |
| EC2 downstream nodes for RKE2                                                     |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              Bootstrap k3s cluster                                |
|-----------------------------------------------------------------------------------|
| cert-manager                                                                      |
| ClusterIssuer (Let's Encrypt)                                                     |
| Rancher                                                                           |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                        Rancher-managed downstream RKE2 cluster                     |
|-----------------------------------------------------------------------------------|
| Control plane and worker machine pools on AWS                                     |
| aws-cloud-controller-manager                                                      |
| Traefik packaged with RKE2, customized via HelmChartConfig                        |
| Service type LoadBalancer for rke2-traefik                                        |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              AWS Network Load Balancer                            |
|-----------------------------------------------------------------------------------|
| NLB created from the Traefik LoadBalancer Service                                 |
| Traffic forwarded to Traefik                                                      |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                                  Ingress traffic                                  |
|-----------------------------------------------------------------------------------|
| Argo CD exposed through Traefik ingress                                           |
+-----------------------------------------------------------------------------------+
```

## Validated Flow

The validated repository workflow is:

1. `terraform/aws-root`
2. `terraform/platform/platform-cert-manager-root`
3. `terraform/platform/platform-issuer-root`
4. `terraform/rancher/rancher-server-root`
5. `terraform/rancher/downstream-rke2-root`
6. `terraform/rancher/downstream-ingress-root`
7. `terraform/platform/platform-argocd-root`
8. `terraform/rancher/downstream-project-root`

This staged layout exists because bootstrap infrastructure, cert-manager resources, Rancher API readiness, downstream provisioning, and post-cluster resources depend on each other in sequence.

## Outcomes

With the current validated code path, this repository produces:

- a bootstrap k3s cluster on AWS for Rancher
- Rancher served with cert-manager-managed TLS
- a Rancher-managed downstream RKE2 cluster on AWS
- external AWS cloud-provider integration through `aws-cloud-controller-manager`
- Traefik exposed by a Kubernetes `LoadBalancer` Service and reconciled to an AWS NLB
- downstream application exposure through Traefik ingress
- Argo CD deployed in the downstream cluster
- Rancher project and namespace resources created after cluster readiness

## Main Troubleshooting Highlights

- Downstream node IAM is a manual prerequisite. The validated node policy is `infra-dev-rke2-cloud-provider-aws`.
- A missing `ec2:CreateTags` permission on `security-group/*` caused `rke2-traefik` to remain in `EXTERNAL-IP: pending`.
- `kube-apiserver-arg = ["cloud-provider=external"]` is not part of the validated setup and breaks startup.
- `node-labels=node-role.kubernetes.io/worker=true` is not part of the validated setup and caused kubelet startup failure.
- A `404` from the NLB before any ingress exists is expected and only means Traefik has no matching route yet.
- TLS trust between Rancher and downstream nodes still matters for successful registration.

## Repository Structure

```text
terraform/
├── README.md
├── aws-root/
├── modules/
├── platform/
└── rancher/
```

Use [terraform/README.md](terraform/README.md) as the execution guide for apply order, destroy order, prerequisites, IAM setup, and downstream ingress behavior.
