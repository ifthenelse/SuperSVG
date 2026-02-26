# SuperSVG Cloud Training Setup Scripts

This directory contains automated setup scripts for training SuperSVG on cloud GPU instances.

## 📋 Quick Comparison

| Feature               | RunPod (Recommended) ⭐   | Lambda Labs                | AWS EC2 g5.2xlarge     |
| --------------------- | ------------------------- | -------------------------- | ---------------------- |
| **GPU**               | RTX 4090 (24GB)           | A100 (40GB) / A6000 (48GB) | A10G (24GB)            |
| **Cost**              | $0.44-0.69/hour           | $1.29-1.99/hour            | $0.36-0.50/hour (spot) |
| **Setup Time**        | 10-15 min                 | 10-15 min                  | 15-20 min              |
| **Best For**          | Best price/performance    | High VRAM when available   | AWS ecosystem          |
| **Availability**      | Good (multiple providers) | ⚠️ Often full              | High (spot: variable)  |
| **Savings Potential** | Already cheap             | Base price                 | 60-70% with spot       |

> **⚠️ Important**: Lambda Labs instances are frequently unavailable. We recommend RunPod or AWS EC2 as more reliable alternatives.

## ☁️ Cloud Provider Alternatives

Since Lambda Labs is often at capacity, here are reliable alternatives:

### Tier 1: Best Value (Recommended)

**1. RunPod** ⭐ **BEST CHOICE**

- **RTX 4090** (24GB): $0.44-0.69/hour
- **RTX A5000** (24GB): $0.34-0.54/hour
- **Availability**: Good (distributed providers)
- **Setup**: Same as Lambda Labs (use our setup script)
- **URL**: https://runpod.io

**2. Vast.ai** (Spot Market)

- **RTX 4090** (24GB): $0.30-0.60/hour
- **A6000** (48GB): $0.60-0.90/hour
- **Availability**: Excellent (peer-to-peer)
- **Setup**: Slightly different, Docker-native
- **URL**: https://vast.ai

### Tier 2: When Available

**3. Lambda Labs**

- **1x A100 (40GB)**: $1.29/hour (when available)
- **1x A6000 (48GB)**: $0.80/hour (rarely available)
- **2x H100 (80GB)**: $6.38/hour ($3.19/GPU) - for large-scale
- **Availability**: ⚠️ Frequently sold out
- **Best for**: When you can get it, good price for A100

**4. Paperspace Gradient**

- **RTX A4000** (16GB): $0.76/hour
- **A100** (80GB): $3.09/hour
- **Availability**: Good
- **Setup**: Web UI or CLI
- **URL**: https://paperspace.com

### Tier 3: Premium Options

**5. AWS EC2**

- **g5.2xlarge** (A10G 24GB): $0.36-0.50/hour (spot)
- **p3.2xlarge** (V100 16GB): $0.90-1.20/hour (spot)
- **Availability**: Best
- **Setup**: Use our setup-aws-ec2.sh script

**6. Google Cloud Platform**

- **n1-standard-8 + V100**: $1.25-1.50/hour (preemptible)
- **n1-standard-8 + A100**: $1.80-2.50/hour (preemptible)
- **Availability**: Excellent
- **Setup**: Similar to AWS

## 🚀 Quick Start

### RunPod Setup (Recommended)

```bash
# 1. Create account at https://runpod.io
# 2. Deploy RTX 4090 or A5000 GPU Pod with Ubuntu 22.04
# 3. SSH into your pod
ssh root@<runpod-ip> -p <port> -i ~/.ssh/id_ed25519

# 4. Download and run setup script (same as Lambda Labs)
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh
chmod +x setup-lambda-labs.sh
./setup-lambda-labs.sh

# 5. Follow the quick start guide
cat ~/QUICKSTART.md
```

### Vast.ai Setup (Cheapest Option)

