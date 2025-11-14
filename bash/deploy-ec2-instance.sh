#!/usr/bin/env bash

# Fail on unset variables, non-zero exit codes, and pipeline errors
set -euo pipefail
IFS=$'\n\t'

# Region can be overridden by environment
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-2}"

# read user data
user_data=$(cat user-data.sh)

# Allow a prefix to be specified from the environment, otherwise use 'sample-app'
name_prefix="${NAME_PREFIX:-sample-app}"
# Use a timestamp + random suffix so repeated runs create unique resources
suffix="$(date +%Y%m%d%H%M%S)-$RANDOM"

group_name="${name_prefix}-${suffix}-sg"
instance_name="${name_prefix}-${suffix}-instance"

echo "Creating security group '$group_name' in $AWS_DEFAULT_REGION..."
security_group_id=$(aws ec2 create-security-group \
  --group-name "$group_name" \
  --description "Allow HTTP traffic into the sample app" \
  --output text \
  --query GroupId) || {
  # If creation fails (rare because name is unique), try to find an existing one
  echo "Create-security-group failed, attempting to find existing group id for $group_name" >&2
  security_group_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$group_name" --query 'SecurityGroups[0].GroupId' --output text)
  if [ -z "${security_group_id}" ] || [ "${security_group_id}" = "None" ]; then
    echo "Failed to create or find security group '$group_name'." >&2
    exit 1
  fi
}

echo "Authorizing ingress on security group $security_group_id (port 80)..."
# Ignore error if the rule already exists (defensive)
aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 80 \
  --cidr "0.0.0.0/0" > /dev/null || true

echo "Finding latest Amazon Linux 2023 AMI..."
image_id=$(aws ec2 describe-images \
  --owners amazon \
  --filters 'Name=name,Values=al2023-ami-2023.*-x86_64' \
  --query 'reverse(sort_by(Images, &CreationDate))[:1] | [0].ImageId' \
  --output text)

if [ -z "${image_id}" ] || [ "${image_id}" = "None" ]; then
  echo "Could not find a suitable AMI." >&2
  exit 1
fi

echo "Launching instance named '$instance_name'..."
instance_id=$(aws ec2 run-instances \
  --image-id "$image_id" \
  --instance-type "t2.micro" \
  --security-group-ids "$security_group_id" \
  --user-data "$user_data" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
  --output text \
  --query Instances[0].InstanceId)

echo "Waiting for instance to get a public IP..."
public_ip=""
for i in {1..30}; do
  public_ip=$(aws ec2 describe-instances \
    --instance-ids "$instance_id" \
    --output text \
    --query 'Reservations[*].Instances[*].PublicIpAddress') || true
  if [ -n "$public_ip" ] && [ "$public_ip" != "None" ]; then
    break
  fi
  sleep 2
done

echo "Instance ID = $instance_id"
echo "Instance Name = $instance_name"
echo "Security Group ID = $security_group_id"
echo "Public IP = $public_ip"