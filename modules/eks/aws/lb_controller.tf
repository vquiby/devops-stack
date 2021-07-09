locals {
  lb_controller_service_account_name = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "lb_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy"

  # source: https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json
  policy = file("${path.module}/lb_controller_iam_policy.json")
}

module "iam_assumable_role_lb_controller" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.0.0"
  create_role                   = true
  number_of_role_policy_arns    = 1
  role_name                     = format("aws-lb-controller-%s", var.cluster_name)
  provider_url                  = replace(module.cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.lb_controller.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:${local.lb_controller_service_account_name}"]
}

resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = local.lb_controller_service_account_name
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_lb_controller.iam_role_arn
    }
  }
}

resource "null_resource" "lb_controller_install_crds" {
  provisioner "local-exec" {
    command = <<EOT
    KUBECONFIG=$(mktemp /tmp/kubeconfig.XXXXXX)
    echo "$KUBECONFIG_CONTENT" > "$KUBECONFIG"
    export KUBECONFIG
    for i in `seq 1 60`; do
      kubectl apply -f ${path.module}/lb_controller_crds.yaml && rm "$KUBECONFIG" && exit 0
    done
    echo TIMEOUT
    rm "$KUBECONFIG"
    exit 1
    EOT

    environment = {
      KUBECONFIG_CONTENT = local.kubeconfig
    }
  }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.2.0"

  namespace = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = local.lb_controller_service_account_name
  }

}

