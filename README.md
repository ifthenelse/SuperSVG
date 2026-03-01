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

## 6) Key Concepts: Training vs. Serving, Milestones & Cost

### 6.1 Training as artifact generation, not an API

SuperSVG training produces:

- **Checkpoint files** (model weights saved at regular intervals)
- **Logs** (training metrics, loss curves)
- **Sample SVG outputs** (vectorization results on fixed test inputs)

Training **does not** produce an HTTP API. Serving (inference) is a separate phase: load a checkpoint, run the vectorization pipeline on new inputs at request time, and return SVG results.

### 6.2 Separate compute from state

Best practice architecture:

- **Ephemeral compute** (RunPod pod, EC2 instance, ECS task): Stateless, disposable, pay-per-hour.
- **Persistent storage** (Network Volume, S3/R2): Datasets, checkpoints, outputs, logs. Pay-per-GB-month.
- **Rule**: Treat pod disk as temporary cache only. Do not rely on it for long-term data. Sync artifacts to persistent storage immediately.

Why this matters:

- RunPod stopped pod disks still incur storage costs.
- EC2 EBS snapshots are expensive if kept long-term.
- Relying on pod disk forces you to keep pods running (expensive and wasteful).

### 6.3 Hardware constraints by OS

| OS               | Local training/inference                                               | Control-plane / API dev                                    |
| ---------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------- |
| Mac M3 Pro (ARM) | Slow/unreliable under amd64 emulation; not recommended. Use cloud GPU. | ✅ Excellent; build here. Standard Python/FastAPI/web dev. |
| Linux x86-64     | ✅ Excellent if GPU available (not typical for dev machines).          | ✅ Excellent.                                              |
| Windows x86-64   | ✅ Good via Docker Desktop + WSL2.                                     | ✅ Excellent.                                              |

**Practical split for Mac users**:

- Build and develop the **control-plane** (API, orchestration, validation logic) locally.
- Run all **GPU workloads** (training, inference) on RunPod/cloud.

### 6.4 Milestones: progress gates and success criteria

Use these to track your journey from "does it run" to "production-ready":

#### Milestone 1: Pipeline Valid

- ✅ Training doesn't crash
- ✅ Produces ≥1 checkpoint file
- ✅ Produces ≥1 SVG output (even if simple)
- ✅ Completes without OOM or timeouts

**How to reach**: Run 1 epoch on the test dataset (~5 images) with default hyperparams.

#### Milestone 2: Non-degenerate Output

- ✅ SVG output is not empty/garbage
- ✅ No major glitches or exploding gradients
- ✅ Training curves show reasonable trends
- ✅ Inference runs without errors on sample images

**How to reach**: Quick dataset (quickdraw 100 images) + 5-10 epochs, monitor convergence.

#### Milestone 3: Publishable Stability & Quality

- ✅ Quality plateaus or improves consistently
- ✅ Costs and throughput measured and reproducible
- ✅ Checkpoint versioning + git/S3 tracking
- ✅ Regression tests in place (golden image comparisons)
- ✅ API contract defined and validated

**How to reach**: Full training run (50-100 epochs) + production hardening.

### 6.5 Cost framing with concrete A5000 numbers

**RunPod A5000 on-demand pricing**:

- GPU cost: `~$0.27/h`
- Running pod disk: `~$0.025/h`
- **Total running**: `~$0.295/h`

**Budget scenarios**:

- 10 hours training: **~$3**
- 50 hours training: **~$15**
- 100 hours training: **~$30**

**Cost leak prevention**:

- ❌ Don't leave pods running idle (suspend or terminate after use)
- ❌ Don't keep large pod disks around after termination (expensive storage)
- ✅ Use Network Volumes (cheaper monthly storage)
- ✅ Push artifacts to S3/R2 regularly
- ✅ Automate pod teardown after training completes

### 6.6 Fastest path to Milestone 1 (minimize variables, cost, time)

**On RunPod, from pod boot to first checkpoint in ~15-20 minutes**:

