# Dataset Download & Setup - Complete Reference

## ✨ What's New

Complete automated dataset download system with multiple options. No more manual configuration!

## 🚀 Quick Start - 3 Commands

```bash
# 1. Download datasets (choose one)
./docker-run.sh download test           # 30 seconds - minimal test
./docker-run.sh download quickdraw      # 1-2 hours - recommended
./docker-run.sh download all            # 2+ hours - comprehensive

# 2. Build Docker (parallel with downloads!)
./docker-run.sh build

# 3. Train
./docker-run.sh train input 100 32 0.001
```

**Or with make:**

```bash
make download-test
make build
make train
```

---

## 📁 New Files Added

| File                                  | Purpose                                  |
| ------------------------------------- | ---------------------------------------- |
| **`download_datasets.sh`**            | Automated dataset download & preparation |
| **`docker-run.sh`** (updated)         | Added `download` command                 |
| **`Makefile`** (updated)              | Added `download-*` targets               |
| **`QUICK_START.md`** (updated)        | Includes download commands               |
| **`DOCKER_SETUP_GUIDE.md`** (updated) | Detailed download documentation          |
| **`DOCKER_SOLUTION.md`** (updated)    | References download automation           |

---

## 💾 Available Datasets

### Option 1: Test Dataset (Fastest)

```bash
./docker-run.sh download test
# Size: ~5 MB
# Time: 30 seconds
# Creates: 5 synthetic images for verification
# Use: Quick setup verification before committing to larger downloads
```

### Option 2: Quick Draw (Recommended)

```bash
./docker-run.sh download quickdraw
# Size: ~1.5 GB
# Time: 1-2 hours
# Creates: ~13,000 images from 25 drawing categories
# Categories: airplane, apple, banana, basketball, beard, car, cat, circle, cloud,
#             diamond, dog, eye, flower, heart, house, lightning, moon, mountain,
#             pizza, star, sun, tree, triangle, umbrella, zigzag
# Use: Good balance of data diversity and training time
```

### Option 3: Tabler Icons

```bash
./docker-run.sh download icons
# Size: ~500 MB
# Time: ~30 minutes
# Creates: ~4,500 SVG icons converted to PNG, organized by category
# Use: Smaller dataset for faster testing or icon-specific training
```

### Option 4: All Datasets (Complete)

```bash
./docker-run.sh download all
# Size: ~2 GB total
# Time: 2+ hours total
# Downloads: test + quickdraw + icons
# Use: Maximum data diversity for comprehensive training
```

---

## 🔄 Optimized Parallel Workflow

The setup is now optimized for parallel execution:

```
Timeline: ~30-60 minutes total (parallel paths)

Terminal 1 (Data Download):          Terminal 2 (Docker Build):
└─ 30 sec - 2 hours                 └─ 15-20 minutes
   download_datasets.sh                docker build

Both can run simultaneously!
```

**Recommended sequence:**

```bash
# Terminal 1 - Start download first
./docker-run.sh download quickdraw

# Terminal 2 - While that downloads, build Docker
./docker-run.sh build

# Later - Once both complete, train
./docker-run.sh train input 100 32 0.001
```

---

## 🎯 Common Workflows

### Workflow 1: Quick Verification (30 minutes)

```bash
# Best for: Verifying setup works before long downloads
./docker-run.sh download test    # 30 seconds
./docker-run.sh build            # 15-20 minutes
./docker-run.sh test input 16    # Quick verification
# Total: ~20 minutes
```

### Workflow 2: Balanced Setup (2-3 hours)

```bash
# Best for: Good balance of training data and setup time
./docker-run.sh download quickdraw  # 1-2 hours (in parallel)
./docker-run.sh build               # 15-20 min (in parallel)
./docker-run.sh train input 50 32   # 50 epochs
```

### Workflow 3: Complete Setup (2.5+ hours)

```bash
# Best for: Maximum data diversity
./docker-run.sh download all        # 2+ hours
./docker-run.sh build               # 15-20 min (parallel)
./docker-run.sh train input 100     # Full training
```

---

## 📊 Data Directory Structure

After download, you'll have:

