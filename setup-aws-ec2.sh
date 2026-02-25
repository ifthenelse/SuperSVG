#!/bin/bash
################################################################################
# SuperSVG Training Setup Script for AWS EC2
#
# This script configures an AWS EC2 g5.2xlarge instance for SuperSVG training
# GPU: NVIDIA A10G (24GB VRAM)
# Recommended: Use spot instances for 70% cost savings
# On-demand: ~$1.21/hour | Spot: ~$0.36-$0.50/hour
################################################################################

set -e  # Exit on error

echo "========================================="
echo "SuperSVG AWS EC2 Setup"
echo "========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Detect instance metadata
print_status "Detecting AWS instance metadata..."
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
INSTANCE_TYPE=$(ec2-metadata --instance-type | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)

print_info "Instance ID: $INSTANCE_ID"
print_info "Instance Type: $INSTANCE_TYPE"
print_info "Availability Zone: $AVAILABILITY_ZONE"

# 1. System Update
print_status "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install AWS CLI (if not present)
print_status "Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    print_status "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# 3. Install essential tools
print_status "Installing essential tools..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    tmux \
    build-essential \
    cmake \
    unzip \
    jq \
    bc

# 4. Install NVIDIA drivers for AWS EC2 (g5 instances)
print_status "Installing NVIDIA drivers for AWS g5 instance..."

# Check if drivers are already installed
if ! command -v nvidia-smi &> /dev/null; then
    print_status "Installing NVIDIA drivers..."
    
    # AWS-specific driver installation for g5 instances
    sudo apt-get install -y linux-headers-$(uname -r)
    
    # Distribution and architecture detection
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
    
    # Add NVIDIA package repositories
    wget https://developer.download.nvidia.com/compute/cuda/repos/$distribution/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    sudo apt-get update
    
    # Install CUDA drivers (includes NVIDIA drivers)
    sudo apt-get -y install cuda-drivers
    
    # Add CUDA to PATH
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    source ~/.bashrc
    
    rm cuda-keyring_1.0-1_all.deb
else
    print_status "NVIDIA drivers already installed"
fi

# Verify NVIDIA GPU
print_status "Verifying NVIDIA GPU..."
nvidia-smi || print_error "GPU verification failed. You may need to reboot the instance."

# 5. Install Docker
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
    sudo usermod -aG docker $(whoami)
    rm get-docker.sh
else
    print_status "Docker already installed"
fi

# 6. Install NVIDIA Container Toolkit
print_status "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit nvidia-docker2
sudo systemctl restart docker

# Verify GPU access in Docker
print_status "Verifying Docker GPU access..."
sudo docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# 7. Clone SuperSVG repository
REPO_DIR="$HOME/SuperSVG"
if [ ! -d "$REPO_DIR" ]; then
    print_status "Cloning SuperSVG repository..."
    cd $HOME
    git clone https://github.com/sjtuplayer/SuperSVG.git
    cd SuperSVG
else
    print_status "SuperSVG repository already exists"
    cd $REPO_DIR
fi

# 8. Build Docker image
print_status "Building SuperSVG Docker image (10-15 minutes)..."
docker build -f Dockerfile.mamba -t supersvg:latest .

# 9. Setup directories
print_status "Creating directories..."
mkdir -p $HOME/supersvg_data
mkdir -p $HOME/supersvg_output
mkdir -p $HOME/supersvg_checkpoints
mkdir -p $HOME/supersvg_logs

# 10. Configure AWS S3 integration (optional)
print_status "Creating S3 sync scripts..."
cat > $HOME/sync_to_s3.sh << 'EOF'
#!/bin/bash
# Sync outputs and checkpoints to S3
# Set your S3 bucket: export S3_BUCKET=s3://your-bucket/supersvg

if [ -z "$S3_BUCKET" ]; then
    echo "Error: Please set S3_BUCKET environment variable"
    echo "Example: export S3_BUCKET=s3://your-bucket/supersvg"
    exit 1
fi

