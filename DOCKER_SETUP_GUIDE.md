# SuperSVG Docker Setup Guide (Time-Optimized)

This guide provides the fastest path to running SuperSVG with Docker, with parallel workflows to minimize total setup time.

## Quick Start (5-10 minutes)

### Prerequisites

- Docker Desktop installed and running
- 50GB+ free disk space for large datasets (test dataset is 5 MB)
- 16GB+ RAM allocated to Docker

### Automated Dataset Download

**The easiest way - one command downloads and prepares everything:**

```bash
# Download test dataset (fastest, 30 seconds)
./docker-run.sh download test

# Or download complete datasets
./docker-run.sh download all
```

**Or with make:**

```bash
make download-test
make download        # all datasets
```

This automatically handles:

- ✅ Creating directory structure
- ✅ Converting formats (SVG → PNG, NDJSON → PNG)
- ✅ Organizing by category
- ✅ Progress reporting

---

## Dataset Options

### Option A: Test Dataset (Fastest - 30 seconds)

```bash
./docker-run.sh download test
# Creates: input/test/ with 5 synthetic images
# Size: ~5 MB
# Use for: Verifying setup works before committing to large downloads
```

### Option B: Quick Draw Dataset (Recommended - ~1.5 hours)

```bash
./docker-run.sh download quickdraw
# Downloads: 25 categories × ~500 images each = 12,500 images
# Size: ~1.5 GB
# Use for: Good balance of data diversity and training time
```

### Option C: Tabler Icons Dataset (~30 minutes)

```bash
./docker-run.sh download icons
# Converts: 4,500+ SVG icons to PNG
# Size: ~500 MB
# Use for: Small, fast training on icons
```

### Option D: All Datasets (Most Complete - 2+ hours)

```bash
./docker-run.sh download all
# Downloads: test + quickdraw + icons
# Size: ~2+ GB total
# Use for: Comprehensive training with variety
```

### Option E: Manual Dataset (Advanced)

```bash
# Create your own directory structure
mkdir -p input/my_dataset/{class_1,class_2,class_3}
# Add image files (.jpg or .png):
# input/my_dataset/class_1/image1.jpg
# input/my_dataset/class_2/image2.jpg
# etc.

# Then train with
./docker-run.sh train input/my_dataset
```

---

## Step-by-Step Setup Workflow

### Timeline: Total ~30-60 minutes (parallel execution)

| Step | Duration | Parallel | Command                           |
| ---- | -------- | -------- | --------------------------------- |
| 1    | ~30s     | Yes\*    | `./docker-run.sh download test`   |
| 2    | ~15-20m  | Yes\*\*  | `./docker-run.sh build`           |
| 3    | ~5m      | After 1  | `./docker-run.sh test input 16`   |
| 4    | Variable | After 3  | `./docker-run.sh train input 100` |

\* Start download immediately
\*\* Docker build happens in parallel with download

---

## Full Setup Instructions

### 1️⃣ Download Datasets (30 seconds to 2+ hours)

```bash
# Fastest path to get started
./docker-run.sh download test

# For better training results
./docker-run.sh download quickdraw

# For complete setup
./docker-run.sh download all
```

### 2️⃣ Build Docker Image (15-20 minutes)

```bash
cd /Users/andreacollet/Projects/SuperSVG

# Start build in background
docker-compose build

# Or with progress
docker build -f Dockerfile.mamba -t supersvg:latest .
```

**While this builds** → Move to Step 2

---

### 2️⃣ Download Datasets (Parallel with Step 1)

**Run these while Docker is building:**

```bash
# Fastest: Test dataset (30 seconds)
./docker-run.sh download test

# Recommended: Quick Draw dataset (1-2 hours)
./docker-run.sh download quickdraw

# Complete: All datasets (2+ hours)
./docker-run.sh download all
```

The download script automatically:

- ✅ Creates the correct directory structure
- ✅ Converts formats if needed (SVG → PNG)
- ✅ Organizes files by category
- ✅ Shows progress

You can run this in parallel with Docker build!

---

### 3️⃣ Start Docker Container

Once build completes (check with `docker images | grep supersvg`):

