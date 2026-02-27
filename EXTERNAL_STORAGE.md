# External Storage & Separate Physical Device Setup Guide

For macBook users with limited local storage, you can easily store datasets on external drives, USB drives, or network storage.

## 🎯 Quick Start

```bash
# 1. List available external drives
./docker-run.sh list-drives

# 2. Download to external drive
./docker-run.sh download /Volumes/MyDrive/datasets quickdraw

# 3. Train using external drive data
./docker-run.sh train /Volumes/MyDrive/datasets 100 32 0.001
```

---

## 📱 macOS External Storage Setup

### Step 1: Find Your External Drive

```bash
# List all connected drives
./docker-run.sh list-drives
# Or manually
ls -la /Volumes/
```

**Output example:**

```
📁 My Passport (2.5 TB) - /Volumes/My Passport
📁 ExternalDrive (1 TB) - /Volumes/ExternalDrive
📁 USB Drive (256 GB) - /Volumes/USB Drive
```

### Step 2: Check Available Space

```bash
# Check total and used space on drive
df -h /Volumes/MyDrive

# Output example:
# Filesystem     Size   Used  Avail Capacity
# /Volumes/...   5.5Ti  2.1Ti  3.4Ti    38%
```

For reference:

- **Test dataset**: 5 MB (fits on any USB)
- **Quick Draw dataset**: 1.5 GB (fits on any modern USB)
- **Tabler Icons**: 500 MB
- **All datasets**: ~2 GB

### Step 3: Create Datasets Directory

```bash
# Create a datasets folder on external drive
mkdir -p /Volumes/MyDrive/SuperSVG_datasets

# Or organize by project
mkdir -p /Volumes/MyDrive/ml_projects/supersvg/datasets
```

### Step 4: Download Datasets to External Drive

```bash
# Download test dataset (quick verification)
./docker-run.sh download /Volumes/MyDrive/SuperSVG_datasets test

# Download Quick Draw (recommended)
./docker-run.sh download /Volumes/MyDrive/SuperSVG_datasets quickdraw

# Download all datasets
./docker-run.sh download /Volumes/MyDrive/SuperSVG_datasets all

# Or using environment variable
DATA_PATH=/Volumes/MyDrive/SuperSVG_datasets ./docker-run.sh download quickdraw
```

**Progress indicator:**

```
════════════════════════════════════════
Downloading Datasets
════════════════════════════════════════
ℹ Data path: /Volumes/MyDrive/SuperSVG_datasets

Downloading 25 Quick Draw categories...
✓ airplane (487 images)
✓ apple (501 images)
...
✓ Downloaded 25 categories (0 failed)
```

### Step 5: Train Using External Drive Data

```bash
# Single command
./docker-run.sh train /Volumes/MyDrive/SuperSVG_datasets 100 32 0.001

# Or use environment variable (works with all commands)
DATA_PATH=/Volumes/MyDrive/SuperSVG_datasets ./docker-run.sh train input 100

# Mount to docker-compose directly
DATA_PATH=/Volumes/MyDrive/SuperSVG_datasets docker-compose up
```

---

## 🔄 Workflow Examples

### Example 1: External USB Drive

```bash
# You have: USB drive labeled "Samsung_SSD" plugged in
# Location: /Volumes/Samsung_SSD

# Step 1: List drives
./docker-run.sh list-drives
# → Output: 📁 Samsung_SSD (1 TB) - /Volumes/Samsung_SSD

# Step 2: Download datasets
./docker-run.sh download /Volumes/Samsung_SSD/datasets quickdraw
# (Takes 1-2 hours, shows progress)

# Step 3: Train
./docker-run.sh train /Volumes/Samsung_SSD/datasets 100
```

### Example 2: Network-Mounted Drive (macOS)

```bash
# Mount network drive (SMB share)
open smb://192.168.1.100/datasets
# → Mounts to /Volumes/datasets

# Download to network drive
./docker-run.sh download /Volumes/datasets quickdraw

# Train
./docker-run.sh train /Volumes/datasets 100 32 0.001
```

### Example 3: Scheduled Downloads to External Drive

```bash
# Set up download to run at specific time
# In Terminal 1:
./docker-run.sh download /Volumes/MyDrive/datasets quickdraw

# While downloading, build Docker in Terminal 2:
./docker-run.sh build

# After both complete, train
./docker-run.sh train /Volumes/MyDrive/datasets 100
```

### Example 4: Multiple Datasets on Same Drive

```bash
# Organize multiple projects on one external drive
/Volumes/ExternalDrive/
├── supersvg/
│   ├── quickdraw/     # Downloaded with: ./docker-run.sh download /Volumes/ExternalDrive/supersvg/quickdraw quickdraw
│   └── icons/         # Downloaded with: ./docker-run.sh download /Volumes/ExternalDrive/supersvg/icons icons
└── other_ml_project/
    └── datasets/
```

---

## 🔗 Environment Variable Method (Persistent)

### Option 1: Per-Command

```bash
# Download
DATA_PATH=/Volumes/MyDrive/datasets ./docker-run.sh download quickdraw

# Train
DATA_PATH=/Volumes/MyDrive/datasets ./docker-run.sh train input 100 32 0.001

# Interactive
DATA_PATH=/Volumes/MyDrive/datasets ./docker-run.sh interactive input

# Docker Compose
DATA_PATH=/Volumes/MyDrive/datasets docker-compose up
```

### Option 2: Shell Profile (Persistent for Session)

```bash
# Add to ~/.zshrc or ~/.bash_profile
export DATA_PATH=/Volumes/MyDrive/SuperSVG_datasets

# Then reload
source ~/.zshrc

# Now just use commands normally
./docker-run.sh download quickdraw
./docker-run.sh train input 100
```

