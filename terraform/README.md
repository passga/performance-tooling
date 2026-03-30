![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)
![Kubernetes](https://img.shields.io/badge/Kubernetes-RKE2-blue)
![Platform](https://img.shields.io/badge/Platform-Rancher-green)
![Cloud](https://img.shields.io/badge/Cloud-AWS-orange)

# terraform-aws-platform

## Overview

This repository demonstrates how to build a Rancher-managed Kubernetes platform on AWS using Terraform.

The platform automatically provisions:

- AWS infrastructure (VPC, security groups, EC2 instances)
- a bootstrap Kubernetes cluster using k3s
- Rancher installed via Helm
- Rancher ingress TLS via cert-manager and Let's Encrypt
- a downstream RKE2 Kubernetes cluster
- control plane and worker nodes managed by Rancher machine pools
- Rancher project and namespace resources after the downstream cluster is ready

The goal is to demonstrate a reproducible platform engineering workflow using Infrastructure as Code.


## Architecture

This project uses a staged Terraform design because the Kubernetes API, Helm resources, Rancher bootstrap, and downstream cluster provisioning depend on each other in sequence.

```text
                         +----------------------------------+
                         |             AWS                  |
                         |----------------------------------|
                         | VPC / Subnet / Security Group    |
                         | EC2 for k3s management node      |
                         | EC2 for downstream RKE2 nodes    |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |     k3s Bootstrap Cluster        |
                         |----------------------------------|
                         | cert-manager                     |
                         | ClusterIssuer (Let's Encrypt)    |
                         | Rancher installed with Helm      |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |            Rancher               |
                         |----------------------------------|
                         | Cloud credential / node templates|
                         | Machine provisioning on AWS      |
                         | Cluster management API/UI        |
                         +----------------+-----------------+
                                          |
                                          v
                         +----------------------------------+
                         |     Downstream RKE2 Cluster      |
                         |----------------------------------|
                         | Control plane nodes              |
                         | Worker nodes                     |
                         | Managed from Rancher             |
                         +----------------------------------+
```
## Resulting Rancher Cluster

Example of the Rancher-managed downstream RKE2 cluster created by this project.

![Rancher Cluster Dashboard](docs/rancher-cluster-dashboard.png)

## Provisioning Workflow

1. Terraform provisions AWS networking and an EC2 instance for the bootstrap management node.
2. The bootstrap node installs k3s and exposes a kubeconfig for follow-up Terraform stages.
3. Terraform installs cert-manager into the k3s cluster.
4. Terraform creates a Let's Encrypt production `ClusterIssuer`.
5. Terraform creates the Rancher TLS `Certificate`, installs the Rancher Helm chart with `ingress.tls.source=secret`, waits for trusted API readiness, and bootstraps Rancher.
6. Terraform connects to the Rancher API, configures machine provisioning, and requests a downstream cluster.
7. Terraform waits until the downstream cluster is ready in both the provisioning and management APIs.
8. Terraform creates Rancher project and namespace resources only after the downstream cluster is fully ready.

## Repository Layout

```text
terraform/
├── aws-root/                          # AWS network + k3s bootstrap node
├── platform/platform-cert-manager-root/ # cert-manager installation
├── platform/platform-issuer-root/       # Let's Encrypt ClusterIssuer
├── rancher/rancher-server-root/         # Rancher installation and bootstrap
├── rancher/downstream-rke2-root/        # Downstream RKE2 cluster provisioning
├── rancher/downstream-project-root/     # Rancher project + namespace after cluster readiness
└── modules/                             # Reusable Terraform modules
```

## Prerequisites

- Terraform `>= 1.6`
- AWS account and credentials with permission to create VPC, security groups, and EC2 resources
- An existing EC2 key pair and access to its private key for bootstrap SSH
- `aws`, `kubectl`, `helm`, and `scp` available on the operator machine
- A public DNS name for Rancher, or a dynamic hostname such as `nip.io`
- Port `80` reachable for Let's Encrypt HTTP-01 validation when using automatic TLS

## AWS Authentication

Terraform AWS resources use the standard AWS credential chain. The simplest local option is environment variables:

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="eu-west-3"
```

If you use temporary credentials, also export:

```bash
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

You can also use `AWS_PROFILE` with `~/.aws/credentials`.

For downstream cluster provisioning, Rancher also needs AWS credentials to create EC2 machines. In `terraform/rancher/downstream-rke2-root`, choose one of these approaches:
- set `cloud_credential_id` to reuse an existing Rancher cloud credential
- or set `access_key` and `secret_key` in `env/dev.tfvars`

## Downstream RKE2 Node IAM Prerequisites

Downstream RKE2 node IAM setup is now a manual AWS prerequisite.

- Terraform and Rancher in this repository do not create the downstream EC2 node IAM role anymore.
- Terraform in this repository also does not create the EC2 instance profile or the `AWSLoadBalancerControllerIAMPolicy` attachment for downstream nodes anymore.
- You must create the downstream EC2 IAM role and the corresponding EC2 instance profile yourself in AWS before running `terraform apply` in `terraform/rancher/downstream-rke2-root`.
- The role is what grants permissions to the EC2 instances. The instance profile is what Rancher attaches to the EC2 instances at launch time.

### What You Must Create In AWS

Create these AWS IAM resources ahead of time:

- one EC2 IAM role for the downstream RKE2 nodes
- one EC2 instance profile associated with that role

The downstream Rancher machine config uses the instance profile name through `rancher2_machine_config_v2.amazonec2_config.iam_instance_profile`.

In this repository, `terraform/rancher/downstream-rke2-root` validates the existing instance profile with `data.aws_iam_instance_profile.downstream_nodes` and passes only its `name` into that field.

Important:

- `iam_instance_profile` must be the instance profile name
- do not pass the instance profile ARN
- do not pass the role ARN

Example:

```hcl
downstream_node_instance_profile_name = "rke2-downstream-instance-profile"
```

Not:

```hcl
downstream_node_instance_profile_name = "arn:aws:iam::123456789012:instance-profile/rke2-downstream-instance-profile"
```

### Required Permissions

The AWS identity used by Terraform or by the Rancher cloud credential must be allowed to pass the downstream node role to EC2.

- grant `iam:PassRole` on the downstream node role
- ensure the permission targets the IAM role used by the instance profile

Without `iam:PassRole`, Rancher can create the machine request in its API but AWS will reject EC2 instance creation.

Because `terraform/rancher/downstream-rke2-root` reads the existing instance profile with `data.aws_iam_instance_profile`, the AWS identity used by Terraform also needs:

- `iam:GetInstanceProfile` on the existing downstream instance profile

Without `iam:GetInstanceProfile`, Terraform cannot validate or read the pre-existing instance profile before passing its name to Rancher.

### Required ALB Policy For Ingress

If you want ALB ingress to work in the downstream cluster, attach `AWSLoadBalancerControllerIAMPolicy` to the downstream node role.

- attach the ALB policy to the downstream EC2 node role
- do not attach it only to the Terraform IAM user
- `terraform/rancher/downstream-ingress-root` installs the controller but does not create or attach its IAM policy

The policy must be available on the role assumed by the downstream EC2 instances, because the AWS Load Balancer Controller runs on those nodes and uses node credentials unless you configure a different AWS credential mechanism such as IRSA.

### IMDSv2 Requirement For AWS Load Balancer Controller

When the AWS Load Balancer Controller retrieves AWS credentials from the EC2 instance metadata service, IMDSv2 must be reachable from the pod network.

- ensure the downstream EC2 instances expose IMDS
- keep IMDS enabled on the downstream EC2 instances
- enable IMDSv2, or require it if that matches your AWS baseline
- for containerized workloads, set the EC2 instance metadata hop limit to at least `2`
- hop limit `1` can prevent pods from reaching IMDSv2 correctly, even when the node role is valid

With the current provider set used by this repository, Rancher machine provisioning consumes the existing IAM instance profile but does not expose a supported Terraform argument here to set the EC2 HTTP PUT response hop limit for the downstream nodes.

This repository therefore uses a per-cluster post-creation IMDS reconciliation step in `terraform/rancher/downstream-rke2-root`.

- the Rancher EC2 machine config enables the metadata endpoint
- the Rancher EC2 machine config requires IMDSv2 tokens
- the Rancher EC2 machine config adds stable AWS tags to every downstream node created for this cluster
- Terraform then discovers the EC2 instances for this cluster by those tags and runs `aws ec2 modify-instance-metadata-options` only against those instances
- the post-creation fix enforces `http-endpoint=enabled`, `http-tokens=required`, and `http-put-response-hop-limit=2`

This is not a Rancher-native EC2 metadata hop-limit option. It is a cluster-scoped AWS-side reconciliation step that runs after the instances are created.

Operational prerequisites:

- the `aws` CLI must be installed where Terraform runs
- valid AWS credentials must be available where Terraform runs
- the Terraform execution identity must be allowed to call `ec2:DescribeInstances`
- the Terraform execution identity must be allowed to call `ec2:ModifyInstanceMetadataOptions`

Operational limitation:

- this is a post-creation reconciliation step
- if Rancher later replaces or adds nodes in the same cluster, run `terraform apply` again so Terraform can discover the new EC2 instance IDs and re-apply the IMDS fix

If the hop limit is too low, the controller may fail to discover node credentials even when the node IAM role is correct.

### Verifying The EC2 Metadata Options

Check the EC2 instances that belong to this downstream cluster:

```bash
aws ec2 describe-instances \
  --region eu-west-3 \
  --filters \
    "Name=tag:tf-aws-platform-cluster,Values=<cluster-name>" \
    "Name=tag:tf-aws-platform-component,Values=downstream-rke2" \
    "Name=tag:tf-aws-platform-managed,Values=true" \
  --query 'Reservations[].Instances[].{InstanceId:InstanceId,HttpEndpoint:MetadataOptions.HttpEndpoint,HttpTokens:MetadataOptions.HttpTokens,HopLimit:MetadataOptions.HttpPutResponseHopLimit,State:MetadataOptions.State}' \
  --output table
```

Expected result:

- `HttpEndpoint = enabled`
- `HttpTokens = required`
- `HopLimit = 2`
- `State = applied`

### Verifying The Result In Kubernetes

After the EC2 metadata options are fixed, verify that the controller can reconcile the Traefik `LoadBalancer` Service:

```bash
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl -n kube-system logs deploy/aws-load-balancer-controller
kubectl -n kube-system get svc rke2-traefik
```

Expected result:

- the controller pod is `Running`
- the logs no longer show `no EC2 IMDS role found`
- the `rke2-traefik` Service gets an `EXTERNAL-IP` instead of staying `pending`

### Traefik Customization In RKE2

`rke2-traefik` is a packaged RKE2 component. It must be customized through a `HelmChartConfig` named `rke2-traefik` in namespace `kube-system`.

- do not recreate or replace the existing `kube-system/rke2-traefik` Service with `kubernetes_manifest`
- set the Traefik service type to `LoadBalancer`
- add the AWS NLB annotations in the `HelmChartConfig`
- keep `loadBalancerClass: service.k8s.aws/nlb` when using AWS Load Balancer Controller for the Service

This repository follows that pattern in `terraform/rancher/downstream-ingress-root`.

### Troubleshooting

#### Invalid IAM Instance Profile Name

Symptoms:

- Rancher machine provisioning fails quickly
- AWS reports an invalid or missing instance profile

Checks:

- confirm that `downstream_node_instance_profile_name` matches the AWS instance profile name exactly
- confirm that you passed the instance profile name, not an ARN
- confirm that the instance profile is associated with the intended downstream node IAM role

#### Missing `iam:PassRole`

Symptoms:

- Rancher can talk to AWS but EC2 instance creation is denied
- AWS errors mention `iam:PassRole` or not being authorized to pass the role

Checks:

- grant the Terraform or Rancher AWS identity `iam:PassRole` on the downstream node role
- verify the permission applies to the role referenced by the instance profile

#### Missing `iam:GetInstanceProfile`

Symptoms:

- Terraform fails during planning or apply before Rancher creates machines
- AWS errors mention `iam:GetInstanceProfile` or access denied while reading the instance profile

Checks:

- grant the Terraform AWS identity `iam:GetInstanceProfile` on the existing instance profile
- confirm that `downstream_node_instance_profile_name` points to the real instance profile name in AWS

#### EXTERNAL-IP Pending On The `LoadBalancer` Service

Symptoms:

- Traefik remains exposed as a `LoadBalancer` Service but `EXTERNAL-IP` stays `pending`
- no NLB is created in AWS

Checks:

- verify `aws-load-balancer-controller` is running and healthy
- verify `AWSLoadBalancerControllerIAMPolicy` is attached to the downstream node role
- verify the Traefik packaged component is customized through `HelmChartConfig` rather than by recreating the Service
- verify the subnet annotation value matches the downstream AWS subnet used by the nodes
- verify `loadBalancerClass` is set to `service.k8s.aws/nlb`
- verify the cluster-scoped IMDS fix ran for the instances tagged with `tf-aws-platform-cluster=<cluster-name>`
- verify IMDS is enabled and that the EC2 metadata hop limit is at least `2`

#### `no EC2 IMDS role found`

Symptoms:

- the AWS Load Balancer Controller logs mention `no EC2 IMDS role found`
- Service reconciliation fails even though the node role exists

Checks:

- verify the downstream EC2 instances actually use the intended instance profile
- verify IMDS is enabled on the instances
- verify IMDSv2 is enabled or required according to your AWS policy
- verify the metadata hop limit is at least `2`
- verify the node role has `AWSLoadBalancerControllerIAMPolicy`

#### Controller Cannot Retrieve AWS Credentials From IMDS

Symptoms:

- the controller cannot discover AWS credentials from EC2 metadata
- reconciliation fails even though the node role and instance profile exist

Checks:

- verify the metadata endpoint is enabled on the downstream EC2 instances
- verify IMDSv2 tokens are required or enabled as expected
- verify the hop limit is `2`
- verify the cluster-scoped post-creation IMDS fix ran successfully for this cluster

#### `Cannot create resource that already exists` For `rke2-traefik`

Symptoms:

- Terraform fails when trying to manage Traefik networking resources
- errors mention that `rke2-traefik` already exists

Checks:

- do not manage `kube-system/rke2-traefik` as a standalone `Service`
- manage the packaged component through `HelmChartConfig` named `rke2-traefik` in namespace `kube-system`
- remove any legacy `kubernetes_manifest` that attempts to recreate the Service

#### EC2 Instances Not Being Created By Rancher

Symptoms:

- the downstream cluster stays in provisioning state
- no new EC2 instances appear in AWS

Checks:

- verify the Rancher machine config is using the correct `iam_instance_profile` value
- verify the instance profile exists in AWS and is linked to the expected role
- verify the AWS identity used by Terraform or Rancher has `iam:PassRole`
- verify the downstream node role, not just the Terraform IAM user, has `AWSLoadBalancerControllerIAMPolicy` when ALB ingress is expected
- inspect Rancher machine provisioning events and AWS CloudTrail or EC2 error messages for the rejected API call

## Security Hygiene

- Do not commit generated files such as `*.tfstate`, `*.tfstate.*`, `env/*.tfvars`, or kubeconfig files.
- Treat Terraform state, backup state, and kubeconfig files as sensitive because they can contain passwords, API tokens, cloud credentials, cluster registration tokens, and client key material.
- If you accidentally create those files inside the repository while testing, remove them from the working tree before sharing or publishing the project.

## How To Deploy

Use the example tfvars files in each Terraform root as the starting point.

### 1. Provision AWS and bootstrap k3s

```bash
cd terraform/aws-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

This stage creates the AWS network, the management EC2 instance, installs k3s, and writes the kubeconfig used by the next stages.

### 2. Install cert-manager

```bash
cd terraform/platform/platform-cert-manager-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 3. Create the Let's Encrypt issuer

```bash
cd terraform/platform/platform-issuer-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 4. Install Rancher

```bash
cd terraform/rancher/rancher-server-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 5. Provision the downstream RKE2 cluster

```bash
cd terraform/rancher/downstream-rke2-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

### 6. Create Rancher project and namespace

```bash
cd terraform/rancher/downstream-project-root
terraform init
terraform apply -var-file=env/dev.tfvars
```

The result is a Rancher-managed downstream RKE2 cluster with project and namespace resources created only after the cluster is actually ready.

## How To Destroy The Infrastructure

Destroy in reverse order to avoid dependency and remote-state issues.

```bash
cd terraform/rancher/downstream-project-root
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

## Notes

- Terraform roots are intentionally separated to handle bootstrap sequencing cleanly.
- Rancher TLS is managed by cert-manager. The Rancher Helm chart consumes a pre-created secret and does not manage Let's Encrypt itself.
- The downstream cluster can either reuse AWS network data from `aws-root` remote state or accept dedicated AWS networking values.
- `rancher-server-root` waits for the cert-manager `Certificate`, trusted HTTPS, and a successful bootstrap login before `rancher2_bootstrap`.
- `downstream-rke2-root` creates only the Rancher cloud credential and `rancher2_cluster_v2`; project and namespace creation lives in `downstream-project-root`.
- This repository is designed as a practical platform engineering portfolio project rather than production-ready infrastructure.


## TLS and Let's Encrypt Considerations

Rancher is exposed through an ingress secured with TLS certificates issued by **Let's Encrypt** via **cert-manager**.

During startup, the ingress controller (Traefik) initially serves a temporary self-signed certificate:

```
TRAEFIK DEFAULT CERT
```

This certificate is used until cert-manager successfully obtains a valid certificate from Let's Encrypt and attaches it to the Rancher ingress.

### Important for Downstream RKE2 Nodes

When Rancher provisions downstream RKE2 nodes, those nodes must connect back to the Rancher server over HTTPS to register themselves.

For this to succeed:

- the Rancher certificate must be issued
- the certificate must be served by the ingress
- the certificate must be signed by a CA trusted by the node OS

If the certificate chain cannot be validated, node registration may fail with errors such as:

```
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

### Why Production Certificates Matter

For the full Rancher-to-RKE2 registration flow, downstream nodes must trust the Rancher endpoint with the OS trust store. Let's Encrypt staging certificates are not trusted by default, so this repository uses a Let's Encrypt production `ClusterIssuer` for the complete join flow.

### Verifying Rancher TLS

Check the certificate served by Rancher:

```bash
echo | openssl s_client -connect rancher.<ip>.nip.io:443 -servername rancher.<ip>.nip.io 2>/dev/null | openssl x509 -noout -issuer -subject -dates
```

Example expected output:

```
issuer=C = US, O = Let's Encrypt, CN = R3
subject=CN = rancher.<ip>.nip.io
```

### Checking Certificate Status in Kubernetes

Verify that cert-manager successfully issued the certificate:

```bash
kubectl -n cattle-system get certificate
```

Expected:

```
NAME                  READY   SECRET
tls-rancher-ingress   True    tls-rancher-ingress
```

You can also inspect details:

```bash
kubectl -n cattle-system describe issuer rancher
kubectl -n cattle-system describe certificate tls-rancher-ingress
```

### Key Takeaway

Even if the Rancher API responds successfully (for example `/ping` returns `pong`), downstream cluster provisioning may still fail if the TLS certificate chain is not trusted by the nodes.

Ensuring a valid and trusted TLS certificate for Rancher is therefore a critical step in the provisioning workflow.


## Disclaimer

This repository is a **learning and experimentation project** designed to demonstrate a platform engineering workflow using Terraform, Rancher, and RKE2.

It is **not intended to represent production-ready infrastructure**.
