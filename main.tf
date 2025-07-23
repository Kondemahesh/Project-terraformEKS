

module "eks" {
  source       = "./modules/eks"
  cluster_name =  local.cluster_name
  subnet_ids   = module.vpc.public_subnet_ids
  cluster_version = "1.29"
          vpc_id =   module.vpc.vpc_id

}

data "aws_eks_cluster" "eks" {
#  name = module.eks.cluster_name
   name = "dev-eks-cluster"
   depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token

}

#data "aws_eks_cluster" "eks" {
#  name       = aws_eks_cluster.eks.name
#  depends_on = [module.eks]
#}
#
#data "aws_eks_cluster_auth" "eks" {
#  name = "aws_eks_cluster.eks.name"
#}
#

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])

    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::315860844598:user/root"
        username = "root"
        groups   = ["system:masters"]
      },
      {
        userarn  = "arn:aws:iam::315860844598:user/eks-admin-user"
        username = "eks-admin-user"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [module.eks]
}



locals {

  cluster_name = "dev-eks-cluster"

}


data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}



module "ec2_instance" {
  source         = "./modules/ec2_instance"
  instance_type  = "t2.micro"
  ami_id        =  data.aws_ami.example.id
  instance_name  = "kubectl"
     vpc_id      = module.vpc.vpc_id
   subnet_id   = module.vpc.public_subnet_ids[0]
}


module "vpc" {
  source         = "./modules/vpc"
  ProjectName    = "astacms_app"
  vpc_cidr       = "10.0.0.0/16"

}            

#module "eks" {
#  source       = "./modules/eks"
#  cluster_name =  local.cluster_name
#  subnet_ids   = module.vpc.public_subnet_ids
#  cluster_version = "1.29"
#          vpc_id =   module.vpc.vpc_id
#}
