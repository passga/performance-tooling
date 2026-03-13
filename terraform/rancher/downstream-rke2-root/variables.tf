variable "access_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "secret_key" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}

variable "cloud_credential_id" {
  type        = string
  description = "Existing Rancher cloud credential secret name/id to reuse instead of creating a new one."
  default     = null
  nullable    = true
}


variable "instance_type" {
  type = string
}

variable "rancher_server_dns" {
  type = string
}

variable "rancher_insecure" {
  type    = bool
  default = false
}

variable "workload_cluster_name" {
  type = string

  validation {
    condition     = length(trimspace(var.workload_cluster_name)) > 0
    error_message = "workload_cluster_name cannot be empty"
  }
}

variable "workload_kubernetes_version" {
  type = string
}

variable "windows_prefered_cluster" {
  type    = bool
  default = false
}

variable "prefix" {
  type    = string
  default = ""

  validation {
    condition     = length(trimspace(var.prefix)) > 0
    error_message = "prefix cannot be empty"
  }
}
