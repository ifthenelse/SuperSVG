#!/bin/bash
################################################################################
# SuperSVG AWS EC2 Instance Launcher (from local machine)
#
# This script automates:
# - AMI lookup for your region
# - EC2 instance launch
# - Security group configuration
# - SSH connection details
#
# Usage: ./launch-aws-ec2.sh [--spot] [--instance-type TYPE]
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Default configuration
INSTANCE_TYPE="g5.2xlarge"
USE_SPOT=false
KEY_NAME="supersvg-key"
VOLUME_SIZE=100

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --spot)
      USE_SPOT=true
      shift
      ;;
    --instance-type)
      INSTANCE_TYPE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--spot] [--instance-type TYPE]"
      echo ""
      echo "Options:"
      echo "  --spot              Use spot instance (70% cheaper, but can be interrupted)"
      echo "  --instance-type     Instance type (default: g5.2xlarge)"
      echo ""
      echo "Examples:"
      echo "  $0                           # Launch on-demand g5.2xlarge"
      echo "  $0 --spot                    # Launch spot g5.2xlarge"
      echo "  $0 --instance-type g5.xlarge # Launch smaller instance"
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       SuperSVG AWS EC2 Instance Launcher                 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first:"
    echo "  https://aws.amazon.com/cli/"
    exit 1
fi

# Get current region
print_status "Detecting AWS region..."
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    print_error "AWS region not configured. Run: aws configure"
    exit 1
fi
print_info "Region: $REGION"

# Check if key pair exists
print_status "Checking SSH key pair..."
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
    print_warning "Key pair '$KEY_NAME' not found. Creating it..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_NAME.pem"
    chmod 600 "$KEY_NAME.pem"
    print_status "Created $KEY_NAME.pem (keep this file safe!)"
else
    print_info "Key pair '$KEY_NAME' exists"
    if [ ! -f "$KEY_NAME.pem" ]; then
        print_warning "Key file $KEY_NAME.pem not found locally"
        print_warning "If you don't have this key, you'll need to create a new one"
    fi
fi

# Find latest Ubuntu 22.04 LTS AMI
print_status "Finding latest Ubuntu 22.04 LTS AMI for $REGION..."
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
    print_error "Could not find Ubuntu 22.04 AMI in region $REGION"
    exit 1
fi
print_info "AMI ID: $AMI_ID"

# Create or get security group
print_status "Configuring security group..."
SG_NAME="supersvg-sg"
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")

if [ -z "$SG_ID" ] || [ "$SG_ID" == "None" ]; then
    print_warning "Security group '$SG_NAME' not found. Creating it..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SG_NAME" \
        --description "SuperSVG training instance security group" \
        --query 'GroupId' \
        --output text)
    
    # Allow SSH from anywhere (you may want to restrict this to your IP)
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    
    print_status "Created security group: $SG_ID"
else
    print_info "Security group ID: $SG_ID"
fi

# Launch instance
print_status "Launching EC2 instance ($INSTANCE_TYPE)..."
if [ "$USE_SPOT" = true ]; then
    print_info "Using spot instance pricing"
    INSTANCE_DATA=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$VOLUME_SIZE,VolumeType=gp3}" \
        --instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=one-time,InstanceInterruptionBehavior=terminate}' \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=supersvg-training}]" \
        --output json)
else
    print_info "Using on-demand pricing"
    INSTANCE_DATA=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$VOLUME_SIZE,VolumeType=gp3}" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=supersvg-training}]" \
        --output json)
fi

INSTANCE_ID=$(echo "$INSTANCE_DATA" | grep -o '"InstanceId": "[^"]*' | cut -d'"' -f4)

if [ -z "$INSTANCE_ID" ]; then
    print_error "Failed to launch instance"
    echo "$INSTANCE_DATA"
    exit 1
fi

print_status "Instance launched: $INSTANCE_ID"
print_info "Waiting for instance to be running..."

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
print_status "Instance is running"

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

print_status "Instance ready!"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Instance Successfully Launched              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
print_info "Instance ID: $INSTANCE_ID"
print_info "Public IP: $PUBLIC_IP"
print_info "Instance Type: $INSTANCE_TYPE"
echo ""
print_status "Next steps:"
echo ""
echo "1. Wait a minute for the instance to fully initialize, then SSH in:"
echo -e "   ${CYAN}ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP${NC}"
echo ""
echo "2. Once connected, run the setup script:"
echo -e "   ${CYAN}curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh${NC}"
echo -e "   ${CYAN}chmod +x setup-aws-ec2.sh${NC}"
echo -e "   ${CYAN}./setup-aws-ec2.sh${NC}"
echo ""
echo "3. Start training:"
echo -e "   ${CYAN}~/train_supersvg.sh${NC}"
echo ""
echo -e "${YELLOW}To terminate this instance later:${NC}"
echo -e "   ${CYAN}aws ec2 terminate-instances --instance-ids $INSTANCE_ID${NC}"
echo ""

# Save instance info to file
cat > supersvg-instance.txt <<EOF
Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Instance Type: $INSTANCE_TYPE
Spot: $USE_SPOT
Region: $REGION
Key: $KEY_NAME.pem
Launch Time: $(date)

SSH Command:
ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP

Terminate Command:
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
EOF

print_status "Instance details saved to supersvg-instance.txt"