echo "Syncing to $S3_BUCKET..."
aws s3 sync ~/supersvg_output $S3_BUCKET/output --exclude "*.tmp"
aws s3 sync ~/supersvg_checkpoints $S3_BUCKET/checkpoints
echo "Sync complete!"
EOF

chmod +x $HOME/sync_to_s3.sh

# 11. Create training launcher
print_status "Creating training launcher..."
cat > $HOME/train_supersvg.sh << 'EOF'
#!/bin/bash
# SuperSVG Training Launcher for AWS EC2

# Configuration
DATA_PATH="${DATA_PATH:-$HOME/supersvg_data}"
OUTPUT_PATH="${OUTPUT_PATH:-$HOME/supersvg_output}"
CHECKPOINT_PATH="${CHECKPOINT_PATH:-$HOME/supersvg_checkpoints}"
LOG_PATH="${LOG_PATH:-$HOME/supersvg_logs}"
BATCH_SIZE="${BATCH_SIZE:-48}"  # g5.2xlarge has 24GB, can handle batch_size=48
EPOCHS="${EPOCHS:-100}"

echo "========================================="
echo "SuperSVG Training on AWS EC2"
echo "========================================="
echo "Instance: $(ec2-metadata --instance-type | cut -d ' ' -f 2)"
echo "Data: $DATA_PATH"
echo "Output: $OUTPUT_PATH"
echo "Batch Size: $BATCH_SIZE"
echo "Epochs: $EPOCHS"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
echo "========================================="

docker run --rm -it --gpus all \
  --name supersvg-training \
  -v $DATA_PATH:/data \
  -v $OUTPUT_PATH:/workspace/output_coarse \
  -v $CHECKPOINT_PATH:/workspace/checkpoints \
  -v $LOG_PATH:/workspace/logs \
  --shm-size=16g \
  supersvg:latest \
  micromamba run -n live python main_coarse.py \
    --data_path=/data \
    --batch_size=$BATCH_SIZE \
    --epochs=$EPOCHS
EOF

chmod +x $HOME/train_supersvg.sh

# 12. Create comprehensive monitoring script
print_status "Creating monitoring scripts..."
cat > $HOME/monitor_training.sh << 'EOF'
#!/bin/bash
# SuperSVG Training Monitor with AWS Cost Estimation

echo "============================================"
echo "SuperSVG Training Monitor - AWS EC2"
echo "============================================"
echo ""

# Instance info
INSTANCE_TYPE=$(ec2-metadata --instance-type | cut -d " " -f 2)
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)

echo "Instance: $INSTANCE_TYPE ($INSTANCE_ID)"
echo "Zone: $AVAILABILITY_ZONE"
echo ""

# GPU monitoring
echo "GPU Status:"
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw --format=csv
echo ""

# Docker status
echo "Training Container:"
docker ps -a --filter name=supersvg-training
echo ""

# Recent logs
if docker ps -a --filter name=supersvg-training | grep -q supersvg-training; then
    echo "Recent Training Logs (last 20 lines):"
    docker logs supersvg-training 2>&1 | tail -n 20
    echo ""
fi

# Disk usage
echo "Disk Usage:"
df -h $HOME/supersvg_output $HOME/supersvg_checkpoints $HOME/supersvg_data
echo ""

# Cost estimation
echo "Cost Estimation:"
UPTIME_INFO=$(docker inspect --format='{{.State.StartedAt}}' supersvg-training 2>/dev/null)

if [ ! -z "$UPTIME_INFO" ]; then
    START=$(date -d "$UPTIME_INFO" +%s)
    NOW=$(date +%s)
    HOURS=$(echo "scale=2; ($NOW - $START) / 3600" | bc)
    
    # Pricing for g5.2xlarge
    ONDEMAND_COST=$(echo "scale=2; $HOURS * 1.212" | bc)
    SPOT_COST=$(echo "scale=2; $HOURS * 0.40" | bc)
    
    echo "Running time: $HOURS hours"
    echo "Estimated cost (on-demand): \$$ONDEMAND_COST USD"
    echo "Estimated cost (spot): \$$SPOT_COST USD"
    
    # Check if this is a spot instance
    SPOT_INSTANCE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].InstanceLifecycle' --output text 2>/dev/null)
    if [ "$SPOT_INSTANCE" == "spot" ]; then
        echo "✓ Running on SPOT instance (saving ~70%)"
    else
        echo "! Running on ON-DEMAND instance (consider using spot)"
    fi
