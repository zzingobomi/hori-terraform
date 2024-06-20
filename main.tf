provider "aws" {
  region  = local.region
  profile = "admin"
}

locals {
  region       = "ap-northeast-2"
  cluster_name = "hori"
  allow_ips    = [
    "125.180.153.109/32",     // zzingo home
    "211.192.203.180/32"      // office
  ]
  ssh_key_name = "zzingo_key"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.cluster_name}-vpc"
  cidr = "192.168.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["192.168.1.0/24", "192.168.2.0/24"]
  private_subnets = ["192.168.3.0/24", "192.168.4.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true  

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_security_group" "eksctl_host_sg" {
  name        = "${local.cluster_name}-host-sg"
  description = "eksctl-host Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.allow_ips
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.cluster_name}-host-sg"
  }
}

# data "template_file" "init" {
#   template = "${file("${path.module}/init.tpl")}"
#   vars = {
#     consul_address = "${aws_instance.consul.private_ip}"
#   }
# }

resource "aws_instance" "eksctl_host" {
  ami                         = "ami-0ebb3f23647161078"
  instance_type               = "t3.medium"
  key_name                    = local.ssh_key_name
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = "192.168.1.100"

  vpc_security_group_ids = [ aws_security_group.eksctl_host_sg.id ]  

  tags = {
    Name = "${local.cluster_name}-host"
  }

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  user_data = templatefile("./scripts/init.tftpl", {
    cluster_name = local.cluster_name
    region       = local.region
  })  
}

output "eksctlhost" {
  value = aws_instance.eksctl_host.public_ip
}