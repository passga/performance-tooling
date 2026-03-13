variable "aws_region" {
  type = string
}

variable "aws_zone" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_id" {
  type = string
}

variable "ec2_security_group_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "access_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "workload_cluster_name" {
  type        = string
  description = "Name of the workload cluster"

  validation {
    condition     = length(var.workload_cluster_name) > 0
    error_message = "cluster name cannot be empty"
  }
}

variable "workload_kubernetes_version" {
  type        = string
  description = "Kubernetes version used for the cluster"
}

variable "windows_prefered_cluster" {
  type        = bool
  description = "Enable windows support for the cluster"
  default     = false
}

variable "prefix" {
  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.prefix)) > 0
    error_message = "prefix cannot be empty"
  }
}
