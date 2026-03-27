variable "aws_region" {
  type        = string
  description = "Dedicated AWS region for downstream-ingress-root. If null, fallback to aws-root remote state."
  default     = null
  nullable    = true
}

variable "downstream_node_instance_profile_name" {
  type        = string
  description = "Existing AWS IAM Instance Profile name attached to downstream RKE2 EC2 nodes."
}

variable "aws_load_balancer_controller_chart_version" {
  type        = string
  description = "Helm chart version for aws-load-balancer-controller."
  default     = "1.14.0"
}

variable "kubeconfig_path_override" {
  type        = string
  description = "Optional kubeconfig path override for downstream cluster access."
  default     = null
  nullable    = true
}
