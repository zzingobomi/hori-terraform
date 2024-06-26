provider "aws" {
  region  = local.region
  profile = "admin"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"    
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"      
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  name   = var.cluster_name
  region = var.aws_region

  # allowed_ip_ranges = [
  #   "125.180.153.109/32",     // zzingo home  
  # ]
  # key_name = "zzingo_key"

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}-vpc"
  cidr = "192.168.0.0/16"

  # azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  # public_subnets  = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  # private_subnets = ["192.168.11.0/24", "192.168.12.0/24", "192.168.13.0/24"]

  azs             = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets  = ["192.168.1.0/24", "192.168.2.0/24"]
  private_subnets = ["192.168.11.0/24", "192.168.12.0/24"]

  enable_dns_support      = true
  enable_dns_hostnames    = true

  enable_nat_gateway      = true
  single_nat_gateway      = true  

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = local.tags
}

################################################################################
# EKS Cluster
################################################################################

resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "ExternalDNSPolicy"
  description = "Policy for ExternalDNSChangeSet and ExternalDNSHostedZones"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        Resource = "*",
        Condition = {
          StringEqualsIfExists: {
            "aws:RequestTag/ExternalDNSChangeSet": "true",
            "aws:RequestTag/ExternalDNSHostedZones": "true"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "route53:ListHostedZones",
        Resource = "*"
      }
    ]
  })
}

#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.name
  cluster_version                = "1.29"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      name                     = "${local.name}-node-group"
      #instance_types           = ["t3.medium"]
      instance_types           = ["m5.large"]
      max_size                 = 2
      min_size                 = 2
      desired_size             = 2
      iam_role_name            = "${local.name}-node-group-eks-node-group"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        "${local.name}ExternalDNSPolicy" = aws_iam_policy.external_dns_policy.arn
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  access_entries = {    
    admin = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.eks_cluster_role.arn

      policy_associations = {
        myeks = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {  
            type       = "cluster"
          }
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Add-ons
  enable_aws_load_balancer_controller    = true

  enable_metrics_server                  = true

  enable_kube_prometheus_stack           = true
  kube_prometheus_stack = {    
    values = [templatefile("${path.module}/custom-values/grafana/values-dev.yaml", {})]
  }

  enable_external_dns                    = true

  enable_cert_manager                    = true

  enable_argocd                          = true
  argocd = {    
    values = [templatefile("${path.module}/custom-values/argocd/values-dev.yaml", {})]
  }

  enable_argo_rollouts                   = true

  cert_manager_route53_hosted_zone_arns  = ["arn:aws:route53:::hostedzone/${var.hosted_zone_id}"]  

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

# resource "aws_security_group" "bastion_sg" {
#   name        = "bastion-sg"
#   description = "Security group for bastion host"
  
#   vpc_id = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = local.allowed_ip_ranges
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "bastion_host" {
#   ami             = "ami-0ebb3f23647161078"
#   instance_type   = "t2.micro"
#   key_name        = local.key_name
#   subnet_id       = module.vpc.public_subnets[0]
#   security_groups = [aws_security_group.bastion_sg.id]

#   associate_public_ip_address = true

#   tags = merge(
#     local.tags,
#     {
#       Name = "bastion-host"
#     }
#   )
# }

resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  chart            = "${path.module}/helm/argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
}

resource "helm_release" "kube_ops_view" {
  name             = "kube-ops-view"
  chart            = "${path.module}/helm/kube-ops-view"
  namespace        = "kube-system"
}

resource "helm_release" "mysql_operator" {
  name             = "mysql-operator"
  chart            = "${path.module}/helm/mysql-operator"
  namespace        = "mysql-operator"
  create_namespace = true  
}

resource "helm_release" "mysql_cluster" {
  name             = "mysql-cluster"
  chart            = "${path.module}/helm/mysql-innodbcluster"
  namespace        = "mysql-cluster"
  create_namespace = true  

  set {
    name  = "credentials.root.password"
    value = var.mysql_password
  }

  set {
    name  = "tls.useSelfSigned"
    value = "true"
  }
}

resource "helm_release" "loki_stack" {
  name             = "loki-stack"
  chart            = "${path.module}/helm/loki-stack"
  namespace        = "loki-stack"
  create_namespace = true  
}