# SuperSVG Docker - Quick Start Reference

## ⚡ TL;DR (30 seconds)

```bash
# 0. Setup Python environment (first time only, ~30 seconds)
./setup_dataset_env.sh

# 1. Download datasets (one-time, ~30 min to 2 hours depending on dataset)
./docker-run.sh download test              # Fastest (5 MB, 30 seconds)
# or
./docker-run.sh download all               # Complete (2+ GB, 1-2 hours)

# 2. Build Docker image (one-time, ~15 min, run while data downloads!)
./docker-run.sh build

# 3. SKIP local testing on M3 Mac - deploy to cloud (see CLOUD_SETUP_README.md)
#    OR export image: docker save supersvg:latest | gzip > supersvg.tar.gz
```

**Note for M3 Mac Users**: Docker image uses `linux/amd64` for cloud compatibility. Rosetta emulation may not work reliably for testing. **Recommended**: Skip local testing and deploy directly to cloud GPU instance. See [CLOUD_SETUP_README.md](CLOUD_SETUP_README.md) for deployment guides.

**Or with make:**

```bash
make download-test
make build
make train
```

---

## 🎯 Common Commands

| Goal                      | Command                                    |
| ------------------------- | ------------------------------------------ |
| **Download test data**    | `./docker-run.sh download test`            |
| **Download Quick Draw**   | `./docker-run.sh download quickdraw`       |
| **Download all datasets** | `./docker-run.sh download all`             |
| **Build image**           | `./docker-run.sh build`                    |
| **Test setup**            | `./docker-run.sh test input 16`            |
| **Interactive shell**     | `./docker-run.sh interactive input`        |
| **Train (100 epochs)**    | `./docker-run.sh train input 100 32 0.001` |
| **Run in background**     | `./docker-run.sh daemon input`             |
| **View logs**             | `./docker-run.sh logs`                     |
| **Stop container**        | `./docker-run.sh stop`                     |

---

## 📁 Expected Directory Structure

```
SuperSVG/
├── docker-compose.yml
├── docker-run.sh
├── Dockerfile.mamba
├── main_coarse.py
├── DOCKER_SETUP_GUIDE.md
│
├── input/                       ← Add your images here
│   ├── class_1/
│   │   ├── image1.jpg
│   │   └── image2.jpg
│   └── class_2/
│       └── image3.jpg
│
├── output_coarse/               ← Auto-created, training outputs
├── logs/                        ← Auto-created, training logs
└── checkpoints/                 ← Auto-created, model checkpoints
```

---

## 🚀 Step-by-Step: First Time Setup

### Step 1: Download Datasets (30 minutes to 2 hours)

**Option 1: Quick Test (Fastest - 30 seconds)**

```bash
# Creates 5 synthetic test images - perfect for verifying setup
./docker-run.sh download test
```

**Option 2: Quick Draw Dataset (Recommended - ~1.5 hours)**

```bash
# Downloads ~13K images from 25 Drawing categories
# Great for training - covers many object types
./docker-run.sh download quickdraw
```

**Option 3: Tabler Icons Dataset (~500 MB - 30 minutes)**

```bash
# Downloads 4,500+ free SVG icons converted to PNG
# Smaller, good for faster testing before full training
./docker-run.sh download icons
```

**Option 4: All Datasets (Most Complete - 2+ hours)**

```bash
# Downloads test + quickdraw + icons
./docker-run.sh download all
```

**Or with make:**

```bash
make download-test       # Quick test
make download-quickdraw  # Quick Draw only
make download-icons      # Tabler Icons only
make download            # All datasets
```

**Note**: These downloads happen in parallel with Docker build for time efficiency!

### Step 2: Build Docker (15-20 minutes, one-time)

```bash
# Start build - can do while Step 1 continues
./docker-run.sh build

# Or manually
docker-compose build
```

### Step 3: Test It Works (5 minutes)

```bash
# Verify prerequisites
./docker-run.sh check

# Run 1-epoch test
./docker-run.sh test input 16
```

### Step 4: Run Full Training (Variable)

```bash
# Simple: defaults (100 epochs, batch 32, lr 0.001)
./docker-run.sh train input

# Custom: 200 epochs, batch 16, learning rate 0.0005
./docker-run.sh train input 200 16 0.0005

# Background mode
./docker-run.sh daemon input
docker-compose logs -f  # In another terminal
```

---

## 📊 Training Time Estimates

| Hardware           | Dataset (1M) | Icons (30K) | Notes                            |
| ------------------ | ------------ | ----------- | -------------------------------- |
| **Cloud RTX 4090** | ~8-12h       | 1-2 hours   | **Recommended for production**   |
| **Cloud RTX 3090** | ~12-18h      | 2-3 hours   | Good price/performance           |
| Cloud RTX 3070     | ~18-24h      | 2-3 hours   | Budget option                    |
| MacBook M3 Pro     | Very slow    | Very slow   | Local testing only (via Rosetta) |
| CPU Only (cloud)   | ~5-7 days    | 12-24 hours | Not recommended                  |

**Recommended Workflow**:

1. Test locally with small dataset (5 images) to verify setup works
2. Deploy to cloud GPU for actual training (see `CLOUD_SETUP_README.md`)
3. Use external storage for datasets if needed

---

## 🔧 Helper Script Commands

### `./docker-run.sh build`

Build the Docker image from Dockerfile