```bash
# 1. SSH into your running pod (from your local machine)
ssh root@<POD_IP> -p <POD_PORT> -i ~/.ssh/id_runpod_ed25519

# 2. On the pod: Set up GitHub SSH auth (one time)
ssh-keygen -t ed25519 -f ~/.ssh/id_github -C "supersvg-pod" -N ""
cat ~/.ssh/id_github.pub
# Copy output, add to https://github.com/settings/keys

# 3. Clone repo and setup (adjust repo URL if public)
git clone git@github.com:ifthenelse/SuperSVG.git
cd SuperSVG
./setup-lambda-labs.sh  # automates Docker build, dependencies

# 4. Download tiny test dataset (if not pre-mounted)
./docker-run.sh download test ./input

# 5. Run 1-epoch smoke training
./docker-run.sh test ./input 16

# 6. Check for artifacts
ls output_coarse/        # SVG outputs
ls checkpoints/          # model checkpoint
ls logs/                 # training logs

# 7. Backup to persistent storage
# Option A: Network Volume
cp -r output_coarse/* /workspace/my_network_volume/

# Option B: S3 (requires AWS credentials on pod)
aws s3 sync output_coarse/ s3://my-bucket/supersvg-outputs/

# 8. Terminate pod to stop charges
# Go to RunPod UI and click "Stop" or "Terminate"
```

**Success = artifacts exist at expected paths.**

### 6.7 On-demand vs in-house decision

| Aspect                     | On-demand (RunPod)                               | In-house GPU                                         |
| -------------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| **Time to first run**      | ~5 min (sign up) + pod deploy                    | Weeks (procurement, setup)                           |
| **Capital**                | $0                                               | $5k-$20k+                                            |
| **Ops overhead**           | Minimal                                          | High (cooling, power, CUDA, drivers)                 |
| **Hourly cost**            | $0.27 (A5000)                                    | ~$0.02 (amortized), but high upfront                 |
| **Total cost Milestone 1** | ~$3-5                                            | $5k+, then cheap after                               |
| **Utilization break-even** | ~$5k / $0.27 ≈ 18,500h of use                    | n/a                                                  |
| **Best for**               | Prototyping, validation, startups, variable load | High utilization, established teams, long-term infra |

**Recommendation**: Use on-demand for Milestones 1-2. Decide in-house only if you'll consistently use GPU many hours/month for years.

---

## 7) Cloud Setup Options (Platforms, Tradeoffs, Costs)

Cost numbers below are indicative and vary by region/availability.

| Platform          | Typical GPU      | Typical Hourly Cost | Pros                      | Cons                      | Best For             |
| ----------------- | ---------------- | ------------------: | ------------------------- | ------------------------- | -------------------- |
| RunPod            | RTX 4090 / A5000 |         ~$0.44-0.69 | Strong price/perf, simple | Marketplace variability   | Most users           |
| Vast.ai           | RTX 4090 / A6000 |         ~$0.30-0.90 | Lowest cost options       | Provider variability      | Budget experiments   |
| AWS EC2 Spot      | A10G / V100      |         ~$0.36-1.20 | Reliability, ecosystem    | More setup complexity     | Production workloads |
| Lambda Labs       | A100 / A6000     |         ~$0.80-1.99 | Good GPU options          | Frequent capacity limits  | If available         |
| GCP (preemptible) | V100 / A100      |            variable | Strong infra              | Pricing/config complexity | GCP-native teams     |

### Training budget examples (estimating Milestone 1-3 iterations)

- Icon dataset runs (2-3h): roughly ~$1-$4 depending platform/GPU.
- Quick Draw-scale runs (10-15h): roughly ~$4-$20 depending platform/GPU.
- Large/full runs (50-70h): roughly ~$20-$90 depending platform/GPU.

### Recommendation order

1. RunPod RTX 4090
2. Vast.ai RTX 4090
3. AWS EC2 Spot (A10G/V100)
4. Lambda Labs when capacity exists

---

## 8) Install & Run on Cloud Infrastructure

## 8.1 RunPod / Vast.ai / Lambda-style flow

### Step 1: Connect to your pod

**Option A (Easiest): Use TCP port forwarding**

```bash
# From your local machine
ssh root@<POD_PUBLIC_IP> -p <POD_PORT> -i ~/.ssh/id_runpod_ed25519
```

Replace `<POD_PUBLIC_IP>` and `<POD_PORT>` with values from RunPod pod console.

**Troubleshooting SSH:**

- If public key auth fails, use password auth instead:

  ```bash
  ssh root@<POD_PUBLIC_IP> -p <POD_PORT>
  ```

  (Enter root password from RunPod pod console)

- If you have VPN enabled, **disable it first** — VPN blocks SSH port forwarding
- If port is unreachable, regenerate keypair from RunPod console: **SSH Keypair** → **Regenerate** → download new private key

**Option B: Use RunPod SSH gateway**

```bash
ssh <POD_ID>-<USER_ID>@ssh.runpod.io -i ~/.ssh/id_runpod_ed25519
```

(Find exact command in RunPod pod console under "SSH Connection")

### Step 2: Set up GitHub SSH authentication

