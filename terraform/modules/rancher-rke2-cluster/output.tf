output "cluster_id" {
  value = rancher2_cluster_v2.cluster.id
}

output "cluster_name" {
  value = rancher2_cluster_v2.cluster.name
}

output "project_id" {
  value = rancher2_project.init_project.id
}

output "namespace_id" {
  value = rancher2_namespace.init_namespace.id
}