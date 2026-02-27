#!/bin/bash

# Setup Python virtual environment for dataset downloads
# This script creates a venv and installs dependencies needed for dataset processing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv-datasets"

echo "=== Setting up Python environment for dataset downloads ==="
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is not installed"
    echo "Please install Python 3.7 or later:"
    echo "  brew install python@3.11"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✓ Found: ${PYTHON_VERSION}"
echo ""

# Create virtual environment if it doesn't exist
if [ -d "${VENV_DIR}" ]; then
    echo "✓ Virtual environment already exists at: ${VENV_DIR}"
else
    echo "Creating virtual environment at: ${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"
    echo "✓ Virtual environment created"
fi
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source "${VENV_DIR}/bin/activate"
echo "✓ Virtual environment activated"
echo ""

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip --quiet
echo "✓ pip upgraded"
echo ""

# Install requirements
echo "Installing dependencies from requirements-datasets.txt..."
pip install -r "${SCRIPT_DIR}/requirements-datasets.txt"
echo "✓ Dependencies installed"
echo ""

echo "=== Setup complete! ==="
echo ""
echo "The virtual environment is located at: ${VENV_DIR}"
echo "It will be automatically activated when running download_datasets.sh"
echo ""
echo "To manually activate it, run:"
echo "  source ${VENV_DIR}/bin/activate"
echo ""
