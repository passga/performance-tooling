data "terraform_remote_state" "aws_root" {
  backend = "local"

  config = {
    path = "../../aws-root/terraform.tfstate"
  }
}

data "terraform_remote_state" "rancher_server" {
  backend = "local"

  config = {
    path = "../rancher-server-root/terraform.tfstate"
  }
}
