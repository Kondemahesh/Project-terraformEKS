variable "iam_policies" {
 description = "Map IAM Policies Labels to aws managed policie names"
 type = map(string)
 default = {}
}


variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Name tag for EC2 instance"
  type        = string
  default     = "web_instance"
}

variable "role_name" {
  description = "IAM role name"
  type        = string
  default     = "mahesh-role"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "List of subnet IDs for the EKS cluster"
}
