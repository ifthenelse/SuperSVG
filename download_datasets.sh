#!/bin/bash
# SuperSVG Dataset Download Script
# Downloads and prepares datasets for training

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
DATA_DIR="${PROJECT_ROOT}/input"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Create data directory structure
setup_directories() {
    mkdir -p "${DATA_DIR}"
    print_success "Created data directory: ${DATA_DIR}"
}

# Download Quick Draw dataset (PNG rasterized version)
download_quickdraw() {
    print_header "Downloading Quick Draw Dataset"
    
    QUICKDRAW_DIR="${DATA_DIR}/quickdraw"
    mkdir -p "${QUICKDRAW_DIR}"
    
    # Quick Draw categories to download
    CATEGORIES=(
        "airplane" "apple" "banana" "basketball" "beard"
        "car" "cat" "circle" "cloud" "diamond"
        "dog" "eye" "flower" "heart" "house"
        "lightning" "moon" "mountain" "pizza" "star"
        "sun" "tree" "triangle" "umbrella" "zigzag"
    )
    
    echo "Downloading ${#CATEGORIES[@]} Quick Draw categories..."
    echo "Total size: ~1.5GB"
    echo ""
    
    DOWNLOADED=0
    FAILED=0
    
    for category in "${CATEGORIES[@]}"; do
        CATEGORY_FOLDER="${QUICKDRAW_DIR}/${category}"
        
        # Skip if already exists
        if [ -d "${CATEGORY_FOLDER}" ] && [ "$(ls -A "${CATEGORY_FOLDER}")" ]; then
            print_info "Already downloaded: $category"
            ((DOWNLOADED++))
            continue
        fi
        
        mkdir -p "${CATEGORY_FOLDER}"
        
        # Download from Quick Draw full dataset (PNG format)
        # These are pre-rendered PNG files
        URL="https://quickdraw.withgoogle.com/data/full/${category}.ndjson"
        TEMP_FILE="/tmp/${category}.ndjson"
        
        echo -n "Downloading $category... "
        
        if curl -f -s -L -o "${TEMP_FILE}" "${URL}" 2>/dev/null; then
            # Convert NDJSON to PNG images
            python3 << PYTHON_SCRIPT
import json
import base64
import os
from pathlib import Path

ndjson_file = "${TEMP_FILE}"
output_folder = "${CATEGORY_FOLDER}"
max_images = 500  # Limit images per category to manage size

images_saved = 0
with open(ndjson_file, 'r') as f:
    for idx, line in enumerate(f):
        if images_saved >= max_images:
            break
        try:
            obj = json.loads(line)
            if 'image' in obj:
                image_data = base64.b64decode(obj['image'])
                filename = os.path.join(output_folder, f"{idx:06d}.png")
                with open(filename, 'wb') as img_file:
                    img_file.write(image_data)
                images_saved += 1
        except:
            pass

print(images_saved, end='')
PYTHON_SCRIPT
            
            rm -f "${TEMP_FILE}"
            print_success "$category ($(ls ${CATEGORY_FOLDER} | wc -l) images)"
            ((DOWNLOADED++))
        else
            print_warning "Failed to download $category"
            ((FAILED++))
        fi
    done
    
    echo ""
    print_success "Downloaded $DOWNLOADED categories (${FAILED} failed)"
}

# Download Tabler Icons (open source, small, good for testing)
download_tabler_icons() {
    print_header "Downloading Tabler Icons Dataset"
    
    ICONS_DIR="${DATA_DIR}/tabler_icons"
    mkdir -p "${ICONS_DIR}"
    
    echo "Tabler Icons: ~4,500 free icons"
    echo "Size: ~500MB"
    echo ""
    
    # Clone tabler icons repo (focused on SVG files)
    if [ -d "${ICONS_DIR}/.git" ]; then
        print_info "Updating existing Tabler Icons repository..."
        cd "${ICONS_DIR}"
        git pull
        cd "${PROJECT_ROOT}"
    else
        print_info "Cloning Tabler Icons repository..."
        git clone --depth 1 https://github.com/tabler/tabler-icons.git "${ICONS_DIR}" 2>&1 | tail -3
    fi
    
    # Convert SVGs to PNGs (creates subdirectories by icon family)
    print_info "Converting SVGs to PNGs (this may take a few minutes)..."
    
    python3 << 'PYTHON_SCRIPT'
import os
import subprocess
from pathlib import Path
from collections import defaultdict

icons_dir = os.path.expanduser("${DATA_DIR}/tabler_icons")
svg_dir = os.path.join(icons_dir, "icons")
png_output = os.path.join(icons_dir, "png_224")

if not os.path.exists(svg_dir):
    print("SVG directory not found")
    exit(1)

# Create category directories by icon group
categories = defaultdict(list)
for svg_file in Path(svg_dir).glob("*.svg"):
    # Group by first part of name (e.g., "alert" for "alert-circle")
    parts = svg_file.stem.split("-")
    category = parts[0] if parts else "misc"
    categories[category].append(svg_file)

# Convert and organize by category
converted = 0
for category, svg_files in sorted(categories.items()):
    category_dir = os.path.join(png_output, category)
    os.makedirs(category_dir, exist_ok=True)
    
    for svg_file in svg_files[:100]:  # Limit 100 per category for space
        png_file = os.path.join(category_dir, f"{svg_file.stem}.png")
        if not os.path.exists(png_file):
            try:
                # Convert using ImageMagick or Inkscape
                cmd = f"convert -background none -density 96 -resize 224x224 '{svg_file}' '{png_file}' 2>/dev/null"
                result = os.system(cmd)
                if result == 0:
                    converted += 1
            except:
                pass

print(f"Converted {converted} icons to PNG")
PYTHON_SCRIPT
    
    print_success "Tabler Icons prepared"
}

