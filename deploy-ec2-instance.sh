#!/usr/bin/env bash

set -e

export AWS_DEFAULT_REGION="us-east-1"
user_data=$(cat user-data.sh)

# Prompt for instance name or auto-generate one
read -p "Enter a name for your EC2 instance (or press Enter to auto-generate): " instance_name
if [ -z "$instance_name" ]; then
  timestamp=$(date +%Y%m%d%H%M%S)
  instance_name="sample-app-$timestamp"
  echo "Auto-generated name: $instance_name"
fi
group_name="sample-app-$instance_name"

# Check for existing security group
security_group_id=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$group_name" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null)

if [ "$security_group_id" = "None" ]; then
  echo "Creating new security group: $group_name"
  security_group_id=$(aws ec2 create-security-group \
    --group-name "$group_name" \
    --description "Allow HTTP traffic into the sample app" \
    --output text \
    --query GroupId)

  aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0" > /dev/null
else
  echo "Reusing existing security group: $group_name"
fi

# Check for existing EC2 instance
existing_instance_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running,pending" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null)

if [ "$existing_instance_id" != "None" ]; then
  echo "Instance '$instance_name' already exists: $existing_instance_id"
  instance_id="$existing_instance_id"
else
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
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
    --output text \
    --query Instances[0].InstanceId)
fi

# Get public IP
public_ip=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --output text \
  --query 'Reservations[*].Instances[*].PublicIpAddress')

echo "Instance Name = $instance_name"
echo "Instance ID = $instance_id"
echo "Security Group ID = $security_group_id"
echo "Public IP = $public_ip"