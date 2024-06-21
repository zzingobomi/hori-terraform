provider "aws" {
  region  = local.region
  profile = "admin"
}
locals {
  region        = "ap-northeast-2"
  cluster_name  = "hori"  
  ssh_key_name  = "zzingo_key"  
  instance_type = "t3.medium"
  allow_ips     = [
    "125.180.153.109/32",     // zzingo home
    "211.192.203.180/32"      // office
  ]
}

///
/// VPC
/// 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.cluster_name}-vpc"
  cidr = "192.168.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnets  = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  private_subnets = ["192.168.11.0/24", "192.168.12.0/24", "192.168.13.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true
  map_public_ip_on_launch = true  

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

///
/// EKS
///
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.cluster_name}-cluster-role"

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


module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "~> 20.0"
  
  cluster_name                    = local.cluster_name
  cluster_version                 = "1.29"

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.public_subnets

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }  

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    default = {
      name = "${local.cluster_name}-node-group"
      use_name_prefix = false
      min_size     = 1
      max_size     = 4
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  enable_cluster_creator_admin_permissions = true

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

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}



///
/// Bastion Host
///
# resource "aws_security_group" "eksctl_host_sg" {
#   name        = "${local.cluster_name}-host-sg"
#   description = "eksctl-host Security Group"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = local.allow_ips
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${local.cluster_name}-host-sg"
#   }
# }

# resource "aws_instance" "eksctl_host" {
#   ami                         = "ami-0ebb3f23647161078"
#   instance_type               = local.instance_type
#   key_name                    = local.ssh_key_name
#   subnet_id                   = element(module.vpc.public_subnets, 0)
#   associate_public_ip_address = true
#   private_ip                  = "192.168.1.100"

#   vpc_security_group_ids = [ aws_security_group.eksctl_host_sg.id ]  

#   tags = {
#     Name = "${local.cluster_name}-host"
#   }

#   ebs_block_device {
#     device_name           = "/dev/xvda"
#     volume_type           = "gp3"
#     volume_size           = 20
#     delete_on_termination = true
#   }

#   user_data = templatefile("./scripts/init.tftpl", {
#     cluster_name  = local.cluster_name
#     region        = local.region
#   }) 
# }

# output "eksctlhost" {
#   value = aws_instance.eksctl_host.public_ip
# }

