provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "kubernetes_namespace" "metrics_server" {
  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
  metadata {
    name = "metrics-server"
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = kubernetes_namespace.metrics_server.metadata[0].name
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  values = [
    <<EOF
args:
  - --kubelet-insecure-tls
  - --kubelet-preferred-address-types=InternalIP
EOF
  ]

  depends_on = [
    kubernetes_namespace.metrics_server
  ]
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  depends_on = [
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]
  metadata {
    name = "cluster-autoscaler"
  }
}

resource "helm_release" "cluster_autoscaler" {
  name = "cluster-autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = local.cluster_autoscaler_ns

  values = [
    <<EOF
autoDiscovery:
  clusterName: "${var.cluster_name}"
  tags:
    - "k8s.io/cluster-autoscaler/${var.cluster_name}=owned"
    - "k8s.io/cluster-autoscaler/enabled=true"


cloudProvider: aws
awsRegion: "${var.aws_region}"

rbac:
    create: true
    automountServiceAccountToken: true
    clusterScoped: true
    serviceAccount:
      name: ${local.cluster_autoscaler_sa}
      annotations:
        eks.amazonaws.com/role-arn: "${module.cluster_autoscaler_irsa_role.iam_role_arn}"

podAnnotations:
  cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
EOF
  ]

  depends_on = [
    kubernetes_namespace.cluster_autoscaler,
    module.cluster_autoscaler_irsa_role,
    helm_release.metrics_server,
  ]
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-deployment"
    namespace = "default"
    labels = {
      app = "nginx"
    }
  }
  depends_on = [
    helm_release.cluster_autoscaler,
    helm_release.metrics_server,
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx_hpa" {
  metadata {
    name      = "nginx-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 1
    max_replicas = 4

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_lb" {

  depends_on = [
    helm_release.cluster_autoscaler,
    helm_release.metrics_server,
    data.aws_eks_cluster.cluster,
    data.aws_eks_cluster_auth.cluster
  ]

  metadata {
    name      = "nginx-service"
    namespace = "default"
    labels = {
      app = "nginx"
    }
  }

  spec {
    selector = {
      app = "nginx"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}
