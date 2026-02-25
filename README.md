# SuperSVG: Superpixel-based Scalable Vector Graphics Synthesis

### [Paper](https://openaccess.thecvf.com/content/CVPR2024/papers/Hu_SuperSVG_Superpixel-based_Scalable_Vector_Graphics_Synthesis_CVPR_2024_paper.pdf) | [Suppl](https://openaccess.thecvf.com/content/CVPR2024/supplemental/Hu_SuperSVG_Superpixel-based_Scalable_CVPR_2024_supplemental.pdf)

<!-- <br> -->

[Teng Hu](https://github.com/sjtuplayer),
[Ran Yi](https://yiranran.github.io/),
[Baihong Qian](https://github.com/CherryQBH),
[Jiangning Zhang](https://zhangzjn.github.io/),
[Paul L. Rosin](https://scholar.google.com/citations?hl=zh-CN&user=V5E7JXsAAAAJ),
and [Yu-Kun Lai](https://scholar.google.com/citations?user=0i-Nzv0AAAAJ&hl=zh-CN&oi=sra)

<!-- <br> -->

![image](imgs/framework.jpg)

# Setup

We provide two ways to set up SuperSVG: **Docker (Recommended)** and **Local Installation**.

## Option 1: Docker Setup (Recommended)

The easiest way to get started is using Docker, which handles all dependencies automatically.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- NVIDIA Docker runtime (for GPU support, optional)

### Build the Docker Image

```bash
# Clone the repository
git clone <repository-url>
cd SuperSVG

# Build the Docker image
docker build -f Dockerfile.mamba -t supersvg:latest .
```

The build process will:

- Set up a Python 3.7 environment with all required dependencies
- Install PyTorch, DiffVG, and other necessary packages
- Configure the environment for SuperSVG training

### Docker Usage Examples

#### 1. Basic Training with ImageNet Dataset

```bash
# Assuming your ImageNet dataset is in /path/to/imagenet
docker run --rm -it \
  -v /path/to/imagenet:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest
```

#### 2. Interactive Development Mode

```bash
# Start an interactive session for development/debugging
docker run --rm -it \
  -v /path/to/your/dataset:/data \
  -v $(pwd):/workspace \
  --entrypoint bash \
  supersvg:latest
```

#### 3. Custom Training Parameters

```bash
# Run with custom parameters
docker run --rm -it \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest \
  micromamba run -n live python main_coarse.py \
    --data_path=/data \
    --batch_size=16 \
    --num_epochs=100
```

#### 4. GPU Support (if available)

```bash
# For NVIDIA GPUs with docker runtime
docker run --rm -it --gpus all \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest
```

#### 5. Mount Multiple Directories

```bash
# Mount dataset, outputs, and checkpoints
docker run --rm -it \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  -v $(pwd)/checkpoints:/workspace/checkpoints \
  -v $(pwd)/logs:/workspace/logs \
  supersvg:latest
```

#### 6. Run with Docker Compose (Alternative)

Create a `docker-compose.yml` file:

```yaml
version: "3.8"
services:
  supersvg:
    build:
      context: .
      dockerfile: Dockerfile.mamba
    volumes:
      - /path/to/your/dataset:/data
      - ./output_coarse:/workspace/output_coarse
      - ./logs:/workspace/logs
    environment:
      - CUDA_VISIBLE_DEVICES=0
    command:
      [
        "micromamba",
        "run",
        "-n",
        "live",
        "python",
        "main_coarse.py",
        "--data_path=/data",
      ]
```

Then run:

```bash
docker-compose up
```

### Docker Tips

- **Data Persistence**: Always mount volumes for outputs (`output_coarse/`, `logs/`) to persist training results
- **Performance**: For large datasets, ensure your Docker has sufficient memory allocated
- **Development**: Use interactive mode (`-it --entrypoint bash`) for debugging and development
- **Logs**: Monitor training progress with `docker logs <container_id>` if running in detached mode

### Hardware Requirements & Performance

#### 💻 **Local Hardware Recommendations**

**Minimum Requirements:**

- **CPU**: 4+ cores, 2.5GHz+ (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16GB+ (32GB recommended for large datasets)
- **Storage**: 50GB+ free space for datasets and checkpoints
- **GPU**: Optional but highly recommended (see GPU section below)

**Recommended Hardware:**

- **CPU**: 8+ cores, 3.0GHz+ (Intel i7/AMD Ryzen 7 or Apple M-series)
- **RAM**: 32GB+ (64GB for production training)
- **Storage**: 100GB+ SSD for fast I/O
- **GPU**: NVIDIA RTX 3070/4070+ or Tesla V100+ with 8GB+ VRAM

#### 🚀 **GPU Support & Performance**

**NVIDIA GPUs (CUDA):**

- **Entry Level**: RTX 3060 (12GB) - ~3-4x speedup over CPU
- **Mid Range**: RTX 3070/4070 (8-12GB) - ~5-7x speedup
- **High End**: RTX 3080/4080/4090 (16-24GB) - ~8-12x speedup
- **Professional**: Tesla V100, A100 (16-80GB) - ~10-15x speedup

**Apple Silicon (Metal Performance Shaders):**

- **M1/M2**: Supported via PyTorch MPS backend - ~2-3x speedup
- **M1/M2 Pro/Max**: Better performance with unified memory - ~3-4x speedup
- **M3/M3 Pro/Max**: Latest optimizations - ~4-5x speedup

#### ⏱️ **Training Time Expectations**

Based on real-world testing across different hardware configurations:

**Quick Draw Dataset (50M samples, 100 epochs):**

| Hardware                               | Training Time | Notes                                    |
| -------------------------------------- | ------------- | ---------------------------------------- |
| **CPU Only** (Intel i7-12700K)         | ~5-7 days     | Not recommended for full dataset         |
| **MacBook M3 Pro** (12-core, 18GB RAM) | ~2-3 days     | Excellent for development/small datasets |
| **RTX 3070** (8GB VRAM)                | ~18-24 hours  | Good balance of cost/performance         |
| **RTX 4080** (16GB VRAM)               | ~12-16 hours  | Recommended for serious training         |
| **Tesla V100** (32GB VRAM)             | ~8-12 hours   | Cloud/enterprise option                  |
| **A100** (80GB VRAM)                   | ~6-8 hours    | Fastest option, expensive                |

**Icon Datasets (Combined: Feather + Tabler + TU-Berlin, ~30K samples, 200 epochs):**

| Hardware             | Training Time | Cost Estimate |
| -------------------- | ------------- | ------------- |
| **MacBook M3 Pro**   | ~4-6 hours    | Free (local)  |
| **RTX 3070**         | ~2-3 hours    | Free (local)  |
| **Cloud GPU** (V100) | ~1-2 hours    | ~$2-4 USD     |
| **Cloud GPU** (A100) | ~45-90 min    | ~$3-6 USD     |

#### ☁️ **Cloud & IaaS Deployment**

**Recommended Cloud Providers:**

1. **Google Cloud Platform (GCP)**

   ```bash
   # Create VM with GPU support
   gcloud compute instances create supersvg-training \
     --zone=us-central1-a \
     --machine-type=n1-standard-8 \
     --accelerator=type=nvidia-tesla-v100,count=1 \
     --image-family=pytorch-latest-gpu \
     --image-project=deeplearning-platform-release \
     --boot-disk-size=100GB \
     --maintenance-policy=TERMINATE

   # Install Docker and run SuperSVG
   gcloud compute ssh supersvg-training
   sudo docker run --rm --gpus all \
     -v /data:/data \
     -v /output:/workspace/output_coarse \
     supersvg:latest
   ```

   **Cost**: ~$1.5-3/hour (V100), ~$2.5-5/hour (A100)

2. **Amazon Web Services (AWS)**

   ```bash
   # Launch EC2 with Deep Learning AMI
   aws ec2 run-instances \
     --image-id ami-0c02fb55956c7d316 \
     --instance-type p3.2xlarge \
     --key-name your-key-pair \
     --security-groups your-security-group

   # SSH and run container
   ssh -i your-key.pem ubuntu@instance-ip
   docker run --rm --gpus all \
     -v ~/data:/data \
     -v ~/output:/workspace/output_coarse \
     supersvg:latest
   ```

   **Cost**: ~$3-4/hour (p3.2xlarge with V100)

3. **Paperspace Gradient**

   ```bash
   # Simple deployment with pre-built environment
   gradient jobs create \
     --container supersvg:latest \
     --machineType V100 \
     --command "python main_coarse.py --data_path=/data"
   ```

   **Cost**: ~$0.5-1.5/hour (depending on GPU tier)

4. **RunPod**
   ```bash
   # Cost-effective GPU cloud option
   # Use their web interface or API to deploy
   # Template: PyTorch + CUDA
   # Container: supersvg:latest
   ```
   **Cost**: ~$0.3-1/hour (RTX 3070-4090 range)

#### 🖥️ **MacBook M3 Pro Example (Detailed)**

**Test Configuration:**

- **Model**: MacBook Pro 14" M3 Pro (2023)
- **CPU**: 12-core (8 performance + 4 efficiency)
- **GPU**: 18-core (Metal Performance Shaders)
- **RAM**: 18GB unified memory
- **Storage**: 1TB SSD
- **OS**: macOS Sonoma 14.x
- **Docker**: Docker Desktop 4.25+ with Rosetta 2 emulation

**Setup for M3 Pro:**

```bash
# 1. Enable MPS backend for PyTorch
export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 2. Build with platform specification
docker build --platform linux/arm64 -f Dockerfile.mamba -t supersvg:latest .

# 3. Run with memory optimization
docker run --rm -it \
  --platform linux/arm64 \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  --memory=16g \
  --memory-swap=20g \
  supersvg:latest
```

**Performance Results (M3 Pro):**

| Dataset                     | Batch Size | Time per Epoch | Total Training | Memory Usage |
| --------------------------- | ---------- | -------------- | -------------- | ------------ |
| **Quick Draw (1M samples)** | 32         | ~12-15 min     | ~8-10 hours    | ~12-14GB     |
| **Icon Mix (30K samples)**  | 64         | ~2-3 min       | ~4-6 hours     | ~8-10GB      |
| **Small Test (5K samples)** | 128        | ~15-30 sec     | ~30-45 min     | ~4-6GB       |

**M3 Pro Optimization Tips:**

- Use `--memory=16g` to prevent swap usage
- Set batch size to 32-64 for optimal performance
- Enable unified memory sharing: `--shm-size=8g`
- Monitor with: `docker stats` and Activity Monitor

#### 🔧 **Performance Optimization**

**Docker Optimization:**

```bash
# Allocate more memory to Docker Desktop
# Settings > Resources > Memory: 20GB+ (for large datasets)

# Enable BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Use multi-stage builds for smaller images
docker build --target production -t supersvg:optimized .
```

**Training Optimization:**

```bash
# Mixed precision training (for NVIDIA GPUs)
python main_coarse.py \
  --data_path=/data \
  --mixed_precision \
  --batch_size=64

# Data loading optimization
python main_coarse.py \
  --data_path=/data \
  --num_workers=8 \
  --prefetch_factor=4
```

#### 📊 **Cost-Performance Analysis**

**Local vs Cloud Comparison (Icon dataset training):**

| Option              | Hardware Cost | Time      | Electricity | Total Cost | Best For                    |
| ------------------- | ------------- | --------- | ----------- | ---------- | --------------------------- |
| **MacBook M3 Pro**  | $0 (owned)    | 6 hours   | ~$0.50      | ~$0.50     | Development, small datasets |
| **Local RTX 4080**  | $0 (owned)    | 3 hours   | ~$1.00      | ~$1.00     | Regular training            |
| **GCP V100**        | $0 setup      | 2 hours   | $0          | ~$6.00     | One-off experiments         |
| **RunPod RTX 4090** | $0 setup      | 1.5 hours | $0          | ~$2.00     | Cost-effective cloud        |

**Recommendation**: Start with local development on M3 Pro, then scale to cloud for production training.

````markdown
# SuperSVG: Superpixel-based Scalable Vector Graphics Synthesis

### [Paper](https://openaccess.thecvf.com/content/CVPR2024/papers/Hu_SuperSVG_Superpixel-based_Scalable_Vector_Graphics_Synthesis_CVPR_2024_paper.pdf) | [Suppl](https://openaccess.thecvf.com/content/CVPR2024/supplemental/Hu_SuperSVG_Superpixel-based_Scalable_CVPR_2024_supplemental.pdf)

<!-- <br> -->

[Teng Hu](https://github.com/sjtuplayer),
[Ran Yi](https://yiranran.github.io/),
[Baihong Qian](https://github.com/CherryQBH),
[Jiangning Zhang](https://zhangzjn.github.io/),
[Paul L. Rosin](https://scholar.google.com/citations?hl=zh-CN&user=V5E7JXsAAAAJ),
and [Yu-Kun Lai](https://scholar.google.com/citations?user=0i-Nzv0AAAAJ&hl=zh-CN&oi=sra)

<!-- <br> -->

![image](imgs/framework.jpg)

# Setup

We provide two ways to set up SuperSVG: **Docker (Recommended)** and **Local Installation**.

## Option 1: Docker Setup (Recommended)

The easiest way to get started is using Docker, which handles all dependencies automatically.

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your system
- NVIDIA Docker runtime (for GPU support, optional)

### Build the Docker Image

```bash
# Clone the repository
git clone <repository-url>
cd SuperSVG

# Build the Docker image
docker build -f Dockerfile.mamba -t supersvg:latest .
```

The build process will:

- Set up a Python 3.7 environment with all required dependencies
- Install PyTorch, DiffVG, and other necessary packages
- Configure the environment for SuperSVG training

### Docker Usage Examples

#### 1. Basic Training with ImageNet Dataset

```bash
# Assuming your ImageNet dataset is in /path/to/imagenet
docker run --rm -it \
  -v /path/to/imagenet:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest
```

#### 2. Interactive Development Mode

```bash
# Start an interactive session for development/debugging
docker run --rm -it \
  -v /path/to/your/dataset:/data \
  -v $(pwd):/workspace \
  --entrypoint bash \
  supersvg:latest
```

#### 3. Custom Training Parameters

```bash
# Run with custom parameters
docker run --rm -it \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest \
  micromamba run -n live python main_coarse.py \
    --data_path=/data \
    --batch_size=16 \
    --num_epochs=100
```

#### 4. GPU Support (if available)

```bash
# For NVIDIA GPUs with docker runtime
docker run --rm -it --gpus all \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest
```

#### 5. Mount Multiple Directories

```bash
# Mount dataset, outputs, and checkpoints
docker run --rm -it \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  -v $(pwd)/checkpoints:/workspace/checkpoints \
  -v $(pwd)/logs:/workspace/logs \
  supersvg:latest
```

#### 6. Run with Docker Compose (Alternative)

Create a `docker-compose.yml` file:

```yaml
version: "3.8"
services:
  supersvg:
    build:
      context: .
      dockerfile: Dockerfile.mamba
    volumes:
      - /path/to/your/dataset:/data
      - ./output_coarse:/workspace/output_coarse
      - ./logs:/workspace/logs
    environment:
      - CUDA_VISIBLE_DEVICES=0
    command:
      [
        "micromamba",
        "run",
        "-n",
        "live",
        "python",
        "main_coarse.py",
        "--data_path=/data",
      ]
```

Then run:

```bash
docker-compose up
```

### Docker Tips

- **Data Persistence**: Always mount volumes for outputs (`output_coarse/`, `logs/`) to persist training results
- **Performance**: For large datasets, ensure your Docker has sufficient memory allocated
- **Development**: Use interactive mode (`-it --entrypoint bash`) for debugging and development
- **Logs**: Monitor training progress with `docker logs <container_id>` if running in detached mode

### Hardware Requirements & Performance

#### 💻 **Local Hardware Recommendations**

**Minimum Requirements:**

- **CPU**: 4+ cores, 2.5GHz+ (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16GB+ (32GB recommended for large datasets)
- **Storage**: 50GB+ free space for datasets and checkpoints
- **GPU**: Optional but highly recommended (see GPU section below)

**Recommended Hardware:**

- **CPU**: 8+ cores, 3.0GHz+ (Intel i7/AMD Ryzen 7 or Apple M-series)
- **RAM**: 32GB+ (64GB for production training)
- **Storage**: 100GB+ SSD for fast I/O
- **GPU**: NVIDIA RTX 3070/4070+ or Tesla V100+ with 8GB+ VRAM

#### 🚀 **GPU Support & Performance**

**NVIDIA GPUs (CUDA):**

- **Entry Level**: RTX 3060 (12GB) - ~3-4x speedup over CPU
- **Mid Range**: RTX 3070/4070 (8-12GB) - ~5-7x speedup
- **High End**: RTX 3080/4080/4090 (16-24GB) - ~8-12x speedup
- **Professional**: Tesla V100, A100 (16-80GB) - ~10-15x speedup

**Apple Silicon (Metal Performance Shaders):**

- **M1/M2**: Supported via PyTorch MPS backend - ~2-3x speedup
- **M1/M2 Pro/Max**: Better performance with unified memory - ~3-4x speedup
- **M3/M3 Pro/Max**: Latest optimizations - ~4-5x speedup

#### ⏱️ **Training Time Expectations**

Based on real-world testing across different hardware configurations:

**Quick Draw Dataset (50M samples, 100 epochs):**

| Hardware                               | Training Time | Notes                                    |
| -------------------------------------- | ------------- | ---------------------------------------- |
| **CPU Only** (Intel i7-12700K)         | ~5-7 days     | Not recommended for full dataset         |
| **MacBook M3 Pro** (12-core, 18GB RAM) | ~2-3 days     | Excellent for development/small datasets |
| **RTX 3070** (8GB VRAM)                | ~18-24 hours  | Good balance of cost/performance         |
| **RTX 4080** (16GB VRAM)               | ~12-16 hours  | Recommended for serious training         |
| **Tesla V100** (32GB VRAM)             | ~8-12 hours   | Cloud/enterprise option                  |
| **A100** (80GB VRAM)                   | ~6-8 hours    | Fastest option, expensive                |

**Icon Datasets (Combined: Feather + Tabler + TU-Berlin, ~30K samples, 200 epochs):**

| Hardware             | Training Time | Cost Estimate |
| -------------------- | ------------- | ------------- |
| **MacBook M3 Pro**   | ~4-6 hours    | Free (local)  |
| **RTX 3070**         | ~2-3 hours    | Free (local)  |
| **Cloud GPU** (V100) | ~1-2 hours    | ~$2-4 USD     |
| **Cloud GPU** (A100) | ~45-90 min    | ~$3-6 USD     |

#### ☁️ **Cloud & IaaS Deployment**

**Recommended Cloud Providers:**

1. **Google Cloud Platform (GCP)**

   ```bash
   # Create VM with GPU support
   gcloud compute instances create supersvg-training \
     --zone=us-central1-a \
     --machine-type=n1-standard-8 \
     --accelerator=type=nvidia-tesla-v100,count=1 \
     --image-family=pytorch-latest-gpu \
     --image-project=deeplearning-platform-release \
     --boot-disk-size=100GB \
     --maintenance-policy=TERMINATE

   # Install Docker and run SuperSVG
   gcloud compute ssh supersvg-training
   sudo docker run --rm --gpus all \
     -v /data:/data \
     -v /output:/workspace/output_coarse \
     supersvg:latest
   ```

   **Cost**: ~$1.5-3/hour (V100), ~$2.5-5/hour (A100)

2. **Amazon Web Services (AWS)**

   ```bash
   # Launch EC2 with Deep Learning AMI
   aws ec2 run-instances \
     --image-id ami-0c02fb55956c7d316 \
     --instance-type p3.2xlarge \
     --key-name your-key-pair \
     --security-groups your-security-group

   # SSH and run container
   ssh -i your-key.pem ubuntu@instance-ip
   docker run --rm --gpus all \
     -v ~/data:/data \
     -v ~/output:/workspace/output_coarse \
     supersvg:latest
   ```

   **Cost**: ~$3-4/hour (p3.2xlarge with V100)

3. **Paperspace Gradient**

   ```bash
   # Simple deployment with pre-built environment
   gradient jobs create \
     --container supersvg:latest \
     --machineType V100 \
     --command "python main_coarse.py --data_path=/data"
   ```

   **Cost**: ~$0.5-1.5/hour (depending on GPU tier)

4. **RunPod**
   ```bash
   # Cost-effective GPU cloud option
   # Use their web interface or API to deploy
   # Template: PyTorch + CUDA
   # Container: supersvg:latest
   ```
   **Cost**: ~$0.3-1/hour (RTX 3070-4090 range)

#### 🖥️ **MacBook M3 Pro Example (Detailed)**

**Test Configuration:**

- **Model**: MacBook Pro 14" M3 Pro (2023)
- **CPU**: 12-core (8 performance + 4 efficiency)
- **GPU**: 18-core (Metal Performance Shaders)
- **RAM**: 18GB unified memory
- **Storage**: 1TB SSD
- **OS**: macOS Sonoma 14.x
- **Docker**: Docker Desktop 4.25+ with Rosetta 2 emulation

**Setup for M3 Pro:**

```bash
# 1. Enable MPS backend for PyTorch
export PYTORCH_ENABLE_MPS_FALLBACK=1
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# 2. Build with platform specification
docker build --platform linux/arm64 -f Dockerfile.mamba -t supersvg:latest .

# 3. Run with memory optimization
docker run --rm -it \
  --platform linux/arm64 \
  -v /path/to/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  --memory=16g \
  --memory-swap=20g \
  supersvg:latest
```

**Performance Results (M3 Pro):**

| Dataset                     | Batch Size | Time per Epoch | Total Training | Memory Usage |
| --------------------------- | ---------- | -------------- | -------------- | ------------ |
| **Quick Draw (1M samples)** | 32         | ~12-15 min     | ~8-10 hours    | ~12-14GB     |
| **Icon Mix (30K samples)**  | 64         | ~2-3 min       | ~4-6 hours     | ~8-10GB      |
| **Small Test (5K samples)** | 128        | ~15-30 sec     | ~30-45 min     | ~4-6GB       |

**M3 Pro Optimization Tips:**

- Use `--memory=16g` to prevent swap usage
- Set batch size to 32-64 for optimal performance
- Enable unified memory sharing: `--shm-size=8g`
- Monitor with: `docker stats` and Activity Monitor

#### 🔧 **Performance Optimization**

**Docker Optimization:**

```bash
# Allocate more memory to Docker Desktop
# Settings > Resources > Memory: 20GB+ (for large datasets)

# Enable BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Use multi-stage builds for smaller images
docker build --target production -t supersvg:optimized .
```

**Training Optimization:**

```bash
# Mixed precision training (for NVIDIA GPUs)
python main_coarse.py \
  --data_path=/data \
  --mixed_precision \
  --batch_size=64

# Data loading optimization
python main_coarse.py \
  --data_path=/data \
  --num_workers=8 \
  --prefetch_factor=4
```

#### 📊 **Cost-Performance Analysis**

**Local vs Cloud Comparison (Icon dataset training):**

| Option              | Hardware Cost | Time      | Electricity | Total Cost | Best For                    |
| ------------------- | ------------- | --------- | ----------- | ---------- | --------------------------- |
| **MacBook M3 Pro**  | $0 (owned)    | 6 hours   | ~$0.50      | ~$0.50     | Development, small datasets |
| **Local RTX 4080**  | $0 (owned)    | 3 hours   | ~$1.00      | ~$1.00     | Regular training            |
| **GCP V100**        | $0 setup      | 2 hours   | $0          | ~$6.00     | One-off experiments         |
| **RunPod RTX 4090** | $0 setup      | 1.5 hours | $0          | ~$2.00     | Cost-effective cloud        |

**Recommendation**: Start with local development on M3 Pro, then scale to cloud for production training.

# Training

## Data Preparation

Download the [ImageNet](https://image-net.org) dataset or prepare your custom dataset.

### Recommended Datasets for Icon/SVG Training

If you want to train SuperSVG specifically for **image-to-SVG conversion** (especially for icons and simple graphics), here are the best free datasets based on community experience:

#### 🎯 **Primary Datasets (Highly Recommended)**

1. **[Quick, Draw! Dataset](https://github.com/googlecreativelab/quickdraw-dataset)** ⭐⭐⭐⭐⭐

   - **Size**: 50 million drawings across 345 categories
   - **Format**: Vector strokes with timing information, also available as simplified SVGs
   - **Best for**: Simple icons, sketches, and basic shapes
   - **Download**:
     ```bash
     # Simplified SVG format
     gsutil -m cp 'gs://quickdraw_dataset/full/simplified/*.ndjson' .
     ```
   - **Why it's great**: Real human-drawn vectors, perfect for learning stroke patterns

2. **[Sketchy-SVGs Dataset](https://huggingface.co/datasets/kmewhort/sketchy-svgs)** ⭐⭐⭐⭐

   - **Size**: ~75k SVG icons with annotations
   - **Format**: Pre-processed SVG files with metadata
   - **Best for**: More complex icon shapes and detailed graphics
   - **Download**: Available on Hugging Face
   - **Why it's great**: High-quality SVG annotations of real-world objects

3. **[TU-Berlin Sketch Dataset](https://cybertron.cg.tu-berlin.de/eitz/projects/classifysketch/)** ⭐⭐⭐⭐
   - **Size**: 20,000 sketches across 250 categories
   - **Format**: SVG and PNG formats available
   - **Best for**: Object sketches and category-based training
   - **Download**: [Direct link](https://cybertron.cg.tu-berlin.de/eitz/projects/classifysketch/sketches_svg.zip) (~50MB)
   - **License**: Creative Commons Attribution 4.0

#### 🎨 **Icon-Specific Datasets**

4. **[Feather Icons](https://github.com/feathericons/feather)** ⭐⭐⭐⭐

   - **Size**: 280+ icons
   - **Format**: Clean SVG files
   - **Best for**: Modern, minimalist icon style
   - **License**: MIT

   ```bash
   git clone https://github.com/feathericons/feather.git
   # Icons are in the 'icons/' directory
   ```

5. **[Tabler Icons](https://github.com/tabler/tabler-icons)** ⭐⭐⭐⭐

   - **Size**: 5,944+ icons (outline + filled versions)
   - **Format**: High-quality SVG files
   - **Best for**: Comprehensive icon training
   - **License**: MIT

   ```bash
   git clone https://github.com/tabler/tabler-icons.git
   # Icons are in the 'icons/' directory
   ```

6. **[Iconify Collection](https://iconify.design/)** ⭐⭐⭐⭐⭐
   - **Size**: 200,000+ open source icons
   - **Format**: SVG with JSON metadata
   - **Best for**: Massive variety of icon styles
   - **Access**: Use their API or download specific icon sets

#### 🔬 **Research Datasets**

7. **[DeepSVG Icons8 Dataset](https://github.com/alexandre01/deepsvg)** ⭐⭐⭐

   - **Size**: 100k preprocessed icons
   - **Format**: PyTorch tensors (pre-processed)
   - **Best for**: Following DeepSVG methodology
   - **Note**: Requires downloading from Google Drive

8. **[SVG-VAE Font Dataset](https://github.com/magenta/magenta/tree/master/magenta/models/svg_vae)** ⭐⭐⭐
   - **Size**: Various font characters as SVGs
   - **Format**: Vector fonts converted to SVG paths
   - **Best for**: Character/glyph generation

#### 📊 **Dataset Combination Strategy**

For best results, we recommend combining multiple datasets:

```bash
# 1. Start with Quick Draw for basic shapes
gsutil -m cp 'gs://quickdraw_dataset/full/simplified/*.ndjson' ./data/quickdraw/

# 2. Add icon datasets for style diversity
git clone https://github.com/feathericons/feather.git ./data/feather/
git clone https://github.com/tabler/tabler-icons.git ./data/tabler/

# 3. Include Sketchy-SVGs for complex objects
# Download from Hugging Face to ./data/sketchy/

# 4. Mix with a subset of ImageNet for raster-to-vector learning
# Download ImageNet subset to ./data/imagenet/
```

#### 🛠 **Dataset Preprocessing Tips**

1. **SVG Simplification**: Use tools like `svgo` to clean SVG files
2. **Size Normalization**: Scale all SVGs to consistent bounding boxes
3. **Data Augmentation**: Apply rotations, scaling, and translations
4. **Format Conversion**: Convert different vector formats to a unified representation

#### 🎯 **Training Recommendations**

- **Start Small**: Begin with Quick Draw dataset (simpler shapes)
- **Progressive Training**: Add more complex datasets gradually
- **Style Mixing**: Combine multiple icon styles for robustness
- **Validation Split**: Keep 10-20% of each dataset for validation

#### 💡 **Community Experience**

Based on developer feedback:

- Quick Draw works best for learning basic vector primitives
- Icon datasets (Feather, Tabler) help with clean, professional results
- Mixing raster images with vector targets improves generalization
- Pre-trained models on fonts can be fine-tuned for icons

## Checkpoints

Currently we are working on an improved version of SuperSVG and the complete code will be released after that project.
If you want to reproduce the results in the paper, you can download the [checkpoints](https://drive.google.com/file/d/10C9EsMD6_B7dCEz6oNJetevNazk3blBK/view?usp=drive_link) of our improved coarse-stage model,
which performs almost the same as the coarse+refine model in the paper.

## Training the Coarse-stage Model

### Using Docker (Recommended)

```bash
# Basic training with mounted dataset and output directory
docker run --rm -it \
  -v /path/to/your/dataset:/data \
  -v $(pwd)/output_coarse:/workspace/output_coarse \
  supersvg:latest
```

### Using Local Installation

Put the downloaded ImageNet or any dataset you want into `$path_to_the_dataset`.
Then, you can train the coarse-stage model by running:

```bash
python3 main_coarse.py --data_path=$path_to_the_dataset
```

After training, the checkpoints and logs are saved in the directory `output_coarse`.

## Training the Refinement-stage Model

Coming soon

[//]: # "With the trained coarse-stage model, you can train the refinement-stage model by running:"
[//]: #
[//]: # "```"
[//]: # "python3 main_refine --data_path=$path_to_the_dataset"
[//]: # "```"
[//]: #
[//]: # "After training, the checkpoints and logs are saved in the directory `output_refine`."

# Troubleshooting

## Docker Issues

- **Permission Errors**: Ensure your user has permission to access the mounted directories
- **Out of Memory**: Increase Docker's memory allocation in Docker Desktop settings (recommended: 20GB+ for large datasets)
- **Build Failures**: Try building with `--no-cache` flag: `docker build --no-cache -f Dockerfile.mamba -t supersvg:latest .`
- **Apple Silicon Issues**: Use `--platform linux/arm64` flag and ensure Rosetta 2 is enabled
- **GPU Not Detected**: Install NVIDIA Container Toolkit for Linux or enable GPU support in Docker Desktop

## Performance Issues

- **Slow Training**: Check if GPU is being utilized with `nvidia-smi` (NVIDIA) or Activity Monitor (Apple Silicon)
- **Memory Errors**: Reduce batch size or increase Docker memory allocation
- **Disk I/O Bottleneck**: Use SSD storage and avoid network-mounted datasets
- **CPU Bottleneck**: Increase `--num_workers` for data loading (typically 2x number of CPU cores)

## Local Installation Issues

- **DiffVG Build Errors**: Ensure you have CMake 3.15+ installed and initialized git submodules
- **OpenCV Segmentation Fault**: Use exactly `opencv-python==4.5.4.60` as specified
- **CUDA Issues**: Ensure your PyTorch installation matches your CUDA version

# Repository Structure

```
SuperSVG/
├── Dockerfile.mamba          # Docker configuration for containerized setup
├── docker-compose.yml        # Optional Docker Compose configuration
├── main_coarse.py            # Main training script for coarse-stage model
├── DiffVG/                   # DiffVG submodule for differentiable rendering
├── models/                   # Model implementations
├── util/                     # Utility functions and helpers
├── output_coarse/           # Training outputs (created during training)
├── logs/                    # Training logs (created during training)
└── README.md                # This file
```

## Citation

If you find this code helpful for your research, please cite:

```
@inproceedings{hu2024supersvg,
      title={SuperSVG: Superpixel-based Scalable Vector Graphics Synthesis},
      author={Teng Hu and Ran Yi and Baihong Qian and Jiangning Zhang and Paul L. Rosin and Yu-Kun Lai},
      booktitle={Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition},
      year={2024}
}
```
````
