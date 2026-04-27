output "traefik_load_balancer_hostname" {
  description = "DNS hostname assigned by AWS to the downstream Traefik LoadBalancer service."
  value       = data.kubernetes_service.rke2_traefik.status[0].load_balancer[0].ingress[0].hostname
}

output "traefik_load_balancer_zone_id" {
  description = "Canonical hosted zone id of the downstream Traefik AWS load balancer."
  value       = data.aws_lb.traefik.zone_id
}
