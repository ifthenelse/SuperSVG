# SuperSVG

SuperSVG is a CVPR 2024 project for superpixel-based SVG synthesis. This repository includes model code, DiffVG dependencies, Docker-based runtime, dataset automation scripts, and cloud setup helpers.

Paper links:

- CVPR Paper: https://openaccess.thecvf.com/content/CVPR2024/papers/Hu_SuperSVG_Superpixel-based_Scalable_Vector_Graphics_Synthesis_CVPR_2024_paper.pdf
- Supplementary: https://openaccess.thecvf.com/content/CVPR2024/supplemental/Hu_SuperSVG_Superpixel-based_Scalable_CVPR_2024_supplemental.pdf

---

## Documentation Policy

- This `README.md` is the single source of truth for setup, runtime, dataset, and cloud operations.
- Operational changes (commands, prerequisites, paths, platform notes, costs, API contract updates) must be applied here first.
- Supporting docs (`QUICK_START.md`, `DOCKER_SETUP_GUIDE.md`, `DOCKER_SOLUTION.md`, `DATASETS.md`, `EXTERNAL_STORAGE.md`, `CLOUD_SETUP_README.md`) remain redirect stubs and should not contain duplicated procedures.
- If behavior changes in scripts (`docker-run.sh`, `download_datasets.sh`, cloud setup scripts), update this README in the same change.

---

## 1) Project Overview

### What this repository provides

- Docker-first environment for reproducible training (`Dockerfile.mamba`, `docker-compose.yml`)
- Helper CLI for common operations (`docker-run.sh`)
- Automated dataset preparation (`download_datasets.sh`, `setup_dataset_env.sh`)
- Local-to-cloud transition support (`setup-lambda-labs.sh`, `setup-aws-ec2.sh`, `choose-platform.sh`)

### Typical workflow

1. Prepare environment
2. Download/prepare dataset
3. Build Docker image
4. Run test training
5. Run full training (usually on cloud GPU)
6. (Optional) expose as service using the API contract in section 8

---

## 2) Hardware

### 2.1 Minimum requirements

#### Local development (sanity checks only)

- CPU: 4+ cores
- RAM: 16 GB
- Storage: 30+ GB free (50+ GB recommended)
- Docker Desktop (or Docker Engine + Compose)
- Python 3.9+ on host for dataset preparation

#### Cloud training minimum

- GPU: 16+ GB VRAM (A10G, RTX 3080/3090 class or better)
- vCPU: 8+
- RAM: 32+ GB
- Storage: 100+ GB SSD/NVMe

### 2.2 Ideal requirements

#### Local

- CPU: 8+ cores
- RAM: 32+ GB
- Storage: 100+ GB SSD
- External dataset drive optional

#### Cloud (recommended)

- GPU: RTX 4090 (24 GB) or better
- vCPU: 16+
- RAM: 64+ GB
- Storage: 200+ GB NVMe

### Important architecture note

- `docker-compose.yml` is pinned to `platform: linux/amd64` to match cloud execution targets.
- On Apple Silicon, AMD64 emulation may be slow or unreliable for runtime binaries. Use local mostly for setup checks; use cloud for actual training.

---

## 3) Docker Solution (Canonical Runtime)

### Files

- `Dockerfile.mamba`: builds runtime with micromamba + Python env + dependencies
- `docker-compose.yml`: default service definition and mounts
- `docker-run.sh`: high-level wrapper for build/download/test/train/etc.

### Docker volume contract

Container expects:

- `/data` -> input dataset root
- `/workspace/output_coarse` -> outputs
- `/workspace/logs` -> logs
- `/workspace/checkpoints` -> checkpoints

### Core commands

```bash
# build image
./docker-run.sh build

# interactive shell
./docker-run.sh interactive ./input

# quick test (1 epoch)
./docker-run.sh test ./input 16

# full train
./docker-run.sh train ./input 100 32 0.001

# background mode
./docker-run.sh daemon ./input
./docker-run.sh logs
./docker-run.sh stop
```

### Data path override

You can bind an external directory by passing an explicit path:

```bash
./docker-run.sh train /absolute/path/to/dataset 100 32 0.001
```

Or with env var:

```bash
DATA_PATH=/absolute/path/to/dataset ./docker-run.sh train ./input 100 32 0.001
```

---

## 4) Datasets

This repo includes automated dataset preparation.

### Supported dataset options

- `test`: small synthetic smoke-test dataset (~5 MB)
- `quickdraw`: 25 categories, up to ~500 PNG images/category (from Quick Draw numpy bitmap source)
- `icons`: Tabler Icons clone + SVG→PNG conversion
- `all`: runs all three

### Setup dataset Python environment

```bash
./setup_dataset_env.sh
```

Installs host-side dependencies in `.venv-datasets` (`numpy`, `pillow`) used by dataset scripts.

### Download commands

