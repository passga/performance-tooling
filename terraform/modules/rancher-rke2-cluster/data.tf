data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_instances" "downstream_nodes" {
  depends_on = [terraform_data.wait_for_cluster_readiness]

  filter {
    name   = "tag:tf-aws-platform-cluster"
    values = [var.workload_cluster_name]
  }

  filter {
    name   = "tag:tf-aws-platform-component"
    values = ["downstream-rke2"]
  }

  filter {
    name   = "tag:tf-aws-platform-managed"
    values = ["true"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