### `./docker-run.sh interactive [data_path]`

Start interactive bash shell for development/debugging

```bash
./docker-run.sh interactive input
# Inside container:
# $ micromamba run -n live python main_coarse.py --data_path=/data
# $ micromamba run -n live python -c "import torch; print(torch.cuda.is_available())"
```

### `./docker-run.sh test [data_path] [batch_size]`

Run quick verification (1 epoch)

```bash
./docker-run.sh test input 16
```

### `./docker-run.sh train [data_path] [epochs] [batch_size] [learning_rate]`

Run full training

```bash
./docker-run.sh train input 100 32 0.001
```

### `./docker-run.sh daemon [data_path]`

Run in background, returns immediately

```bash
./docker-run.sh daemon input
# Then monitor with: docker-compose logs -f
```

### `./docker-run.sh logs`

Show live training logs

### `./docker-run.sh stop`

Stop the running container

### `./docker-run.sh clean`

Clean up containers and optionally remove Docker image

### `./docker-run.sh check`

Verify prerequisites are met

---

## 🐛 Troubleshooting

| Error                                   | Fix                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------- |
| `cannot execute binary file` on M3 Mac  | **Expected** - Rosetta limitation. Deploy to cloud instead (see below) |
| `Mount denied: The path does not exist` | `mkdir -p input && ls -la input/`                                      |
| Very slow on M3 Mac                     | Expected - using AMD64 via Rosetta. Deploy to cloud for speed          |
| Container exits immediately             | Normal on M3 - skip to cloud deployment                                |
| Out of memory errors (on cloud)         | Reduce batch size: `--batch_size=16`                                   |
| "Cannot connect to Docker daemon"       | Start Docker Desktop                                                   |

### M3 Mac Workaround for Local Testing

If you need to test locally before cloud deployment:

```bash
# Build ARM64 version (won't work on cloud, but works locally)
# Temporarily edit docker-compose.yml: change platform to linux/arm64
./docker-run.sh build

# Test locally
./docker-run.sh test input 16

# Then rebuild AMD64 for cloud
# Change docker-compose.yml back to linux/amd64
./docker-run.sh build
```

**Recommended**: Skip local testing, go straight to cloud deployment.

---

## 📖 Full Documentation

See `DOCKER_SETUP_GUIDE.md` for:

- Detailed dataset download instructions
- Performance optimization tips
- GPU setup and NVIDIA Docker
- Cloud deployment options (GCP, AWS, RunPod, Paperspace)
- Detailed troubleshooting

---

## ✅ Verification Checklist

Before starting training:

- [ ] Docker Desktop running: `docker ps`
- [ ] Images in input directory: `find input -type f | wc -l`
- [ ] Docker image built: `docker images | grep supersvg`
- [ ] Config valid: `docker-compose config > /dev/null`
- [ ] Test run works: `./docker-run.sh test input 16`

---

## 💡 Pro Tips

**Parallel Setup for Time Efficiency**:

1. Start Docker build (`./docker-run.sh build`) in Terminal 1
2. Download dataset in Terminal 2 while build runs
3. By the time dataset is ready, Docker image is built and ready to train

**Monitor Resource Usage**:

```bash
# In another terminal
docker stats supersvg-training
```

### For M3 Mac Users (Recommended Path):

1. ✅ **Setup complete** - You have:
   - Python environment set up
   - Datasets downloaded (or ready to download on cloud)
   - Docker image built (AMD64 for cloud)

2. 🚀 **Deploy to Cloud GPU**:
   - See [CLOUD_SETUP_README.md](CLOUD_SETUP_README.md) for detailed guides
   - Transfer your datasets to cloud instance
   - Run training on real GPU hardware

3. 📊 **Cloud Platforms**:
   - **RunPod**: ~$0.34/hr for RTX 3090 ([setup-runpod.sh](choose-platform.sh))
   - **Lambda Labs**: ~$0.50/hr for RTX 4090 ([setup-lambda-labs.sh](setup-lambda-labs.sh))
   - **AWS EC2**: Enterprise option ([setup-aws-ec2.sh](setup-aws-ec2.sh))

### Export Docker Image for Cloud:

```bash
# Save image to tar file (for transferring to cloud)
docker save supersvg:latest | gzip > supersvg.tar.gz

# On cloud instance, load the image:
gunzip -c supersvg.tar.gz | docker load
```

```bash
# Quick test with tiny batch
./docker-run.sh test input 4
```

---

## 🎓 Next Steps

Download test dataset locally** to verify setup: `./docker-run.sh download test` 2. **Quick local test** (will be slow on M3): `./docker-run.sh test input 16` 3. **Review CLOUD_SETUP_README.md** for cloud deployment options (RunPod, Lambda Labs, AWS) 4. **Deploy to cloud GPU** for actual training with full dataset 5. **Monitor and optimize\*\* batch size based on cloud hardware

**Recommended Cloud Platforms**:

- **RunPod**: Pre-configured GPU instances, ~$0.34/hr for RTX 3090
- **Lambda Labs**: Dedicated GPU cloud, ~$0.50/hr for RTX 4090
- **AWS EC2**: Enterprise option with G4/P3 instances

See `CLOUD_SETUP_README.md` and helper scripts: `setup-lambda-labs.sh`, `setup-aws-ec2.sh`s) 4. **Monitor and optimize** batch size based on your hardware

Happy training! 🚀