If you're cloning a **private repo**, generate SSH credentials on the pod and add to GitHub:

```bash
# On the pod
ssh-keygen -t ed25519 -f ~/.ssh/id_github -C "supersvg-pod" -N ""
cat ~/.ssh/id_github.pub
```

Then:

1. Copy the output (public key)
2. Go to https://github.com/settings/keys
3. Click "New SSH key"
4. Paste the public key, name it "SuperSVG Pod", and save

### Step 3: Clone and build

```bash
# On pod
git clone git@github.com:ifthenelse/SuperSVG.git
cd SuperSVG
./setup-lambda-labs.sh
```

The `setup-lambda-labs.sh` script automates:

- system packages
- NVIDIA/container runtime checks
- Docker setup
- image build
- launcher scripts (`~/train_supersvg.sh`, `~/monitor_training.sh`)

## 8.2 AWS EC2 flow

### Prerequisites (quota approval needed)

Before launching GPU instances, you need sufficient vCPU quota:

1. **Check your quota:**

   ```bash
   aws service-quotas get-service-quota \
     --service-code ec2 \
     --quota-code L-DB2E81BA  # Running On-Demand G and VT instances
   ```

2. **Request increase if needed:**
   - Via AWS Console: [Service Quotas](https://console.aws.amazon.com/servicequotas/home) → EC2 → "Running On-Demand G and VT instances"
   - Request at least 32 vCPUs (g5.2xlarge needs 8)
   - Approval typically takes 1-2 business days

   Or via CLI:

   ```bash
   aws service-quotas request-service-quota-increase \
     --service-code ec2 \
     --quota-code L-DB2E81BA \
     --desired-value 32
   ```

### Launch instance from local machine

Use the automated launcher script (recommended):

```bash
# On-demand instance (reliable, ~$1.21/hour)
./launch-aws-ec2.sh

# Spot instance (70% cheaper, ~$0.36-0.50/hour, can be interrupted)
./launch-aws-ec2.sh --spot

# Different instance type
./launch-aws-ec2.sh --instance-type g5.xlarge
```

The script automatically:

- Finds the correct Ubuntu 22.04 AMI for your region
- Creates SSH key pair (`supersvg-key.pem`) if needed
- Sets up security group for SSH access
- Launches the instance
- Provides SSH connection details

### Setup on the EC2 instance

Once the instance is running, SSH in and run the setup script:

```bash
# SSH into instance (command provided by launch script)
ssh -i supersvg-key.pem ubuntu@<PUBLIC_IP>

# Run setup script on the instance
curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh
chmod +x setup-aws-ec2.sh
./setup-aws-ec2.sh
```

The setup script (runs on the EC2 instance) automates:

- NVIDIA driver installation
- Docker + NVIDIA container runtime setup
- Repository clone
- Image build
- Launcher scripts (`~/train_supersvg.sh`, `~/monitor_training.sh`)
- S3 sync helpers
- Spot-instance handling helpers
- Cost estimation scripts

## 8.3 Dataset transfer to cloud

### Option A: from local machine

```bash
scp -r /local/path/to/dataset ubuntu@<cloud-ip>:~/supersvg_data/
```

### Option B: pull directly on cloud host

```bash
cd ~/supersvg_data
# Download or copy from object storage
```

## 8.4 Start training in cloud

```bash
# generated by setup scripts
~/train_supersvg.sh

# optional custom params
BATCH_SIZE=64 EPOCHS=200 ~/train_supersvg.sh

# monitor (in another SSH session)
~/monitor_training.sh
```

## 8.5 Terminate instance when done

**Important:** Remember to terminate instances to avoid ongoing charges.

```bash
# From your local machine
aws ec2 terminate-instances --instance-ids i-xxxxxxxxxxxxx

# Or use the instance ID saved by launch script
cat supersvg-instance.txt  # shows terminate command
```

Check termination status:

```bash
aws ec2 describe-instances --instance-ids i-xxxxxxxxxxxxx \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

## 8.6 RunPod storage strategy (Do you need a Network Volume?)

Short answer: **recommended, but not strictly required**.

Choose based on desired durability:

- **No Network Volume (fast start, lowest complexity):**
  - Use container/volume disk only
  - Data is lost when pod is terminated
  - Best for short experiments where outputs are pushed to external storage immediately
- **With Network Volume (recommended for most users):**
  - Data persists across pod termination/recreation
  - Better for iterative training, checkpoint recovery, and dataset reuse
  - Network Volume is locked to a RunPod region/data center

Recommended baseline for SuperSVG:

- GPU: A5000 on-demand for first stable runs
- Container disk: 20-30 GB
- Network Volume: 100-150 GB
- Jupyter: off unless needed for exploratory analysis

RunPod region matching rule:

- The pod and Network Volume must be in the same compatible data center/region.
- If you see "Data center does not match filters", adjust GPU/data-center filters or create the volume in the selected pod region.

Durability best practice:

- Keep active training state on Network Volume
- Periodically export checkpoints/results to object storage (for example AWS S3) as system-of-record backups

---

## 9) Expose SuperSVG as a Deployable Service (Interface Agreement + APIs)

The repository is training-oriented by default. For production serving, use a thin API service around the model pipeline.

## 9.1 Service model

Use asynchronous job-based inference:

1. Client submits image + config
2. Service enqueues job
3. Worker runs vectorization pipeline
4. Client polls or receives callback
5. Client downloads SVG/result artifacts

## 9.2 API contract (proposed, implementation target)

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

## 9.3 Error model

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

## 9.4 Non-functional API requirements

- Idempotency header on submit: `Idempotency-Key`
- Correlation ID header: `X-Request-Id`
- Max upload size (example): 25 MB
- Job retention (example): 7 days
- SLA target (example): P95 status API < 200 ms

## 9.5 Deployment architecture (reference)

- API gateway / ingress
- FastAPI (or equivalent) control plane
- Queue (Redis/RQ, RabbitMQ, or cloud queue)
- Worker pool with GPU scheduling
- Object storage for artifacts
- PostgreSQL for job metadata
- Observability: logs + metrics + tracing

## 9.6 Security baseline

- Token-based auth or private network only
- Signed URLs for result download
- Input validation + file type checks
- Per-tenant quotas and rate limits
- Secret management via cloud secret manager

## 9.7 Versioning policy

- URI-based versioning (`/api/v1`)
- Backward-compatible additions only within major version
- Breaking changes in `/api/v2`

## 9.8 AWS serverless HTTP deployment pattern (recommended)

For production APIs, use a **serverless control plane** and a **GPU worker plane**:

- **Control plane (serverless):**
  - API Gateway + Lambda for HTTP endpoints and orchestration
  - SQS for async job queueing
  - DynamoDB (or PostgreSQL) for job status/metadata
  - S3 for input/output artifacts
- **Worker plane (GPU):**
  - ECS on EC2 GPU instances, EKS GPU nodes, or SageMaker async endpoints
  - Pull jobs from queue, run inference, write artifacts/metadata back

Important constraint:

- AWS Lambda is excellent for API orchestration and lightweight preprocessing.
- Lambda is **not** suitable for heavy GPU inference/training workloads.

Reference request flow:

1. `POST /api/v1/vectorize/jobs` uploads input to S3 and enqueues job in SQS
2. GPU worker consumes job, runs vectorization, writes `output.svg` to S3
3. Worker updates job state in DynamoDB/PostgreSQL
4. `GET /api/v1/vectorize/jobs/{job_id}` returns progress/status
5. `GET /api/v1/vectorize/jobs/{job_id}/result` returns signed S3 URL

## 9.9 Practical E2E migration path (RunPod → AWS service)

Phase 1: model development and training

- Train/tune on RunPod (A5000) with persistent storage
- Save checkpoints and export final artifacts to S3

Phase 2: inference packaging and local validation

- Build an inference container with a deterministic `/predict` contract
- Validate locally with fixed test inputs and expected outputs

Phase 3: production API enablement

- Implement async API contract from this section
- Deploy API Gateway + Lambda + SQS + DynamoDB + S3
- Deploy GPU worker service (ECS/EKS/SageMaker)

Phase 4: hardening and operations

- Add authentication, rate limiting, and structured logging
- Add metrics/alerts, retries, DLQ, and idempotency controls
- Define SLOs, run load tests, and establish rollback procedures

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

- `docker-run.sh`: local Docker operations (build, train, download datasets)
- `download_datasets.sh`: dataset preparation automation
- `setup_dataset_env.sh`: host Python environment for datasets
- `launch-aws-ec2.sh`: launch EC2 instance from local machine (macOS/Linux)
- `setup-lambda-labs.sh`: setup script for RunPod/Vast.ai/Lambda Labs (runs on cloud VM)
- `setup-aws-ec2.sh`: setup script for AWS EC2 (runs on EC2 instance)
- `choose-platform.sh`: interactive cloud platform selector

### C) Cloud-first recommendation

For Apple Silicon users: use local environment for preparation, and run full training/inference workloads on cloud AMD64 GPU infrastructure.
