variable "aws_region" {
  default = "us-east-1"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the EKS cluster"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "315860844598"
}

variable "cluster_version" {
  description = "Kubernetes Version for the EKS Cluster"
  type   =  string

}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