```bash
# 1. Create account at https://vast.ai
# 2. Search for RTX 4090 or A6000 instances
# 3. Select instance with good reliability score (>99%)
# 4. SSH into instance
ssh root@<vast-ip> -p <port>

# 5. Run setup script
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh
chmod +x setup-lambda-labs.sh
./setup-lambda-labs.sh
```

### Lambda Labs Setup (When Available)

```bash
# 1. SSH into your Lambda Labs instance
ssh ubuntu@<lambda-instance-ip>

# 2. Download and run setup script
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh
chmod +x setup-lambda-labs.sh
./setup-lambda-labs.sh

# 3. Follow the quick start guide
cat ~/QUICKSTART.md
```

### AWS EC2 Setup

```bash
# 1. Launch g5.2xlarge instance (Ubuntu 22.04, Deep Learning AMI recommended)

# 2. SSH into instance
ssh -i your-key.pem ubuntu@<ec2-public-ip>

# 3. Download and run setup script
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh
chmod +x setup-aws-ec2.sh
./setup-aws-ec2.sh

# 4. Follow the AWS quick start guide
cat ~/AWS_QUICKSTART.md
```

## 💰 Cost Calculator

### Example Training Costs

**Icon Dataset (30K samples, 200 epochs, ~2-3 hours):**

- **RunPod RTX 4090**: **$0.88-1.38** ⭐ **BEST VALUE**
- **Vast.ai RTX 4090**: **$0.60-1.20** 💰 **CHEAPEST**
- AWS g5.2xlarge (spot): **$0.80-1.20**
- Lambda Labs A100 (40GB): **$2.58-3.87** (when available)
- Lambda Labs A6000 (48GB): **$1.60-2.40** (⚠️ rarely available)
- AWS g5.2xlarge (on-demand): **$2.42-3.64**

**Quick Draw Dataset (1M samples, 100 epochs, ~10-15 hours):**

- **RunPod RTX 4090**: **$4.40-6.90** ⭐ **BEST VALUE**
- **Vast.ai RTX 4090**: **$3.00-6.00** 💰 **CHEAPEST**
- AWS g5.2xlarge (spot): **$4-6**
- Lambda Labs A100 (40GB): **$12.90-19.35** (when available)
- Lambda Labs A6000 (48GB): **$8-12** (⚠️ rarely available)
- AWS g5.2xlarge (on-demand): **$12-18**

**Full Dataset (50M samples, 100 epochs, ~50-70 hours):**

- **RunPod RTX 4090**: **$22-35** ⭐ **BEST VALUE**
- **Vast.ai RTX 4090**: **$15-30** 💰 **CHEAPEST**
- AWS g5.2xlarge (spot): **$20-30**
- Lambda Labs A100 (40GB): **$64.50-90.30** (when available)
- Lambda Labs A6000 (48GB): **$40-56** (⚠️ rarely available)
- AWS g5.2xlarge (on-demand): **$60-85**

## 🎯 Recommendations

> **⚠️ Important**: Lambda Labs instances (A6000, GH200, B200) are frequently sold out. We recommend RunPod or AWS EC2 as primary options.

### 🥇 First Choice: RunPod RTX 4090

- ✅ **Best price/performance ratio** ($0.44-0.69/hour)
- ✅ Good availability (multiple providers)
- ✅ 24GB VRAM (sufficient for batch_size=48-64)
- ✅ Simple setup (use our Lambda Labs script)
- ✅ Pay-as-you-go, no commitments
- ✅ Fast NVMe storage included
- ✅ Easy to scale up/down

**Recommended for**: Most users, development, production training

### 🥈 Second Choice: Vast.ai (Marketplace)

- ✅ **Cheapest option** ($0.30-0.60/hour for RTX 4090)
- ✅ Excellent availability (peer-to-peer marketplace)
- ✅ Flexible GPU selection (RTX 4090, A6000, etc.)
- ✅ Reliability scoring system (choose >95%)
- ⚠️ Variable quality (carefully check provider ratings)
- ⚠️ Less polished UI than other providers

**Recommended for**: Budget-conscious users, experimentation

