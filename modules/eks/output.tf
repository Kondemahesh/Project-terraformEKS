output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "node_group_name" {
  value = aws_eks_node_group.this.node_group_name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}

output "eks_cluster_certificate_authority" {
  description = "Base64 encoded certificate data required to connect to the cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

