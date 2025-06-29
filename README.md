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

## Option 2: Local Installation

If you prefer to install dependencies locally:

```bash
conda create -n live python=3.7
conda activate live
conda install -y pytorch torchvision -c pytorch
conda install -y numpy scikit-image
conda install -y -c anaconda cmake
conda install -y -c conda-forge ffmpeg
pip install svgwrite svgpathtools cssutils numba torch-tools scikit-fmm easydict visdom
pip install opencv-python==4.5.4.60  # please install this version to avoid segmentation fault.

cd DiffVG
git submodule update --init --recursive
python setup.py install
cd ..
```

# Training

## Data Preparation

Download the [ImageNet](https://image-net.org) dataset or prepare your custom dataset.

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
- **Out of Memory**: Increase Docker's memory allocation in Docker Desktop settings
- **Build Failures**: Try building with `--no-cache` flag: `docker build --no-cache -f Dockerfile.mamba -t supersvg:latest .`

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