#### Interactive Mode (Development/Testing)

```bash
# This starts a bash shell where you can run commands manually
docker-compose up -d
docker-compose exec supersvg bash

# Inside container:
micromamba run -n live python main_coarse.py --data_path=/data --num_epochs=1
```

#### Training Mode (Production)

```bash
# Create a training-specific compose override
cat > docker-compose.training.yml << 'EOF'
services:
  supersvg:
    command: >
      micromamba run -n live python main_coarse.py
      --data_path=/data
      --batch_size=32
      --num_epochs=100
      --lr=0.001
    stdin_open: false
    tty: false
EOF

# Run training
docker-compose -f docker-compose.yml -f docker-compose.training.yml up
```

#### Detached Mode (Run in Background)

```bash
# Start container in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop when done
docker-compose down
```

---

## Configuration Reference

### Set Custom Data Path

```bash
# Using environment variable (preferred)
DATA_PATH=/path/to/your/dataset docker-compose up

# Or edit docker-compose.yml:
# Change: - ${DATA_PATH:-.}/input:/data
# To: - /absolute/path/to/dataset:/data
```

### Volume Mounts Explained

```yaml
volumes:
  - ${DATA_PATH:-.}/input:/data # Input images (inside container at /data)
  - ./output_coarse:/workspace/output_coarse # Training outputs (persisted locally)
  - ./logs:/workspace/logs # Training logs (persisted locally)
  - ./checkpoints:/workspace/checkpoints # Model checkpoints (persisted locally)
```

---

## Verification Checklist

Before running training, verify:

```bash
# ✅ Check Docker image built successfully
docker images | grep supersvg

# ✅ Check data directory has images
ls -la input/
find input -name "*.jpg" -o -name "*.png" | head -5

# ✅ Test container can access data
docker-compose run supersvg ls /data

# ✅ Check output directories exist
mkdir -p output_coarse logs checkpoints
```

---

## Running Training

### Test Run (Quick Verification)

```bash
docker-compose run supersvg \
  micromamba run -n live python main_coarse.py \
  --data_path=/data \
  --num_epochs=1 \
  --batch_size=16
```

### Full Training (Production)

```bash
docker-compose run supersvg \
  micromamba run -n live python main_coarse.py \
  --data_path=/data \
  --num_epochs=100 \
  --batch_size=32 \
  --lr=0.001
```

### Monitor Training

```bash
# In another terminal
docker-compose logs -f

# Check Docker resource usage
docker stats supersvg-training
```

---

## Troubleshooting

### ❌ "Mount denied: The path does not exist"

**Solution**: Ensure local directories exist

```bash
mkdir -p input output_coarse logs checkpoints
ls -la input/  # Should show subdirectories with images
```

### ❌ "No such file or directory: /data"

**Solution**: Check docker-compose.yml volume mount

```bash
docker-compose config  # Shows resolved configuration
```

### ❌ Container exits immediately

**Solution**: Verify data is present AND check for runtime errors

```bash
# Run in interactive mode to see errors
docker-compose run -it supersvg bash
micromamba run -n live python main_coarse.py --data_path=/data
```

### ❌ "Out of memory" errors

**Solution**: Reduce batch size or allocate more memory to Docker

```bash
# Docker Desktop → Preferences → Resources → Memory → increase allocation

# In training command
python main_coarse.py --data_path=/data --batch_size=16
```

---

## Next Steps

1. **While waiting for downloads**: Review [README.md](README.md) sections on training parameters
2. **After first successful run**: Experiment with different batch sizes for your hardware
3. **For optimization**: See "Performance Optimization" section in main README

---

## Dataset Size Reference

| Dataset           | Size   | Training Time (RTX 3070) | Use Case      |
| ----------------- | ------ | ------------------------ | ------------- |
| Test (10 images)  | <1MB   | <1 min                   | Verification  |
| Quick Draw (1M)   | ~30GB  | 18-24h                   | Full training |
| Quick Draw (100K) | ~3GB   | 2-3h                     | Development   |
| Icons (30K)       | ~200MB | 30-45m                   | Testing       |

Choose based on your available time and patience! 🚀
