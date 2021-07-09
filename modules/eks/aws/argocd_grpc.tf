resource "kubernetes_service" "argocd_grpc" {
  metadata {
    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP2"
    }
    labels      = {
      app       = "argogrpc"
    }
    name        = "argogrpc"
    namespace   = "argocd"
  }

  spec {
    port {
      name        = "80"
      port        = 80
      protocol    = "TCP"
      target_port = 8080
    }

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    session_affinity = "None"

    type = "NodePort"
  }
}
