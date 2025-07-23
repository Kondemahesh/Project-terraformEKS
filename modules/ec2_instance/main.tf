data "aws_iam_policy_document" "AssumeRolePolicy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "var.role_name"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.AssumeRolePolicy.json
}

data "aws_iam_policy" "this" {
  for_each = { for k, v in var.iam_policies : v => k }
  name     = each.key
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = { for k, v in var.iam_policies : v => k }
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.this[each.key].arn
}

resource "aws_iam_instance_profile" "this" {
  name = "amazon-mahesh-role"
  role = aws_iam_role.this.name
}


data "aws_ami" "example" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

 }

output "aws_ami" {

   value = data.aws_ami.example.id

 }

resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.this.name
  vpc_security_group_ids  = [aws_security_group.bastion_server.id]
             key_name  =         aws_key_pair.bastion.key_name
   subnet_id      = var.subnet_id

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y

              # Install required packages
              apt-get install -y unzip curl apt-transport-https ca-certificates gnupg lsb-release

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Install kubectl
              curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
              echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
              apt-get update -y
              apt-get install -y kubectl

              # Configure AWS CLI (write credentials file directly)
              mkdir -p /root/.aws
              echo "[default]" > /root/.aws/credentials
              echo "aws_access_key_id = AKIAUTCWGAA3DPENGK5V" >> /root/.aws/credentials
              echo "aws_secret_access_key = 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" >> /root/.aws/credentials

              echo "[default]" > /root/.aws/config
              echo "region = us-east-1" >> /root/.aws/config
              echo "output = json" >> /root/.aws/config

              # Export AWS variables (optional for CLI use)
              export AWS_ACCESS_KEY_ID=*****
              export AWS_SECRET_ACCESS_KEY=***
              export AWS_DEFAULT_REGION=***

              # Confirm success
              echo "AWS CLI and kubectl are configured" > /tmp/kube-setup-success.txt
              EOF


  tags = {
    Name = var.instance_name
  }
}


resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "kubec"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion.private_key_pem
  filename = "${path.module}/kubec.pem"
  file_permission = "0400"
}




resource "aws_security_group"  "bastion_server" {
   name = "Bastion-server-sg"
   vpc_id = var.vpc_id

   ingress {
     description = " open port 22"
     from_port   =  22
     to_port     =  22
     protocol    =  "tcp"
      cidr_blocks  =  ["0.0.0.0/0"]

}

egress { 
  from_port = 0
  to_port   = 0
  protocol  =  "-1"
  cidr_blocks  = ["0.0.0.0/0"]

}


}