```bash
# default path
./docker-run.sh download test
./docker-run.sh download quickdraw
./docker-run.sh download icons
./docker-run.sh download all

# explicit destination path
./docker-run.sh download /absolute/path/to/datasets quickdraw
```

### Dataset directory layout (expected)

```text
<dataset-root>/
  test/
    test_class/
      test_000.jpg ...
  quickdraw/
    airplane/
      000000.png ...
    ...
  tabler_icons/
    png_224/
      <category>/
        *.png
```

### Notes

- Quick Draw source URL used by script: Google Cloud Storage numpy bitmap dataset.
- Icons conversion relies on ImageMagick `convert` when available.
- Re-running download commands is incremental for already prepared parts.

---

## 5) Local Installation & Run (Windows / macOS / Linux)

## 5.1 Prerequisites by OS

### Windows 11/10

- Docker Desktop (WSL2 backend enabled)
- Git for Windows
- Python 3.9+ (for dataset setup scripts)
- Recommended shell: PowerShell or Git Bash

### macOS (Intel/Apple Silicon)

- Docker Desktop
- Python 3.9+
- For Apple Silicon: expect AMD64 emulation limitations (cloud-first training recommended)

### Linux (Ubuntu 22.04+ recommended)

- Docker Engine + Docker Compose plugin
- Python 3.9+
- `git`, `curl`

## 5.2 Linear local setup process

```bash
# 1) clone
git clone https://github.com/sjtuplayer/SuperSVG.git
cd SuperSVG

# 2) host dataset env (one time)
./setup_dataset_env.sh

# 3) download small test data
./docker-run.sh download test

# 4) build docker image
./docker-run.sh build

# 5) run smoke test training
./docker-run.sh test ./input 16
```

## 5.3 If using external storage

### macOS example

```bash
./docker-run.sh list-drives
./docker-run.sh download /Volumes/MyDrive/supersvg_data quickdraw
./docker-run.sh train /Volumes/MyDrive/supersvg_data 100 32 0.001
```

### Windows example

Use absolute Windows path in Docker Desktop shared drives context.

```powershell
./docker-run.sh download "D:/supersvg_data" quickdraw
./docker-run.sh train "D:/supersvg_data" 100 32 0.001
```

### Linux example

```bash
./docker-run.sh download /mnt/data/supersvg quickdraw
./docker-run.sh train /mnt/data/supersvg 100 32 0.001
```

## 5.4 Local troubleshooting quick list

- `cannot execute binary file` on Apple Silicon with AMD64 image: expected in some cases; use cloud runtime.
- No images found: verify path and ensure dataset root contains image files.
- Docker daemon unavailable: start Docker Desktop / service.

---

## 6) Cloud Setup Options (Platforms, Tradeoffs, Costs)

Cost numbers below are indicative and vary by region/availability.

| Platform          | Typical GPU      | Typical Hourly Cost | Pros                      | Cons                      | Best For             |
| ----------------- | ---------------- | ------------------: | ------------------------- | ------------------------- | -------------------- |
| RunPod            | RTX 4090 / A5000 |         ~$0.44-0.69 | Strong price/perf, simple | Marketplace variability   | Most users           |
| Vast.ai           | RTX 4090 / A6000 |         ~$0.30-0.90 | Lowest cost options       | Provider variability      | Budget experiments   |
| AWS EC2 Spot      | A10G / V100      |         ~$0.36-1.20 | Reliability, ecosystem    | More setup complexity     | Production workloads |
| Lambda Labs       | A100 / A6000     |         ~$0.80-1.99 | Good GPU options          | Frequent capacity limits  | If available         |
| GCP (preemptible) | V100 / A100      |            variable | Strong infra              | Pricing/config complexity | GCP-native teams     |

### Training budget examples

- Icon dataset runs (2-3h): roughly ~$1-$4 depending platform/GPU.
- Quick Draw-scale runs (10-15h): roughly ~$4-$20 depending platform/GPU.
- Large/full runs (50-70h): roughly ~$20-$90 depending platform/GPU.

### Recommendation order

1. RunPod RTX 4090
2. Vast.ai RTX 4090
3. AWS EC2 Spot (A10G/V100)
4. Lambda Labs when capacity exists

---

## 7) Install & Run on Cloud Infrastructure

## 7.1 RunPod / Vast.ai / Lambda-style flow

```bash
# On cloud VM/pod
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh
chmod +x setup-lambda-labs.sh
./setup-lambda-labs.sh
```

This script automates:

- system packages
- NVIDIA/container runtime checks
- Docker setup
- repo clone
- image build
- launcher scripts (`~/train_supersvg.sh`, `~/monitor_training.sh`)

## 7.2 AWS EC2 flow

```bash
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh
chmod +x setup-aws-ec2.sh
./setup-aws-ec2.sh
```

AWS script additionally supports:

- S3 sync helpers
- spot-instance handling helpers
- monitoring/cost estimation scripts

