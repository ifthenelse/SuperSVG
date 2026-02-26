#!/bin/bash
# SuperSVG Docker Helper Script
# Usage: ./docker-run.sh [command] [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker Desktop."
        exit 1
    fi
    print_success "Docker installed"
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose not found."
        exit 1
    fi
    print_success "Docker Compose installed"
    
    # Check if Docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker daemon not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker daemon running"
}

# Verify data directory
verify_data() {
    DATA_PATH="${1:-.}/input"
    
    if [ ! -d "$DATA_PATH" ]; then
        print_warning "Data directory '$DATA_PATH' not found"
        print_warning "Creating empty data directory..."
        mkdir -p "$DATA_PATH"
        print_warning "Please add image files to: $DATA_PATH"
        print_warning "Directory structure:"
        echo "  $DATA_PATH/"
        echo "    ├── class_1/"
        echo "    │   ├── image1.jpg"
        echo "    │   └── image2.jpg"
        echo "    └── class_2/"
        echo "        └── image3.jpg"
        return 1
    fi
    
    IMAGE_COUNT=$(find "$DATA_PATH" -type f \( -name "*.jpg" -o -name "*.png" \) | wc -l)
    if [ "$IMAGE_COUNT" -eq 0 ]; then
        print_warning "No images found in $DATA_PATH"
        return 1
    fi
    
    print_success "Found $IMAGE_COUNT images in $DATA_PATH"
    return 0
}

# Build Docker image
cmd_build() {
    print_header "Building Docker Image"
    docker-compose build
    print_success "Docker image built successfully"
}

# Start interactive shell
cmd_interactive() {
    local data_path="${1:-.}/input"
    
    print_header "Starting Interactive Shell"
    print_warning "Make sure data is in: $data_path"
    
    if ! verify_data "$data_path"; then
        print_warning "Continuing without data verification..."
    fi
    
    echo "Type 'exit' to stop the container"
    echo ""
    
    DATA_PATH="$data_path" docker-compose run --rm supersvg bash
}

# Run test training
cmd_test() {
    local data_path="${1:-.}/input"
    local batch_size="${2:-16}"
    
    print_header "Running Test Training (1 epoch)"
    
    if ! verify_data "$data_path"; then
        print_error "No data found. Please add images to $data_path"
        exit 1
    fi
    
    DATA_PATH="$data_path" docker-compose run --rm supersvg \
        micromamba run -n live python main_coarse.py \
        --data_path=/data \
        --num_epochs=1 \
        --batch_size="$batch_size"
    
    print_success "Test training completed"
}

# Run full training
cmd_train() {
    local data_path="${1:-.}/input"
    local num_epochs="${2:-100}"
    local batch_size="${3:-32}"
    local learning_rate="${4:-0.001}"
    
    print_header "Starting Training"
    echo "Settings:"
    echo "  Data path: $data_path"
    echo "  Epochs: $num_epochs"
    echo "  Batch size: $batch_size"
    echo "  Learning rate: $learning_rate"
    echo ""
    
    if ! verify_data "$data_path"; then
        print_error "No data found. Please add images to $data_path"
        exit 1
    fi
    
    mkdir -p output_coarse logs checkpoints
    
    DATA_PATH="$data_path" docker-compose run --rm supersvg \
        micromamba run -n live python main_coarse.py \
        --data_path=/data \
        --num_epochs="$num_epochs" \
        --batch_size="$batch_size" \
        --lr="$learning_rate"
    
    print_success "Training completed"
    print_warning "Results saved to: output_coarse/"
}

# Run in detached mode
cmd_daemon() {
    local data_path="${1:-.}/input"
    
    print_header "Starting Training (Background Mode)"
    
    if ! verify_data "$data_path"; then
        print_error "No data found. Please add images to $data_path"
        exit 1
    fi
    
    mkdir -p output_coarse logs checkpoints
    
    DATA_PATH="$data_path" docker-compose up -d
    
    print_success "Container started in background"
    echo "Monitor with: docker-compose logs -f"
    echo "Stop with: docker-compose down"
}

# Download datasets
cmd_download() {
    local dataset_type="${1:-all}"
    
    print_header "Downloading Datasets"
    
    if [ ! -f "${PROJECT_ROOT}/download_datasets.sh" ]; then
        print_error "download_datasets.sh not found"
        exit 1
    fi
    
    bash "${PROJECT_ROOT}/download_datasets.sh" "$dataset_type"
}

# View logs
cmd_logs() {
    docker-compose logs -f
}

# Stop container
cmd_stop() {
    print_header "Stopping Container"
    docker-compose down
    print_success "Container stopped"
}

# Clean up
cmd_clean() {
    print_header "Cleaning Up"
    
    docker-compose down
    echo "Remove Docker image? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
        docker rmi supersvg:latest
        print_success "Docker image removed"
    fi
}

# Show help
cmd_help() {
    cat << 'EOF'
SuperSVG Docker Helper Script

Usage: ./docker-run.sh [command] [options]

Commands:
  build               Build the Docker image
  download [type]     Download datasets (test|quickdraw|icons|all)
  interactive         Start interactive bash shell
  test [data] [bs]    Run quick test training (1 epoch)
  train [data] [e] [bs] [lr]  Run full training
  daemon [data]       Run training in background
  logs                View training logs
  stop                Stop the container
  clean               Clean up containers and images
  check               Check prerequisites
  help                Show this help message

Examples:
  ./docker-run.sh build
  ./docker-run.sh download test
  ./docker-run.sh download quickdraw
  ./docker-run.sh test input 32
  ./docker-run.sh train input 100 32 0.001
  ./docker-run.sh daemon input

Arguments:
  data    Data directory path (default: ./input)
  e       Number of epochs (default: 100)
  bs      Batch size (default: 32)
  lr      Learning rate (default: 0.001)
  type    Dataset type: test, quickdraw, icons, all (default: all)

Environment Variables:
  DATA_PATH           Override data directory path

EOF
}

# Main script logic
main() {
    local command="${1:-help}"
    
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    case "$command" in
        build)
            check_prerequisites
            cmd_build
            ;;
        download)
            cmd_download "$2"
            ;;
        interactive)
            check_prerequisites
            cmd_interactive "$2"
            ;;
        test)
            check_prerequisites
            cmd_test "$2" "$3"
            ;;
        train)
            check_prerequisites
            cmd_train "$2" "$3" "$4" "$5"
            ;;
        daemon)
            check_prerequisites
            cmd_daemon "$2"
            ;;
        logs)
            cmd_logs
            ;;
        stop)
            cmd_stop
            ;;
        clean)
            cmd_clean
            ;;
        check)
            check_prerequisites
            print_success "All prerequisites met!"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            print_error "Unknown command: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
