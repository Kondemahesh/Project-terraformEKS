
output "bastion_public_ip" {
  value = module.ec2_instance.public_ip
}

output "eks_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}


