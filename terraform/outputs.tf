output "cluster_name" {
  value = var.cluster_name
}

output "load_balancer_hostname" {
  value = kubernetes_service.nginx_lb.status.0.load_balancer.0.ingress.0.hostname
}

output "eks_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}
