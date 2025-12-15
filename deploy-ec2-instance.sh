#!/usr/bin/env bash
set -e

export AWS_DEFAULT_REGION="us-east-1"
user_data=$(cat user-data.sh)

# Unique suffix per run to avoid naming collisions
run_id=$(date +%Y%m%d-%H%M%S)

security_group_id=$(aws ec2 create-security-group \
  --group-name "sample-app-$run_id" \
  --description "Allow HTTP traffic into the sample app" \
  --output text \
  --query GroupId)

aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0" > /dev/null

image_id=$(aws ec2 describe-images \
  --owners amazon \
  --filters 'Name=name,Values=al2023-ami-2023.*-x86_64' \
  --query 'reverse(sort_by(Images, &CreationDate))[:1] | [0].ImageId' \
  --output text)

instance_id=$(aws ec2 run-instances \
  --image-id "$image_id" \
  --instance-type "t2.micro" \
  --security-group-ids "$security_group_id" \
  --user-data "$user_data" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=sample-app-$run_id}]" \
  --output text \
  --query Instances[0].InstanceId)

# Wait so public IP is reliably present
aws ec2 wait instance-running --instance-ids "$instance_id"

public_ip=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --output text \
  --query 'Reservations[*].Instances[*].PublicIpAddress')

echo "Instance ID = $instance_id"
echo "Security Group ID = $security_group_id"
echo "Public IP = $public_ip"