else
    echo "Container not currently running"
fi
echo ""

# Network usage
echo "Network Traffic:"
ifconfig | grep -A 7 "eth0" | grep "RX packets\|TX packets"
EOF

chmod +x $HOME/monitor_training.sh

# 13. Create spot instance termination handler
print_status "Creating spot instance termination handler..."
cat > $HOME/spot_termination_handler.sh << 'EOF'
#!/bin/bash
# Monitor for EC2 spot instance termination notice and save checkpoints

while true; do
    # Check for termination notice (2 minute warning)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://169.254.169.254/latest/meta-data/spot/instance-action)
    
    if [ "$HTTP_CODE" == "200" ]; then
        echo "[WARNING] Spot instance termination notice received!"
        echo "[ACTION] Saving checkpoints and syncing to S3..."
        
        # Stop training gracefully
        docker stop -t 60 supersvg-training
        
        # Sync to S3 if configured
        if [ ! -z "$S3_BUCKET" ]; then
            ~/sync_to_s3.sh
            echo "[SUCCESS] Data synced to S3"
        else
            echo "[WARNING] S3_BUCKET not set, cannot sync to S3"
        fi
        
        exit 0
    fi
    
    # Check every 5 seconds
    sleep 5
done
EOF

chmod +x $HOME/spot_termination_handler.sh

# 14. Create auto-backup with S3
cat > $HOME/setup_auto_backup.sh << 'EOF'
#!/bin/bash
# Setup automatic backup to S3 every hour

if [ -z "$S3_BUCKET" ]; then
    echo "Error: Please set S3_BUCKET environment variable"
    echo "Example: export S3_BUCKET=s3://your-bucket/supersvg"
    exit 1
fi

# Add cron job for hourly backup
(crontab -l 2>/dev/null; echo "0 * * * * $HOME/sync_to_s3.sh >> $HOME/s3_sync.log 2>&1") | crontab -

echo "Auto-backup configured. Checkpoints will sync to $S3_BUCKET every hour."
echo "Check logs: tail -f $HOME/s3_sync.log"
EOF

chmod +x $HOME/setup_auto_backup.sh

# 15. Create quick start guide
print_status "Creating AWS-specific quick start guide..."
cat > $HOME/AWS_QUICKSTART.md << 'EOF'
# SuperSVG AWS EC2 Quick Start Guide

## 🚀 Quick Start

### 1. Upload Dataset to EC2

**Option A: Direct Upload via SCP**
```bash
# From your local machine
scp -i your-key.pem -r /path/to/dataset ubuntu@<ec2-ip>:~/supersvg_data/
```

**Option B: Download from S3**
```bash
# On EC2 instance
export S3_BUCKET=s3://your-bucket/datasets
aws s3 sync $S3_BUCKET/your-dataset ~/supersvg_data/
```

**Option C: Download from URL**
```bash
cd ~/supersvg_data
wget <dataset-url>
unzip dataset.zip
```

### 2. Start Training

**Basic Training:**
```bash
~/train_supersvg.sh
```

**Custom Parameters:**
```bash
BATCH_SIZE=64 EPOCHS=200 ~/train_supersvg.sh
```

**Background Training with tmux:**
```bash
tmux new -s training
~/train_supersvg.sh
# Detach: Ctrl+B, then D
# Reattach: tmux attach -t training
```

### 3. Monitor Training

```bash
# View comprehensive monitor
~/monitor_training.sh

# Watch live
watch -n 5 ~/monitor_training.sh

# GPU monitoring
watch -n 1 nvidia-smi

# Live logs
docker logs -f supersvg-training
```

