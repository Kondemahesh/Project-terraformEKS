output "role_name" {
  value = aws_iam_role.this.name
}

output "public_ip" {
   value = "aws_instance.web_server.public_ip" 
}

