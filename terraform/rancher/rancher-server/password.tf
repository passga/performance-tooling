resource "random_password" "rancher_admin" {
  length  = 20
  special = true
}
