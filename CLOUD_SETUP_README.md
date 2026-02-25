# SuperSVG Cloud Training Setup Scripts

This directory contains automated setup scripts for training SuperSVG on cloud GPU instances.

## 📋 Quick Comparison

| Feature               | Lambda Labs                  | AWS EC2 g5.2xlarge        |
| --------------------- | ---------------------------- | ------------------------- |
| **GPU**               | A6000 (48GB)                 | A10G (24GB)               |
| **Cost (On-Demand)**  | $0.80/hour                   | $1.21/hour                |
| **Cost (Spot)**       | N/A                          | $0.36-0.50/hour           |
| **Setup Time**        | 10-15 min                    | 15-20 min                 |
| **Best For**          | Simple training, development | Production, AWS ecosystem |
| **Availability**      | Limited                      | High (spot: variable)     |
| **Savings Potential** | Base price                   | 60-70% with spot          |

## 🚀 Quick Start

### Lambda Labs Setup

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

- Lambda Labs A6000: **$1.60-2.40**
- AWS g5.2xlarge (spot): **$0.80-1.20**
- AWS g5.2xlarge (on-demand): **$2.42-3.64**

**Quick Draw Dataset (1M samples, 100 epochs, ~10-15 hours):**

- Lambda Labs A6000: **$8-12**
- AWS g5.2xlarge (spot): **$4-6**
- AWS g5.2xlarge (on-demand): **$12-18**

**Full Dataset (50M samples, 100 epochs, ~50-70 hours):**

- Lambda Labs A6000: **$40-56**
- AWS g5.2xlarge (spot): **$20-30**
- AWS g5.2xlarge (on-demand): **$60-85**

## 🎯 Recommendations

### Choose Lambda Labs if:

- ✅ You want the simplest setup
- ✅ You're doing research/experiments
- ✅ You need more VRAM (48GB vs 24GB)
- ✅ You prefer flat-rate pricing
- ✅ Availability works for your schedule

### Choose AWS EC2 if:

- ✅ You're already in AWS ecosystem
- ✅ You want 60-70% savings with spot instances
- ✅ You need S3 integration
- ✅ You need high availability
- ✅ You want auto-scaling capabilities
- ✅ You need CloudWatch monitoring

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

| Platform                   | GPU   | VRAM | Batch Size | Time  | Cost  |
| -------------------------- | ----- | ---- | ---------- | ----- | ----- |
| Lambda A6000               | A6000 | 48GB | 128        | ~1.5h | $1.20 |
| Lambda A6000               | A6000 | 48GB | 64         | ~2h   | $1.60 |
| AWS g5.2xlarge (spot)      | A10G  | 24GB | 64         | ~2h   | $0.80 |
| AWS g5.2xlarge (spot)      | A10G  | 24GB | 48         | ~2.5h | $1.00 |
| AWS g5.2xlarge (on-demand) | A10G  | 24GB | 48         | ~2.5h | $3.03 |

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