## 7.3 Dataset transfer to cloud

### Option A: from local machine

```bash
scp -r /local/path/to/dataset ubuntu@<cloud-ip>:~/supersvg_data/
```

### Option B: pull directly on cloud host

```bash
cd ~/supersvg_data
# Download or copy from object storage
```

## 7.4 Start training in cloud

```bash
# generated by setup scripts
~/train_supersvg.sh

# optional custom params
BATCH_SIZE=64 EPOCHS=200 ~/train_supersvg.sh

# monitor
~/monitor_training.sh
```

---

## 8) Expose SuperSVG as a Deployable Service (Interface Agreement + APIs)

The repository is training-oriented by default. For production serving, use a thin API service around the model pipeline.

## 8.1 Service model

Use asynchronous job-based inference:

1. Client submits image + config
2. Service enqueues job
3. Worker runs vectorization pipeline
4. Client polls or receives callback
5. Client downloads SVG/result artifacts

## 8.2 API contract (proposed, implementation target)

### Base

- Base URL: `/api/v1`
- Auth: `Authorization: Bearer <token>` (or internal mTLS)
- Content type: `application/json` (upload endpoint uses `multipart/form-data`)

### Endpoints

#### Health

- `GET /api/v1/health`
- Response:

```json
{ "status": "ok", "version": "1.0.0" }
```

#### Submit job

- `POST /api/v1/vectorize/jobs`
- Request (multipart):
  - `image` (required): jpg/png
  - `config` (optional JSON string)
- Example config:

```json
{
  "max_paths": 256,
  "num_iterations": 300,
  "output_format": "svg",
  "priority": "normal",
  "callback_url": "https://client.example/webhook"
}
```

- Response `202 Accepted`:

```json
{
  "job_id": "job_01J...",
  "status": "queued",
  "created_at": "2026-02-28T12:00:00Z"
}
```

#### Get job status

- `GET /api/v1/vectorize/jobs/{job_id}`
- Response:

```json
{
  "job_id": "job_01J...",
  "status": "running",
  "progress": 42,
  "created_at": "2026-02-28T12:00:00Z",
  "started_at": "2026-02-28T12:00:15Z",
  "finished_at": null,
  "error": null
}
```

#### Get job result

- `GET /api/v1/vectorize/jobs/{job_id}/result`
- Response when complete:

```json
{
  "job_id": "job_01J...",
  "status": "completed",
  "result": {
    "svg_url": "https://storage.example/results/job_01J/output.svg",
    "preview_png_url": "https://storage.example/results/job_01J/preview.png",
    "metrics": {
      "num_paths": 187,
      "duration_sec": 48.2
    }
  }
}
```

#### Cancel job

- `POST /api/v1/vectorize/jobs/{job_id}/cancel`
- Response:

```json
{ "job_id": "job_01J...", "status": "cancelling" }
```

## 8.3 Error model

Standard error payload:

```json
{
  "error": {
    "code": "INVALID_ARGUMENT",
    "message": "output_format must be one of: svg",
    "details": {}
  }
}
```

Suggested status mapping:

- `400` invalid request
- `401/403` auth/permission
- `404` job not found
- `409` invalid state transition
- `422` unsupported media/config
- `429` rate limit
- `500` internal
- `503` capacity unavailable

## 8.4 Non-functional API requirements

- Idempotency header on submit: `Idempotency-Key`
- Correlation ID header: `X-Request-Id`
- Max upload size (example): 25 MB
- Job retention (example): 7 days
- SLA target (example): P95 status API < 200 ms

## 8.5 Deployment architecture (reference)

- API gateway / ingress
- FastAPI (or equivalent) control plane
- Queue (Redis/RQ, RabbitMQ, or cloud queue)
- Worker pool with GPU scheduling
- Object storage for artifacts
- PostgreSQL for job metadata
- Observability: logs + metrics + tracing

## 8.6 Security baseline

- Token-based auth or private network only
- Signed URLs for result download
- Input validation + file type checks
- Per-tenant quotas and rate limits
- Secret management via cloud secret manager

## 8.7 Versioning policy

- URI-based versioning (`/api/v1`)
- Backward-compatible additions only within major version
- Breaking changes in `/api/v2`

---

## Appendices

### A) Most-used commands

```bash
./setup_dataset_env.sh
./docker-run.sh download test
./docker-run.sh build
./docker-run.sh test ./input 16
./docker-run.sh train ./input 100 32 0.001
```

### B) Key repository scripts

- `docker-run.sh`
- `download_datasets.sh`
- `setup_dataset_env.sh`
- `setup-lambda-labs.sh`
- `setup-aws-ec2.sh`
- `choose-platform.sh`

### C) Cloud-first recommendation

For Apple Silicon users: use local environment for preparation, and run full training/inference workloads on cloud AMD64 GPU infrastructure.
