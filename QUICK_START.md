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

# 3. Run training
./docker-run.sh train input 100 32 0.001
```

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

## ❌ Why Container Was Exiting

**Problem**: `docker-compose up` would start but immediately exit with code 0

**Root Causes**:

1. ❌ `/path/to/your/dataset` - placeholder path didn't exist
2. ❌ Missing data at `/data` mount point
3. ❌ Deprecated `version: '3.8'` warning

**Solution**: ✅ Fixed in updated `docker-compose.yml`:

- Removed deprecated version field
- Changed to `${DATA_PATH:-.}/input:/data` (looks for local `input/` directory)
- Set interactive mode by default (starts bash instead of running main_coarse.py immediately)

---

## 📁 Expected Directory Structure

```
SuperSVG/
├── docker-compose.yml          ← Updated (fixed)
├── docker-run.sh               ← New helper script
├── Dockerfile.mamba            ← Unchanged
├── main_coarse.py              ← Unchanged
├── DOCKER_SETUP_GUIDE.md       ← New detailed guide
│
├── input/                       ← Add your images here
│   ├── class_1/
│   │   ├── image1.jpg
│   │   └── image2.jpg
│   └── class_2/
│       └── image3.jpg
│
├── output_coarse/              ← Auto-created, training outputs
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

| Hardware       | Dataset (1M) | Icons (30K) |
| -------------- | ------------ | ----------- |
| MacBook M3 Pro | ~2-3 days    | 4-6 hours   |
| RTX 3070       | ~18-24h      | 2-3 hours   |
| RTX 4080       | ~12-16h      | 1-2 hours   |
| CPU Only       | ~5-7 days    | 12-24 hours |

**Recommendation**: Start with small test dataset (5 images) to verify setup, then scale up.

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

| Error                                   | Fix                                                        |
| --------------------------------------- | ---------------------------------------------------------- |
| `Mount denied: The path does not exist` | `mkdir -p input && ls -la input/`                          |
| `No such file or directory: /data`      | Check `docker-compose config \| grep source`               |
| Container exits immediately             | `./docker-run.sh interactive input` to see error           |
| Out of memory errors                    | Reduce batch size: `--batch_size=16`                       |
| "Cannot connect to Docker daemon"       | Start Docker Desktop                                       |
| Slow training on macOS                  | Normal! M3 Pro single-GPU: ~12-15 min/epoch for 1M dataset |

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

**Access Training Outputs**:

- Outputs: `output_coarse/` (updated in real-time)
- Logs: `logs/` (training progress)
- Checkpoints: `checkpoints/` (saved models)

**Speed Up for Testing**:

```bash
# Quick test with tiny batch
./docker-run.sh test input 4
```

---

## 🎓 Next Steps

1. **Review main README.md** for training parameters and architecture
2. **Start with test dataset** (5-10 images) to verify everything works
3. **Then scale to full dataset** (Quick Draw, ImageNet, Icons)
4. **Monitor and optimize** batch size based on your hardware

Happy training! 🚀