### 4. Backup to S3

**Setup S3 Bucket:**
```bash
export S3_BUCKET=s3://your-bucket/supersvg
echo 'export S3_BUCKET=s3://your-bucket/supersvg' >> ~/.bashrc
```

**Manual Sync:**
```bash
~/sync_to_s3.sh
```

**Auto-backup (every hour):**
```bash
~/setup_auto_backup.sh
```

### 5. Download Results

**From S3 (recommended):**
```bash
# After training, sync to S3
~/sync_to_s3.sh

# Download to local machine
aws s3 sync s3://your-bucket/supersvg/output ./results/
```

**Direct Download:**
```bash
# From your local machine
scp -i your-key.pem -r ubuntu@<ec2-ip>:~/supersvg_output ./results/
```

## 💰 AWS Cost Optimization

### Instance Pricing (g5.2xlarge)
| Type      | Price/hour | Best For                    |
|-----------|------------|-----------------------------|
| On-Demand | $1.212     | Production, reliability     |
| Spot      | $0.36-0.50 | Training, flexible workloads|

**Savings with Spot: 60-70%**

### Launch Spot Instance

**Via AWS Console:**
1. Go to EC2 → Spot Requests
2. Select g5.2xlarge
3. Use Deep Learning AMI (Ubuntu)
4. Set max price: $0.60/hour

**Via AWS CLI:**
```bash
aws ec2 request-spot-instances \
  --spot-price "0.60" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification file://spot-config.json
```

### Spot Instance Protection

**Enable termination handler:**
```bash
# Run in background to monitor for termination
tmux new -s spot-handler
~/spot_termination_handler.sh
# Detach: Ctrl+B, D
```

This will automatically:
- Detect 2-minute termination warning
- Save checkpoints
- Sync to S3
- Gracefully shutdown

### Cost Estimates

**Icon Dataset (30K samples, 200 epochs):**
- On-Demand: ~$2.42-3.64 USD (2-3 hours)
- Spot: ~$0.80-1.20 USD (2-3 hours)

**Quick Draw (1M samples, 100 epochs):**
- On-Demand: ~$12-18 USD (10-15 hours)
- Spot: ~$4-6 USD (10-15 hours)

**Full Dataset (50M samples, 100 epochs):**
- On-Demand: ~$60-85 USD (50-70 hours)
- Spot: ~$20-30 USD (50-70 hours)

## 🔧 Performance Tips

### Optimal Batch Sizes for g5.2xlarge (A10G 24GB)
- **Recommended**: 48-64
- **Maximum**: 96 (with gradient checkpointing)
- **Safe**: 32 (for large models)

### Multi-GPU Training (g5.4xlarge, g5.8xlarge)
For g5.4xlarge (2x A10G):
```bash
docker run --rm -it --gpus all \
  -v ~/supersvg_data:/data \
  -v ~/supersvg_output:/workspace/output_coarse \
  supersvg:latest \
  micromamba run -n live python -m torch.distributed.launch \
    --nproc_per_node=2 main_coarse.py --data_path=/data
```

### Mixed Precision Training
Edit main_coarse.py to enable AMP (Automatic Mixed Precision):
```python
from torch.cuda.amp import autocast, GradScaler
scaler = GradScaler()
# In training loop:
with autocast():
    output = model(input)
```

## 📊 Monitoring & Debugging

### CloudWatch Integration
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Configure to send GPU metrics
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s -c ssm:<parameter-name>
```

### TensorBoard Monitoring
```bash
# On EC2
docker run --rm -it -p 6006:6006 \
  -v ~/supersvg_logs:/logs \
  tensorflow/tensorflow \
  tensorboard --logdir=/logs --host=0.0.0.0

# Access from local machine (SSH tunnel)
ssh -i your-key.pem -L 6006:localhost:6006 ubuntu@<ec2-ip>
# Open browser: http://localhost:6006
```

### Alerts on Completion
```bash
# Install AWS SNS for notifications
aws sns publish \
  --topic-arn arn:aws:sns:region:account:topic \
  --message "SuperSVG training completed on instance $INSTANCE_ID"
