
#data "aws_eks_cluster" "eks" {
#  name       = aws_eks_cluster.eks.name
#  depends_on = [aws_eks_cluster.eks]
#}
#
#data "aws_eks_cluster_auth" "eks" {
#  name = "aws_eks_cluster.eks.name"
#}
#
#resource "kubernetes_config_map" "aws_auth" {
#  metadata {
#    name      = "aws-auth"
#    namespace = "kube-system"
#  }
#
#  data = {
#    mapRoles = yamlencode([
#
#    {
#        rolearn  = aws_iam_role.eks_node_role.arn
#        username = "system:node:{{EC2PrivateDNSName}}"
#        groups   = [
#          "system:bootstrappers",
#          "system:nodes"
#        ]
#      },
#
#      {
#        rolearn  = "arn:aws:iam::315860844598:role/root"  # Replace with your IAM role
#        username = "root"
#        groups   = ["system:masters"]
#      }
#    ])
#  }
#
#  depends_on = [aws_eks_cluster.eks]
#}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version = var.cluster_version
  


  vpc_config {
    subnet_ids = var.subnet_ids
    endpoint_public_access  = true

  }



  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]

access_config {
    authentication_mode = "API_AND_CONFIG_MAP"  
  }

}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3.medium"]

       remote_access { 
          ec2_ssh_key = aws_key_pair.node_group.key_name
          source_security_group_ids    = [aws_security_group.node_group.id]     
}
    

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  depends_on = [
    
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKSWorkerNodePolicy,
    aws_security_group.node_group
     
  ]
}

resource "aws_key_pair" "node_group" {
  key_name   = "node-group"
  public_key = file("~/.ssh/node-group-key.pub")
}


resource "aws_eks_access_entry" "root_access" {
 cluster_name = aws_eks_cluster.eks.name
 principal_arn = "arn:aws:iam::${var.account_id}:root" 

  type        = "STANDARD"
  user_name    = "root"


 depends_on = [aws_eks_cluster.eks]

}

resource "aws_security_group" "node_group" {
   name = "eks-node-group"
  vpc_id = var.vpc_id  
  
 ingress { 
   description = "to allow port 22"
   from_port = 22
   to_port = 22
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]

}

  ingress {
  description = "open port 80"
  from_port  = 80
  to_port    = 80
  protocol   = "tcp"
  cidr_blocks  = ["0.0.0.0/0"]
}

  ingress {
  description = "allow 443 port"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks  = ["0.0.0.0/0"]

}

  egress { 
    description = "allow all traffic" 
    from_port = 0 
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]

}
 
tags = {
   Name = "eks-node-group"
}
}


data "aws_eks_addon_version" "vpc_cni" {
  addon_name   = "vpc-cni"
  kubernetes_version = var.cluster_version
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
  addon_version = data.aws_eks_addon_version.vpc_cni.version
  depends_on = [aws_eks_cluster.eks]

}

data "aws_eks_addon_version" "coredns" {
  addon_name   = "coredns"
  kubernetes_version  = var.cluster_version

}


resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
  addon_version = data.aws_eks_addon_version.coredns.version
  
  depends_on = [aws_eks_cluster.eks]

}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name  = "kube-proxy"
  kubernetes_version  = var.cluster_version
  most_recent = true
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
  addon_version = data.aws_eks_addon_version.kube_proxy.version

  depends_on = [aws_eks_cluster.eks]

}



#data "aws_eks_addon_version" "node_monitoring" {
#  addon_name  = "eks-node-viewer"
#  kubernetes_version  = var.cluster_version
#  most_recent = true
#  
#
#}
#
#resource "aws_eks_addon" "node_monitoring" {
#  cluster_name = aws_eks_cluster.eks.name
#  addon_name   = "eks-node-viewer"
#  addon_version = data.aws_eks_addon_version.node_monitoring.version
#
#
#  depends_on = [aws_eks_cluster.eks]
#
#
#
#}

data "aws_eks_addon_version" "pod_identity_agent" {
  addon_name  = "eks-pod-identity-agent"
  kubernetes_version  = var.cluster_version
  most_recent = true
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "eks-pod-identity-agent"
  addon_version  = data.aws_eks_addon_version.pod_identity_agent.version
  depends_on = [aws_eks_cluster.eks]

}
