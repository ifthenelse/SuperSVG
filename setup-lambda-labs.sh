#!/bin/bash
################################################################################
# SuperSVG Training Setup Script for Lambda Labs
# 
# This script configures a Lambda Labs instance for SuperSVG training
# Recommended GPU: A6000 (48GB VRAM) or RTX A4000/A5000
# Cost: ~$0.50-$0.80/hour
################################################################################

set -e  # Exit on error

echo "========================================="
echo "SuperSVG Lambda Labs Setup"
echo "========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. System Update
print_status "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# 2. Install essential tools
print_status "Installing essential tools..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    tmux \
    build-essential \
    cmake

# 3. Verify NVIDIA GPU and drivers
print_status "Verifying NVIDIA GPU setup..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
    print_status "NVIDIA drivers detected"
else
    print_error "NVIDIA drivers not found! Installing..."
    # Lambda Labs instances typically come with drivers pre-installed
    # If not, install them:
    sudo apt-get install -y nvidia-driver-535
fi

# 4. Install Docker (if not already installed)
print_status "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
else
    print_status "Docker already installed"
fi

# 5. Install NVIDIA Container Toolkit
print_status "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit nvidia-docker2
sudo systemctl restart docker

# Verify GPU access in Docker
print_status "Verifying Docker GPU access..."
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# 6. Clone SuperSVG repository (if not already present)
REPO_DIR="$HOME/SuperSVG"
if [ ! -d "$REPO_DIR" ]; then
    print_status "Cloning SuperSVG repository..."
    cd $HOME
    git clone https://github.com/sjtuplayer/SuperSVG.git
    cd SuperSVG
else
    print_status "SuperSVG repository already exists at $REPO_DIR"
    cd $REPO_DIR
fi

# 7. Build Docker image
print_status "Building SuperSVG Docker image (this may take 10-15 minutes)..."
docker build -f Dockerfile.mamba -t supersvg:latest .

# 8. Create data and output directories
print_status "Creating data and output directories..."
mkdir -p $HOME/supersvg_data
mkdir -p $HOME/supersvg_output
mkdir -p $HOME/supersvg_checkpoints
mkdir -p $HOME/supersvg_logs

# 9. Download sample dataset (Quick Draw - optional)
print_warning "Sample dataset download skipped. Please upload your dataset to: $HOME/supersvg_data"
print_warning "For Quick Draw dataset, visit: https://quickdraw.withgoogle.com/data"
print_warning "For icon datasets, see the README for download links"

# 10. Create convenient training launcher script
print_status "Creating training launcher script..."
cat > $HOME/train_supersvg.sh << 'EOF'
#!/bin/bash
# SuperSVG Training Launcher for Lambda Labs

# Configuration
DATA_PATH="${DATA_PATH:-$HOME/supersvg_data}"
OUTPUT_PATH="${OUTPUT_PATH:-$HOME/supersvg_output}"
CHECKPOINT_PATH="${CHECKPOINT_PATH:-$HOME/supersvg_checkpoints}"
LOG_PATH="${LOG_PATH:-$HOME/supersvg_logs}"
BATCH_SIZE="${BATCH_SIZE:-32}"
EPOCHS="${EPOCHS:-100}"

echo "Starting SuperSVG Training..."
echo "Data: $DATA_PATH"
echo "Output: $OUTPUT_PATH"
echo "Batch Size: $BATCH_SIZE"
echo "Epochs: $EPOCHS"
echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader)"

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

# 11. Create cost monitoring script
print_status "Creating cost monitoring script..."
cat > $HOME/monitor_training.sh << 'EOF'
#!/bin/bash
# SuperSVG Training Monitor

echo "=== SuperSVG Training Monitor ==="
echo ""

# GPU monitoring
echo "GPU Status:"
nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv

echo ""
echo "Docker Containers:"
docker ps -a

echo ""
echo "Recent logs (last 20 lines):"
docker logs supersvg-training 2>&1 | tail -n 20

echo ""
echo "Disk usage:"
df -h $HOME/supersvg_output $HOME/supersvg_checkpoints

echo ""
echo "Estimated cost (Lambda Labs A6000 @ $0.80/hour):"
UPTIME=$(docker inspect --format='{{.State.StartedAt}}' supersvg-training 2>/dev/null)
if [ ! -z "$UPTIME" ]; then
    START=$(date -d "$UPTIME" +%s)
    NOW=$(date +%s)
    HOURS=$(echo "scale=2; ($NOW - $START) / 3600" | bc)
    COST=$(echo "scale=2; $HOURS * 0.80" | bc)
    echo "Running time: $HOURS hours"
    echo "Estimated cost: \$$COST USD"