```

## 🛠️ Troubleshooting

### Out of Memory
```bash
# Reduce batch size
BATCH_SIZE=32 ~/train_supersvg.sh

# Check memory usage
nvidia-smi dmon -s mu
```

### Slow Data Loading
```bash
# Use instance storage (NVMe SSD) for datasets
sudo mkfs.ext4 /dev/nvme1n1
sudo mount /dev/nvme1n1 /mnt/data
cp -r ~/supersvg_data/* /mnt/data/
DATA_PATH=/mnt/data ~/train_supersvg.sh
```

### Docker Build Failures
```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker build -f Dockerfile.mamba -t supersvg:latest .

# Clear cache if needed
docker builder prune -a
```

### Network Bottlenecks
```bash
# Enable enhanced networking (if not already)
aws ec2 modify-instance-attribute \
  --instance-id $INSTANCE_ID \
  --ena-support
```

## 📁 File Structure

```
$HOME/
├── SuperSVG/                 # Git repository
├── supersvg_data/           # Training datasets
├── supersvg_output/         # Training outputs
├── supersvg_checkpoints/    # Model checkpoints
├── supersvg_logs/          # TensorBoard logs
├── train_supersvg.sh       # Training launcher
├── monitor_training.sh     # Monitor script
├── sync_to_s3.sh          # S3 sync script
├── spot_termination_handler.sh
└── AWS_QUICKSTART.md       # This file
```

## 🔒 Security Best Practices

1. **Use IAM Roles** (not access keys)
2. **Restrict Security Groups** (only open necessary ports)
3. **Enable VPC Flow Logs**
4. **Encrypt EBS volumes**
5. **Regular AMI snapshots**

## 🎯 Production Checklist

- [ ] Configure S3 bucket for backups
- [ ] Set up auto-backup cron job
- [ ] Enable spot termination handler
- [ ] Configure CloudWatch alarms
- [ ] Test training with small dataset
- [ ] Document hyperparameters
- [ ] Set up SNS notifications
- [ ] Create AMI of configured instance

## 📚 Additional Resources

- [AWS EC2 G5 Instances](https://aws.amazon.com/ec2/instance-types/g5/)
- [AWS Spot Instances](https://aws.amazon.com/ec2/spot/)
- [PyTorch on AWS](https://docs.aws.amazon.com/dlami/latest/devguide/tutorial-pytorch.html)
- [SuperSVG Paper](https://openaccess.thecvf.com/content/CVPR2024/papers/Hu_SuperSVG_Superpixel-based_Scalable_Vector_Graphics_Synthesis_CVPR_2024_paper.pdf)

EOF

print_status "================================================="
print_status "AWS EC2 Setup Complete! 🎉"
print_status "================================================="
echo ""
print_info "Instance Information:"
echo "  Type: $INSTANCE_TYPE"
echo "  ID: $INSTANCE_ID"
echo "  Zone: $AVAILABILITY_ZONE"
echo ""
print_status "Next Steps:"
echo "  1. Configure S3 (optional): export S3_BUCKET=s3://your-bucket/supersvg"
echo "  2. Upload dataset to: $HOME/supersvg_data"
echo "  3. Read guide: cat $HOME/AWS_QUICKSTART.md"
echo "  4. Start training: $HOME/train_supersvg.sh"
echo "  5. Monitor: $HOME/monitor_training.sh"
echo ""
print_warning "For spot instances, enable termination handler:"
echo "  tmux new -s spot-handler"
echo "  $HOME/spot_termination_handler.sh"
echo ""
print_status "GPU Information:"
nvidia-smi --query-gpu=name,memory.total --format=csv
echo ""
print_info "Estimated costs (g5.2xlarge):"
echo "  On-demand: ~$1.21/hour"
echo "  Spot: ~$0.36-0.50/hour"
echo ""
print_status "Happy training! 🚀"
