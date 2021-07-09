locals {
}

resource "aws_iam_policy" "external_dns" {
  name = "AWSExternalDNSIAMPolicy"

  # source: https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
  policy = file("${path.module}/external_dns_iam_policy.json")
}

module "iam_assumable_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.0.0"
  create_role                   = true
  number_of_role_policy_arns    = 1
  role_name                     = format("external-dns-%s", var.cluster_name)
  provider_url                  = replace(module.cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:external-dns:external-dns"]
}

#resource "kubernetes_namespace" "external_dns" {
#  metadata {
#    name = local.external_dns_namespace
#  }
#}
#
#resource "kubernetes_service_account" "external_dns" {
#  metadata {
#    name      = local.external_dns_service_account_name
#    namespace = local.external_dns_namespace
#
#    annotations = {
#      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_external_dns.iam_role_arn
#    }
#  }
#}
#
#resource "kubernetes_cluster_role" "external_dns" {
#  metadata {
#    name = "external-dns"
#  }
#
#  rule {
#    api_groups = [""]
#    resources = ["services","endpoints","pods"]
#    verbs     = ["get","watch","list"]
#  }
#
#  rule {
#    api_groups = ["extensions","networking.k8s.io"]
#    resources = ["ingresses"]
#    verbs     = ["get","watch","list"]
#  }
#
#  rule {
#    api_groups = [""]
#    resources = ["nodes"]
#    verbs     = ["list","watch"]
#  }
#}
#
#resource "kubernetes_cluster_role_binding" "external_dns" {
#  metadata {
#    name = "external-dns-viewer"
#  }
#
#  role_ref {
#    api_group = "rbac.authorization.k8s.io"
#    kind     = "ClusterRole"
#    name     = "external-dns"
#  }
#
#  subject {
#    kind      = "ServiceAccount"
#    name      = "external-dns"
#    namespace = local.external_dns_namespace
#  }
#}
#
#resource "kubernetes_deployment" "external_dns" {
#  metadata {
#    name      = "external-dns"
#    namespace = local.external_dns_namespace
#  }
#
#  spec {
#    strategy {
#      type = "Recreate"
#    }
#  
#    selector {
#      match_labels = {
#        app = "external-dns"
#      }
#    }
#  
#    template {
#      metadata {
#        labels = {
#          app = "external-dns"
#        }
#      }
#  
#      spec {
#        service_account_name = local.external_dns_service_account_name
#  
#        container {
#          name = "external-dns"
#          image = "k8s.gcr.io/external-dns/external-dns:v0.7.6"
#          args = [
#            "--source=service",
#            "--source=ingress",
#            "--domain-filter=${var.base_domain}",
#            "--provider=aws",
#            "--policy=sync",
#            "--registry=txt",
#            "--txt-owner-id=${var.route53_zone_id}",
#          ]
#        }
#  
#        security_context {
#          fs_group = "65534"
#        }
#      }
#    }
#
#  }
#}
