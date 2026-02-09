# Rancher on k3s – Terraform Proof of Concept (AWS)

This repository contains a **clean, reproducible Proof of Concept** to deploy **Rancher on top of k3s**, running on **AWS EC2**, fully automated with **Terraform**.

The goal of this POC is **not** to hide complexity, but to demonstrate:
- correct infrastructure layering
- clean Terraform modularization
- proper handling of TLS, CRDs, and bootstrapping constraints
- production-grade reasoning applied to a small setup

---

## 🎯 Objectives

- Deploy **k3s** on a single EC2 instance using `cloud-init`
- Install **cert-manager** and **Rancher** using Terraform (Helm + Kubernetes providers)
- Use **valid TLS** (no `insecure_skip_tls_verify`)
- Ensure **reproducibility** (stable IP, deterministic flow)
- Clearly separate **infrastructure** and **Kubernetes addons**

---

## 🧱 Architecture Overview

AWS  
└── EC2 (k3s server)  
    ├── k3s (single-node cluster)  
    ├── Traefik (default ingress)  
    ├── cert-manager  
    │   └── CRDs + ClusterIssuer (Let's Encrypt)  
    └── Rancher  
        └── HTTPS via nip.io + cert-manager  

Key points:
- Elastic IP ensures a stable public endpoint
- nip.io provides DNS without external dependencies
- tls-san is configured in k3s to avoid x509 errors
- No insecure flags are used for Kubernetes or Rancher

---

## 📁 Repository Structure

terraform/
├── aws-root/               # Infrastructure root (AWS + k3s)  
├── addons-root/            # Kubernetes addons root (cert-manager + Rancher)  
├── modules/                # Reusable Terraform modules  
├── kube/                   # Generated kubeconfig (gitignored)  
└── scripts/                # Helper scripts  

---

## 🚀 Deployment Flow

### Phase 1 – Infrastructure + k3s

```bash
terraform -chdir=terraform/aws-root apply
```

This step:
- creates AWS networking
- provisions the EC2 instance
- installs k3s via cloud-init
- attaches an Elastic IP

---

### Phase 2 – Fetch kubeconfig

```bash
./scripts/fetch-kubeconfig.sh
```

This script:
- fetches `/etc/rancher/k3s/k3s.yaml`
- rewrites the API endpoint to the public IP
- stores it under `terraform/kube/k3s.yaml`

---

### Phase 3 – Kubernetes Addons

```bash
terraform -chdir=terraform/addons-root apply
```

This installs:
- cert-manager (with CRDs)
- Rancher (via Helm)
- Rancher bootstrap (admin password, token)

---

## 🔐 TLS Strategy

- cert-manager is installed with CRDs enabled
- a `ClusterIssuer` (Let's Encrypt) is created
- Rancher ingress uses a valid TLS certificate
- No `insecure_skip_tls_verify` flags are used

---

## ⚠️ Known Terraform Constraints (Handled Explicitly)

Terraform cannot model:
- file generation outside the graph (kubeconfig)
- CRD availability timing
- API readiness

Solutions used:
- two Terraform roots
- explicit wait barriers (`null_resource`)
- documented execution order

These are intentional and documented decisions.

---

## 🧠 Interview Notes

This POC demonstrates:
- understanding of Terraform dependency graph limits
- clean separation between infra and cluster addons
- real-world Kubernetes TLS bootstrapping
- pragmatic DevOps decision-making

---

## ✅ Status

- Rancher UI reachable over HTTPS
- cert-manager operational
- Fully reproducible POC
