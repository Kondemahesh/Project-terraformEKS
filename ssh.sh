#!/bin/bash

BASTION_IP=$(terraform output -raw bastion_ip)
EKS_ENDPOINT=$(terraform output -raw eks_endpoint)
KEY=~/.ssh/<your-key>.pem

echo "Starting SSH tunnel..."
ssh -i "$KEY" -N -L 8001:${EKS_ENDPOINT}:443 ec2-user@${BASTION_IP} &
SSH_PID=$!

echo "Tunnel running (PID $SSH_PID), applying Terraform..."
terraform apply

echo "Killing tunnel..."
kill $SSH_PID