else
    echo "Container not running"
fi
EOF

chmod +x $HOME/monitor_training.sh

# 12. Create quick start guide
print_status "Creating quick start guide..."
cat > $HOME/QUICKSTART.md << 'EOF'
# SuperSVG Lambda Labs Quick Start Guide

## 🚀 Quick Start

### 1. Upload Your Dataset
```bash
# Option A: Upload via SCP from your local machine
scp -r /path/to/your/dataset ubuntu@<lambda-instance-ip>:~/supersvg_data/

# Option B: Download directly on Lambda instance
cd ~/supersvg_data
wget <dataset-url>
unzip dataset.zip
```

### 2. Start Training
```bash
# Basic training with default parameters
~/train_supersvg.sh

# Custom parameters
DATA_PATH=~/supersvg_data BATCH_SIZE=64 EPOCHS=200 ~/train_supersvg.sh
```

### 3. Monitor Training
```bash
# View training monitor
~/monitor_training.sh

# Watch live logs
docker logs -f supersvg-training

# GPU monitoring
watch -n 1 nvidia-smi
```

### 4. Interactive Development Mode
```bash
docker run --rm -it --gpus all \
  -v ~/supersvg_data:/data \
  -v ~/supersvg_output:/workspace/output_coarse \
  --entrypoint bash \
  supersvg:latest

# Inside container:
micromamba run -n live python main_coarse.py --data_path=/data --batch_size=32
```

## 📊 Performance Tips

### Optimize Batch Size
- **A6000 (48GB)**: batch_size=64-128
- **RTX A5000 (24GB)**: batch_size=32-64
- **RTX A4000 (16GB)**: batch_size=16-32

### Use tmux for Long Training
```bash
# Start tmux session
tmux new -s training

# Run training
~/train_supersvg.sh

# Detach: Ctrl+B, then D
# Reattach: tmux attach -t training
```

### Download Results
```bash
# From your local machine
scp -r ubuntu@<lambda-instance-ip>:~/supersvg_output ./results/
```

## 💰 Cost Management

**Lambda Labs Pricing (as of 2024):**
- A6000 (48GB): ~$0.80/hour
- RTX A5000 (24GB): ~$0.60/hour
- RTX A4000 (16GB): ~$0.50/hour

**Typical Training Costs:**
- Icon dataset (30K, 200 epochs): ~$1-2
- Quick Draw (1M, 100 epochs): ~$8-15
- Full dataset (50M, 100 epochs): ~$30-50

**Tips:**
- Terminate instance when not in use
- Download checkpoints regularly
- Use spot instances when possible
- Monitor costs with: ~/monitor_training.sh

## 🛠️ Troubleshooting

### Out of Memory
```bash
# Reduce batch size
BATCH_SIZE=16 ~/train_supersvg.sh

# Check GPU memory
nvidia-smi
```

### Docker Issues
```bash
# Restart Docker
sudo systemctl restart docker

# Clean up
docker system prune -a
```

### Slow Training
```bash
# Check GPU utilization
watch -n 1 nvidia-smi

# Increase workers (in main_coarse.py: num_workers=8)
```

## 📁 Important Paths

- **Data**: `~/supersvg_data/`
- **Output**: `~/supersvg_output/`
- **Checkpoints**: `~/supersvg_checkpoints/`
- **Logs**: `~/supersvg_logs/`
- **Repository**: `~/SuperSVG/`

EOF

print_status "================================================="
print_status "Setup Complete! 🎉"
print_status "================================================="
echo ""
print_status "Next steps:"
echo "  1. Upload your dataset to: $HOME/supersvg_data"
echo "  2. Read the quick start guide: cat $HOME/QUICKSTART.md"
echo "  3. Start training: $HOME/train_supersvg.sh"
echo "  4. Monitor progress: $HOME/monitor_training.sh"
echo ""
print_warning "Note: If this is the first time installing Docker, you may need to:"
print_warning "  sudo newgrp docker"
print_warning "  or log out and log back in"
echo ""
print_status "GPU Information:"
nvidia-smi --query-gpu=name,memory.total --format=csv
echo ""
print_status "Happy training! 🚀"