### 🥉 Third Choice: AWS EC2 (Spot Instances)

- ✅ **Best for AWS ecosystem** integration
- ✅ 60-70% savings with spot instances
- ✅ S3 integration for datasets and backups
- ✅ Best infrastructure reliability
- ✅ CloudWatch monitoring built-in
- ✅ Auto-scaling capabilities
- ⚠️ More complex setup
- ⚠️ Spot interruptions possible (use our handler)

**Recommended for**: AWS users, production workloads, enterprise

### 💎 When Available: Lambda Labs

**Available Sometimes:**

- ✅ **1x A100 (40GB)**: $1.29/hour - Good value when available
- ✅ **2x H100 (80GB)**: $6.38/hour ($3.19/GPU) - For multi-GPU training

**Rarely Available:**

- ❌ **1x A6000 (48GB)**: $0.80/hour - Almost always sold out
- ❌ **GH200, B200 series**: Premium instances, frequently unavailable

**Tips for Lambda Labs:**

- 🔔 Check early morning UTC for better availability
- 🔔 Set up availability alerts if they offer them
- 🔔 Have RunPod/Vast.ai as backup ready

### ❌ Not Recommended:

- AWS on-demand instances (too expensive vs alternatives)
- Colab Pro/Pro+ (session limits, unreliable for long training)
- Local RTX 3060 (insufficient VRAM for larger batch sizes)

## 📦 What These Scripts Do

Both scripts fully automate:

1. ✅ System updates and essential tools installation
2. ✅ NVIDIA driver installation
3. ✅ Docker and NVIDIA Container Toolkit setup
4. ✅ SuperSVG repository cloning
5. ✅ Docker image building
6. ✅ Directory structure creation
7. ✅ Training launcher scripts
8. ✅ Monitoring and cost tracking tools
9. ✅ Quick start guides

### AWS-specific additions:

- S3 sync scripts for backup
- Spot instance termination handler
- Auto-backup setup
- CloudWatch integration guide

## 🛠️ Script Features

### Training Launcher (`train_supersvg.sh`)

Simple one-command training start with customizable parameters:

```bash
# Default settings
./train_supersvg.sh

# Custom batch size and epochs
BATCH_SIZE=64 EPOCHS=200 ./train_supersvg.sh

# All custom parameters
DATA_PATH=~/my_data BATCH_SIZE=32 EPOCHS=50 ./train_supersvg.sh
```

### Training Monitor (`monitor_training.sh`)

Real-time monitoring with:

- GPU utilization and memory
- Container status
- Recent training logs
- Disk usage
- **Cost estimation** (running time × hourly rate)
- Spot instance detection (AWS)

### S3 Sync (AWS only - `sync_to_s3.sh`)

```bash
export S3_BUCKET=s3://your-bucket/supersvg
./sync_to_s3.sh  # Manual sync
./setup_auto_backup.sh  # Hourly auto-sync
```

### Spot Termination Handler (AWS only)

Automatically handles 2-minute spot termination warning:

```bash
tmux new -s spot-handler
./spot_termination_handler.sh
```

## 📊 Performance Comparison

**Icon Dataset Training (30K samples, 200 epochs):**

| Platform                   | GPU      | VRAM | Batch Size | Time  | Cost           | Availability |
| -------------------------- | -------- | ---- | ---------- | ----- | -------------- | ------------ |
| **RunPod RTX 4090** ⭐     | RTX 4090 | 24GB | 64         | ~2h   | **$0.88-1.38** | ✅ Good      |
| **Vast.ai RTX 4090** 💰    | RTX 4090 | 24GB | 64         | ~2h   | **$0.60-1.20** | ✅ Excellent |
| AWS g5.2xlarge (spot)      | A10G     | 24GB | 48         | ~2.5h | $1.00          | ✅ Good      |
| Lambda A100 (40GB)         | A100     | 40GB | 96         | ~1.5h | $1.94          | ⚠️ Sometimes |
| Lambda A6000               | A6000    | 48GB | 64         | ~2h   | $1.60          | ❌ Rare      |
| AWS g5.2xlarge (on-demand) | A10G     | 24GB | 48         | ~2.5h | $3.03          |

