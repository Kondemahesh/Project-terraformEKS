variable "iam_policies" {
 description = "Map IAM Policies Labels to aws managed policie names"
 type = map(string)
 default = {}
}