```
SuperSVG/
├── input/
│   ├── test/                    # Test dataset (if downloaded)
│   │   └── test_class/
│   │       ├── test_000.jpg
│   │       ├── test_001.jpg
│   │       └── ...
│   │
│   ├── quickdraw/               # Quick Draw dataset (if downloaded)
│   │   ├── airplane/
│   │   │   ├── 000000.png
│   │   │   ├── 000001.png
│   │   │   └── ...
│   │   ├── apple/
│   │   ├── banana/
│   │   └── ... (25 categories)
│   │
│   └── tabler_icons/            # Tabler icons (if downloaded)
│       ├── png_224/
│       │   ├── alert/
│       │   ├── arrow/
│       │   ├── bell/
│       │   └── ... (50+ categories)
│
├── output_coarse/               # Training outputs (created during training)
├── logs/                        # Training logs (created during training)
└── checkpoints/                 # Model checkpoints (created during training)
```

---

## 🛠️ Using Custom Datasets

To use your own dataset:

```bash
# Create directory structure
mkdir -p input/my_dataset/{class_1,class_2,class_3}

# Add images (JPG or PNG)
cp /path/to/images/*.jpg input/my_dataset/class_1/
cp /path/to/images/*.png input/my_dataset/class_2/

# Train with custom dataset
./docker-run.sh train input/my_dataset 100 32 0.001
```

---

## 📞 Command Reference

### Download Commands

```bash
# Via docker-run.sh
./docker-run.sh download test           # Test dataset
./docker-run.sh download quickdraw      # Quick Draw
./docker-run.sh download icons          # Tabler Icons
./docker-run.sh download all            # All datasets
./docker-run.sh download help           # Show options

# Via make
make download-test
make download-quickdraw
make download-icons
make download

# Direct script
./download_datasets.sh test
./download_datasets.sh quickdraw
./download_datasets.sh icons
./download_datasets.sh all
```

### Training Commands

```bash
# After download, train immediately
./docker-run.sh train input 100 32 0.001

# Or verify setup with test
./docker-run.sh test input 16

# View help
./docker-run.sh help
make help
```

---

## 🐛 Troubleshooting

### "curl: command not found"

The download script uses curl. Install with:

```bash
# macOS
brew install curl

# Linux
sudo apt-get install curl

# Already installed on most systems
```

### "convert: command not found"

For Tabler Icons conversion, install ImageMagick:

```bash
# macOS
brew install imagemagick

# Linux
sudo apt-get install imagemagick
```

### Download interrupted

Simply run again - the script skips already downloaded items:

```bash
./docker-run.sh download quickdraw
```

### Insufficient disk space

Check available space:

```bash
df -h .
# Ensure 50GB+ for full datasets
```

### Network timeout

If downloads timeout, you can retry. Large downloads may take time.

---

## 📈 Dataset Size Reference

| Dataset      | Size   | Time   | Images | Categories | Use Case          |
| ------------ | ------ | ------ | ------ | ---------- | ----------------- |
| Test         | 5 MB   | 30s    | 5      | 1          | Verify setup      |
| Quick Draw   | 1.5 GB | 1-2h   | 13K    | 25         | Recommended       |
| Tabler Icons | 500 MB | 30min  | 4.5K   | 50+        | Icons focused     |
| All          | 2+ GB  | 2+ hrs | ~18K   | 75+        | Maximum diversity |

---

## ✅ Verification

Confirm setup is complete:

```bash
# Check Docker
./docker-run.sh check

# Check data was downloaded
ls -la input/

# Count images
find input -type f | wc -l

# Verify config
docker-compose config > /dev/null && echo "✓ Config valid"
```

---

## 🚀 Next Steps

1. **Choose dataset**: Start with `make download-test` for quick verification
2. **Run download**: `./docker-run.sh download test`
3. **Build Docker** (parallel): `./docker-run.sh build`
4. **Verify**: `./docker-run.sh test input 16`
5. **Train**: `./docker-run.sh train input 100 32 0.001`

---

## 📖 Related Documentation

- **QUICK_START.md** - 5-minute reference guide
- **DOCKER_SETUP_GUIDE.md** - Comprehensive setup guide
- **DOCKER_SOLUTION.md** - Problem explanation and solutions
- **README.md** - Main project documentation

---

## 💡 Pro Tips

1. **Parallel execution saves time**: Start download and Docker build simultaneously
2. **Start small**: Use test dataset first to verify everything works
3. **Check progress**: Downloads show progress in real-time
4. **Network friendly**: Downloaded files are cached - retry safely if interrupted
5. **Space efficient**: Each dataset can be downloaded separately as needed

---

Everything is automated! No more manual dataset configuration. Just run one command and go! 🎉