# Create minimal test dataset
create_test_dataset() {
    print_header "Creating Test Dataset"
    
    TEST_DIR="${DATA_DIR}/test"
    mkdir -p "${TEST_DIR}/test_class"
    
    print_info "Generating 5 test images..."
    
    python3 << 'PYTHON_SCRIPT'
import os
from PIL import Image, ImageDraw
import random

test_dir = os.path.expanduser("${DATA_DIR}/test/test_class")
os.makedirs(test_dir, exist_ok=True)

# Create simple test images
for i in range(5):
    img = Image.new('RGB', (224, 224), color='white')
    draw = ImageDraw.Draw(img)
    
    # Draw random shapes
    for _ in range(3):
        x1 = random.randint(10, 100)
        y1 = random.randint(10, 100)
        x2 = random.randint(150, 200)
        y2 = random.randint(150, 200)
        color = (random.randint(50, 200), random.randint(50, 200), random.randint(50, 200))
        draw.rectangle([x1, y1, x2, y2], fill=color, outline=color)
    
    img.save(os.path.join(test_dir, f"test_{i:03d}.jpg"))

print("Created 5 test images")
PYTHON_SCRIPT
    
    print_success "Test dataset created at ${TEST_DIR}"
}

# Show summary and recommendations
show_summary() {
    print_header "Dataset Download Summary"
    
    if [ -d "${DATA_DIR}" ]; then
        TOTAL_SIZE=$(du -sh "${DATA_DIR}" 2>/dev/null | cut -f1 || echo "unknown")
        echo "Data directory: ${DATA_DIR}"
        echo "Total size: $TOTAL_SIZE"
        echo ""
        
        if [ -d "${DATA_DIR}/test" ]; then
            TEST_IMAGES=$(find "${DATA_DIR}/test" -type f | wc -l)
            echo "✓ Test dataset: $TEST_IMAGES images"
        fi
        
        if [ -d "${DATA_DIR}/quickdraw" ]; then
            QD_CATEGORIES=$(ls -d "${DATA_DIR}/quickdraw"/*/ 2>/dev/null | wc -l)
            QD_IMAGES=$(find "${DATA_DIR}/quickdraw" -name "*.png" 2>/dev/null | wc -l)
            echo "✓ Quick Draw dataset: $QD_CATEGORIES categories, $QD_IMAGES images"
        fi
        
        if [ -d "${DATA_DIR}/tabler_icons/png_224" ]; then
            ICON_DIRS=$(ls -d "${DATA_DIR}/tabler_icons/png_224"/*/ 2>/dev/null | wc -l)
            ICON_IMAGES=$(find "${DATA_DIR}/tabler_icons/png_224" -name "*.png" 2>/dev/null | wc -l)
            echo "✓ Tabler Icons: $ICON_DIRS categories, $ICON_IMAGES images"
        fi
    fi
}

# Show help
show_help() {
    cat << 'EOF'
SuperSVG Dataset Download Script

Usage: ./download_datasets.sh [option]

Options:
  test          Download minimal test dataset (fastest, ~5 MB)
  quickdraw     Download Quick Draw dataset (recommended, ~1.5 GB)
  icons         Download Tabler Icons dataset (~500 MB)
  all           Download all datasets (default)
  help          Show this help message

Examples:
  ./download_datasets.sh                    # Download all
  ./download_datasets.sh test               # Quick verification
  ./download_datasets.sh quickdraw          # Just Quick Draw

Data will be downloaded to: ./input/

After downloading, train with:
  ./docker-run.sh train input 100 32 0.001
  make train

EOF
}

# Main logic
main() {
    local option="${1:-all}"
    
    case "$option" in
        test)
            setup_directories
            create_test_dataset
            show_summary
            ;;
        quickdraw)
            setup_directories
            download_quickdraw
            show_summary
            ;;
        icons)
            setup_directories
            download_tabler_icons
            show_summary
            ;;
        all)
            setup_directories
            create_test_dataset
            download_quickdraw
            download_tabler_icons
            show_summary
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown option: $option"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    print_success "Dataset download completed!"
    echo ""
    echo "Next step: ./docker-run.sh train input 100 32 0.001"
}

main "$@"