## 🔍 Troubleshooting

### Script Won't Run

```bash
chmod +x setup-*.sh
./setup-lambda-labs.sh  # or setup-aws-ec2.sh
```

### Docker Permission Issues

```bash
# After script completes
sudo newgrp docker
# Or log out and back in
```

### GPU Not Detected

```bash
# Check drivers
nvidia-smi

# Reinstall drivers (may need reboot)
sudo apt-get install --reinstall nvidia-driver-535
sudo reboot
```

### Out of Memory During Training

```bash
# Reduce batch size
BATCH_SIZE=16 ./train_supersvg.sh

# Check GPU memory
nvidia-smi
```

### Build Fails

```bash
# Clear Docker cache
docker system prune -a

# Rebuild with no cache
docker build --no-cache -f Dockerfile.mamba -t supersvg:latest .
```

## 📁 Directory Structure After Setup

```
$HOME/
├── SuperSVG/                    # Repository
├── supersvg_data/              # Put your datasets here
├── supersvg_output/            # Training outputs
├── supersvg_checkpoints/       # Model checkpoints
├── supersvg_logs/             # TensorBoard logs
├── train_supersvg.sh          # Training launcher
├── monitor_training.sh        # Monitoring tool
├── sync_to_s3.sh             # S3 sync (AWS only)
├── spot_termination_handler.sh # Spot handler (AWS only)
├── setup_auto_backup.sh       # Auto-backup (AWS only)
└── QUICKSTART.md / AWS_QUICKSTART.md  # Platform guide
```

## 🎓 Usage Examples

### Basic Training

```bash
# Upload your dataset
scp -r /local/dataset ubuntu@instance:~/supersvg_data/

# Start training
ssh ubuntu@instance
./train_supersvg.sh
```

### Long Training with tmux

```bash
ssh ubuntu@instance
tmux new -s training
./train_supersvg.sh
# Detach: Ctrl+B, D
# Logout and come back later
tmux attach -t training
```

### Monitor from Another Terminal

```bash
# Terminal 1: Training
./train_supersvg.sh

# Terminal 2: Monitoring
watch -n 5 ./monitor_training.sh
```

### AWS with S3 Backup

```bash
# Setup
export S3_BUCKET=s3://my-bucket/supersvg
./setup_auto_backup.sh

# Train (auto-backed up hourly)
./train_supersvg.sh

# Manual sync
./sync_to_s3.sh
```

## 🔐 Security Notes

### Lambda Labs

- Use SSH key authentication (not password)
- Terminate instances when not in use
- Don't expose Docker ports publicly

### AWS

- Use IAM roles (not access keys)
- Configure security groups properly
- Enable VPC flow logs
- Encrypt EBS volumes
- Use spot instances for cost savings

## 📚 Additional Resources

- [SuperSVG Paper (CVPR 2024)](https://openaccess.thecvf.com/content/CVPR2024/papers/Hu_SuperSVG_Superpixel-based_Scalable_Vector_Graphics_Synthesis_CVPR_2024_paper.pdf)
- [Lambda Labs Documentation](https://lambdalabs.com/service/gpu-cloud)
- [AWS EC2 G5 Instances](https://aws.amazon.com/ec2/instance-types/g5/)
- [AWS Spot Instances Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
- [DiffVG Documentation](https://github.com/BachiLi/diffvg)

## 🤝 Contributing

Found an issue or improvement? Please submit a PR or issue on the SuperSVG repository.

## 📝 License

These setup scripts are provided as-is for use with SuperSVG. See the main repository for license details.

---

**Last Updated**: February 2026
**Scripts Tested On**: Ubuntu 22.04, Ubuntu 20.04
**GPU Compatibility**: NVIDIA GPUs with CUDA support
