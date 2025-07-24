
variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ProjectName" {
  description = "Name for the resource"
  type        = string
  default     = "global-communication-app"
}

