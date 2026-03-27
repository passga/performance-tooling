variable "downstream_node_instance_profile_name" {
  type        = string
  description = "Existing IAM instance profile name attached to downstream RKE2 EC2 nodes."
}

variable "aws_load_balancer_controller_chart_version" {
  type        = string
  description = "Helm chart version for aws-load-balancer-controller."
  default     = "1.14.0"
}
