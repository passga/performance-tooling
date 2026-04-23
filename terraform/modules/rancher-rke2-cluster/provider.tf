terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 13.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