### Option 3: .env File (Project-Wide)

```bash
# Create .env in SuperSVG directory
echo 'DATA_PATH=/Volumes/MyDrive/datasets' > .env

# Then commands automatically use that path
# Note: Requires docker-compose to load .env (default behavior)
```

---

## 💾 Path Examples by Device Type

### USB Drives

```bash
/Volumes/USB_Drive_Name
/Volumes/Kingston
/Volumes/SanDisk
```

### External Hard Drives

```bash
/Volumes/My Passport
/Volumes/WD External
/Volumes/Seagate
```

### Network Drives (After mounting)

```bash
/Volumes/nas_share
/Volumes/network_storage
/Volumes/home_server
```

### SD Cards

```bash
/Volumes/SD_Card
/Volumes/Camera_Card
```

---

## ⚙️ Docker Configuration for External Drives

### Option 1: Environment Variable (Recommended)

```bash
DATA_PATH=/Volumes/MyDrive/datasets ./docker-run.sh train input 100
```

### Option 2: docker-compose.yml (Manual Edit)

```yaml
services:
  supersvg:
    volumes:
      # Change from default ./input to external drive
      - /Volumes/MyDrive/SuperSVG_datasets:/data
      - ./output_coarse:/workspace/output_coarse
      - ./logs:/workspace/logs
      - ./checkpoints:/workspace/checkpoints
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - PYTHONPATH=/workspace
```

Then run:

```bash
docker-compose up
```

### Option 3: Docker Run Command

```bash
docker run --rm -it \
  -v /Volumes/MyDrive/SuperSVG_datasets:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest \
  micromamba run -n live python main_coarse.py --data_path=/data
```

---

## 🚀 Complete Workflow: MacBook with Limited Storage

**Setup:** MacBook Pro 256GB with USB-C external drive

### Step 1: Prepare External Drive (One-time)

```bash
# See available drives
./docker-run.sh list-drives

# Create dataset folder on external drive
mkdir -p /Volumes/My_Passport/ml_work/supersvg/datasets
```

### Step 2: Parallel Build & Download

```bash
# Terminal 1: Download datasets (starts immediately)
./docker-run.sh download /Volumes/My_Passport/ml_work/supersvg/datasets quickdraw
# This takes ~1-2 hours

# Terminal 2 (while terminal 1 is downloading): Build Docker
./docker-run.sh build
# This takes ~15-20 minutes and finishes while downloading continues
```

### Step 3: Train (After both complete)

```bash
# Quick test first
./docker-run.sh test /Volumes/My_Passport/ml_work/supersvg/datasets 16

# Full training
./docker-run.sh train /Volumes/My_Passport/ml_work/supersvg/datasets 100 32 0.001
```

**Total time with parallel execution:** ~2 hours (vs ~3.5 hours sequential!)

---

## 📊 Storage Space Management

### Check Current Usage

```bash
# Total size of all data
du -sh /Volumes/MyDrive/ml_work/supersvg/

# Size of specific dataset
du -sh /Volumes/MyDrive/ml_work/supersvg/datasets/quickdraw

# Available space on drive
df -h /Volumes/MyDrive
```

### Clean Up (If Needed)

```bash
# Remove specific dataset
rm -rf /Volumes/MyDrive/datasets/quickdraw

# Or download only what you need
./docker-run.sh download /Volumes/MyDrive/datasets test  # 5 MB only
```

---

## 🐛 Troubleshooting

### External Drive Not Appearing

```bash
# List all drives
ls -la /Volumes/

# Check disk utility
diskutil list

# Try remounting
diskutil mount /dev/diskX  # Replace X with your disk
```

### Permission Denied Error

```bash
# Check permissions
ls -la /Volumes/MyDrive/

# If needed, fix permissions
sudo chown -R $(whoami) /Volumes/MyDrive/datasets

# Or check if drive is write-protected
# If yes: Disable write protection on the device
```

### Docker Can't Access External Drive

```bash
# Docker Desktop → Preferences → Resources → File Sharing
# Add the external drive path:
# /Volumes/MyDrive

# Then restart Docker
```

### Slow Performance from External Drive

```bash
# This is normal for USB 2.0 or older USB 3.0
# Switch to newer USB 3.1/3.2 drives for better speed
# Or use Thunderbolt external drives

# Check drive speed
diskutil info /Volumes/MyDrive | grep "Protocol"
```

### Path with Spaces in Name

```bash
# macOS allows spaces in drive names. Use quotes:
./docker-run.sh download "/Volumes/My Passport/datasets" quickdraw

# Or use environment variable
DATA_PATH="/Volumes/My Passport/datasets" docker-compose up
```

---

## ✅ Verification

After setup, verify everything works:

```bash
# 1. Check drive is mounted
./docker-run.sh list-drives

# 2. Check data downloaded
ls -la /Volumes/MyDrive/SuperSVG_datasets/quickdraw/

# 3. Count images
find /Volumes/MyDrive/SuperSVG_datasets -name "*.png" | wc -l

# 4. Test with small training
./docker-run.sh test /Volumes/MyDrive/SuperSVG_datasets 16
```

---

## 📝 Reference Commands

```bash
# List available drives
./docker-run.sh list-drives

# Download to external drive
./docker-run.sh download /Volumes/MyDrive/datasets [test|quickdraw|icons|all]

# Train from external drive
./docker-run.sh train /Volumes/MyDrive/datasets 100 32 0.001

# Using environment variable for any command
DATA_PATH=/Volumes/ExternalDrive/datasets ./docker-run.sh [command]

# Check available space
df -h /Volumes/MyDrive

# See data usage
du -sh /Volumes/MyDrive/datasets
```

---

You can now store all datasets on external storage while keeping your MacBook's storage free! 🎉
