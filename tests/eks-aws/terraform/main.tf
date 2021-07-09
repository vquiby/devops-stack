locals {
  base_domain = "demo.camptocamp.com"
  cluster_name = "devops-stack-eks-test"
  route53_zone_id = "Z018482835V1BDP1L63A0"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name = local.cluster_name
  cidr = "10.0.0.0/16"

  azs = data.aws_availability_zones.available.names

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
  ]

  public_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24",
  ]

  # NAT Gateway Scenarios : One NAT Gateway per availability zone
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}

module "cluster" {
  source = "../../../modules/eks/aws"

  cluster_name    = local.cluster_name
  cluster_version = "1.19"
  vpc_id          = module.vpc.vpc_id

  worker_groups = [
    {
      instance_type        = "m5a.large"
      asg_desired_capacity = 2
      asg_max_size         = 3
    }
  ]

  base_domain     = local.base_domain
  #route53_zone_id = module.route53_zone.route53_zone_zone_id[local.base_domain]
  route53_zone_id = local.route53_zone_id

  cognito_user_pool_id     = aws_cognito_user_pool.this.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.this.domain

  repo_url        = var.repo_url
  target_revision = var.target_revision

  extra_apps = [
    {
      metadata = {
        name = "demo-app"
      }
      spec = {
        project = "default"

        source = {
          path           = "tests/eks-aws/argocd/demo-app"
          repoURL        = var.repo_url
          targetRevision = var.target_revision

          helm = {
            values = <<EOT
spec:
  source:
    repoURL: ${var.repo_url}
    targetRevision: ${var.target_revision}

baseDomain: ${local.base_domain}
          EOT
          }
        }

        destination = {
          namespace = "demo-app"
          server    = "https://kubernetes.default.svc"
        }

        syncPolicy = {
          automated = {
            selfHeal = true
          }
        }
      }
    }
  ]
}

#resource "aws_security_group_rule" "workers_ingress_http" {
#  security_group_id = module.cluster.worker_security_group_id
#
#  type        = "ingress"
#  protocol    = "tcp"
#  from_port   = "80"
#  to_port     = "80"
#  cidr_blocks = ["0.0.0.0/0"]
#}
#
#resource "aws_security_group_rule" "workers_ingress_https" {
#  security_group_id = module.cluster.worker_security_group_id
#
#  type        = "ingress"
#  protocol    = "tcp"
#  from_port   = "443"
#  to_port     = "443"
#  cidr_blocks = ["0.0.0.0/0"]
#}

resource "aws_cognito_user_pool" "this" {
  name = local.cluster_name
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = local.cluster_name
  user_pool_id = aws_cognito_user_pool.this.id
}
