#!/bin/bash
################################################################################
# SuperSVG Cloud Platform Selector
# Interactive guide to help choose the best GPU cloud provider
################################################################################

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║         SuperSVG Cloud Training Platform Selector        ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Note: Lambda Labs is frequently sold out. This tool will recommend${NC}"
echo -e "${YELLOW}the best available alternatives (RunPod, Vast.ai, AWS).${NC}"
echo ""

# Initialize scores
runpod_score=0
vast_score=0
aws_score=0
lambda_score=0

# Question 1: Experience level
echo -e "${BLUE}Question 1 of 7${NC}"
echo "What is your cloud experience level?"
echo "  1) Beginner - I want the simplest setup"
echo "  2) Intermediate - I have some cloud experience"
echo "  3) Advanced - I'm comfortable with cloud infrastructure"
read -p "Your choice: " choice
case $choice in
    1) runpod_score=$((runpod_score + 3)); lambda_score=$((lambda_score + 2)) ;;
    2) runpod_score=$((runpod_score + 2)); vast_score=$((vast_score + 1)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 3)); vast_score=$((vast_score + 1)) ;;
esac
echo ""

# Question 2: Budget sensitivity
echo -e "${BLUE}Question 2 of 7${NC}"
echo "How important is minimizing cost?"
echo "  1) Critical - I need the absolute lowest cost"
echo "  2) Important - I want good value for money"
echo "  3) Not critical - Performance and reliability matter more"
read -p "Your choice: " choice
case $choice in
    1) vast_score=$((vast_score + 4)); runpod_score=$((runpod_score + 2)); aws_score=$((aws_score + 1)) ;;
    2) runpod_score=$((runpod_score + 3)); vast_score=$((vast_score + 2)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 3)); lambda_score=$((lambda_score + 2)) ;;
esac
echo ""

# Question 3: Dataset size
echo -e "${BLUE}Question 3 of 7${NC}"
echo "What is your dataset size?"
echo "  1) Small (< 50K samples) - Icon datasets"
echo "  2) Medium (50K - 5M samples)"
echo "  3) Large (> 5M samples) - Quick Draw size"
read -p "Your choice: " choice
case $choice in
    1) runpod_score=$((runpod_score + 2)); vast_score=$((vast_score + 2)) ;;
    2) runpod_score=$((runpod_score + 2)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 3)); runpod_score=$((runpod_score + 1)) ;;
esac
echo ""

# Question 4: Training frequency
echo -e "${BLUE}Question 4 of 7${NC}"
echo "How often will you train models?"
echo "  1) One-time or occasional experiments"
echo "  2) Regular training (weekly)"
echo "  3) Continuous/production training"
read -p "Your choice: " choice
case $choice in
    1) vast_score=$((vast_score + 2)); runpod_score=$((runpod_score + 2)) ;;
    2) runpod_score=$((runpod_score + 3)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 4)); runpod_score=$((runpod_score + 1)) ;;
esac
echo ""

# Question 5: Availability importance
echo -e "${BLUE}Question 5 of 7${NC}"
echo "How important is instant availability?"
echo "  1) Critical - I need to start immediately"
echo "  2) Important - Within a few hours is fine"
echo "  3) Flexible - I can wait for the best deal"
read -p "Your choice: " choice
case $choice in
    1) aws_score=$((aws_score + 3)); runpod_score=$((runpod_score + 2)); vast_score=$((vast_score + 2)) ;;
    2) runpod_score=$((runpod_score + 3)); vast_score=$((vast_score + 2)); aws_score=$((aws_score + 1)) ;;
    3) vast_score=$((vast_score + 2)); lambda_score=$((lambda_score + 1)) ;;
esac
echo ""

# Question 6: VRAM requirements
echo -e "${BLUE}Question 6 of 7${NC}"
echo "Do you need more than 24GB VRAM?"
echo "  1) Yes - I want to use very large batch sizes (128+)"
echo "  2) Unsure - What's recommended for SuperSVG?"
echo "  3) No - 24GB is plenty"
read -p "Your choice: " choice
case $choice in
    1) lambda_score=$((lambda_score + 3)); vast_score=$((vast_score + 1)) ;;
    2) runpod_score=$((runpod_score + 2)); vast_score=$((vast_score + 1)) ;;
    3) runpod_score=$((runpod_score + 1)); vast_score=$((vast_score + 1)); aws_score=$((aws_score + 1)) ;;
esac
echo ""

# Question 7: AWS/Cloud experience
echo -e "${BLUE}Question 7 of 7${NC}"
echo "What's your experience with cloud providers?"
echo "  1) I'm already using AWS (S3, EC2, etc.)"
echo "  2) I prefer simple, straightforward platforms"
echo "  3) I'm comfortable learning new platforms"
read -p "Your choice: " choice
case $choice in
    1) aws_score=$((aws_score + 4)) ;;
    2) runpod_score=$((runpod_score + 3)); lambda_score=$((lambda_score + 1)) ;;
    3) runpod_score=$((runpod_score + 1)); vast_score=$((vast_score + 2)) ;;
esac
echo ""

# Calculate results - find highest score
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                    RECOMMENDATION                       ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Determine winner
max_score=$runpod_score
winner="runpod"
if [ $vast_score -gt $max_score ]; then
    max_score=$vast_score
    winner="vast"
fi
if [ $aws_score -gt $max_score ]; then
    max_score=$aws_score
    winner="aws"
fi
if [ $lambda_score -gt $max_score ]; then
    max_score=$lambda_score
    winner="lambda"
fi

# Display recommendation based on winner
case $winner in
    "runpod")
        echo -e "${GREEN}★★★ RECOMMENDED: RunPod RTX 4090 ★★★${NC}"
        echo ""
        echo -e "${GREEN}Why RunPod is best for you:${NC}"
        echo "  ✓ Best price/performance ratio (\$0.44-0.69/hour)"
        echo "  ✓ Good availability (rarely sold out)"
        echo "  ✓ Simple setup (use our Lambda Labs script)"
        echo "  ✓ 24GB VRAM (perfect for batch_size=48-64)"
        echo "  ✓ Fast NVMe storage included"
        echo "  ✓ Pay-as-you-go, no commitments"
        echo ""
        echo -e "${YELLOW}Setup command:${NC}"
        echo "  1. Sign up at https://runpod.io"
        echo "  2. Deploy RTX 4090 or A5000 Pod (Ubuntu 22.04)"
        echo "  3. SSH into your pod and run:"
        echo "  curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh"
        echo "  chmod +x setup-lambda-labs.sh && ./setup-lambda-labs.sh"
        echo ""
        echo -e "${YELLOW}Estimated cost for your use case:${NC}"
        echo "  • Icon dataset (30K, 200 epochs): ~\$0.88-1.38"
        echo "  • Quick Draw (1M, 100 epochs): ~\$4.40-6.90"
        echo "  • Hourly rate: \$0.44-0.69/hour"
        ;;
    
    "vast")
        echo -e "${MAGENTA}★★★ RECOMMENDED: Vast.ai RTX 4090 ★★★${NC}"
        echo ""
        echo -e "${MAGENTA}Why Vast.ai is best for you:${NC}"
        echo "  ✓ Cheapest option (\$0.30-0.60/hour)"
        echo "  ✓ Excellent availability (P2P marketplace)"
        echo "  ✓ Flexible GPU selection"
        echo "  ✓ Good for budget-conscious training"
        echo "  ⚠️  Check provider reliability (>95% recommended)"
        echo ""
        echo -e "${YELLOW}Setup command:${NC}"
        echo "  1. Sign up at https://vast.ai"
        echo "  2. Search for RTX 4090 (24GB) instances"
        echo "  3. Filter by reliability score >95%"
        echo "  4. SSH into instance and run:"
        echo "  curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh"
        echo "  chmod +x setup-lambda-labs.sh && ./setup-lambda-labs.sh"
        echo ""
        echo -e "${YELLOW}Estimated cost for your use case:${NC}"
        echo "  • Icon dataset (30K, 200 epochs): ~\$0.60-1.20"
        echo "  • Quick Draw (1M, 100 epochs): ~\$3.00-6.00"
        echo "  • Hourly rate: \$0.30-0.60/hour"
        ;;
    
    "aws")
        echo -e "${BLUE}★★★ RECOMMENDED: AWS EC2 g5.2xlarge (Spot) ★★★${NC}"
        echo ""
        echo -e "${BLUE}Why AWS EC2 is best for you:${NC}"
        echo "  ✓ 60-70% cost savings with spot instances"
        echo "  ✓ Best availability and reliability"
        echo "  ✓ S3 integration for datasets/backups"
        echo "  ✓ CloudWatch monitoring built-in"
        echo "  ✓ Production-ready infrastructure"
        echo "  ⚠️  More complex setup"
        echo ""
        echo -e "${YELLOW}Setup command:${NC}"
        echo "  1. Launch g5.2xlarge spot instance (Ubuntu 22.04)"
        echo "  2. SSH into instance and run:"
        echo "  curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh"
        echo "  chmod +x setup-aws-ec2.sh && ./setup-aws-ec2.sh"
        echo ""
        echo -e "${YELLOW}Estimated cost for your use case:${NC}"
        echo "  • Icon dataset (30K, 200 epochs):"
        echo "    - Spot: ~\$0.80-1.20"
        echo "    - On-demand: ~\$2.42-3.64"
        echo "  • Quick Draw (1M, 100 epochs):"
        echo "    - Spot: ~\$4-6"
        echo "    - On-demand: ~\$12-18"
        echo "  • Hourly rate: \$0.36-0.50/hour (spot)"
        ;;
    
    "lambda")
        echo -e "${YELLOW}★★★ RECOMMENDED: Lambda Labs (If Available) ★★★${NC}"
        echo ""
        echo -e "${YELLOW}Lambda Labs recommendation:${NC}"
        echo "  ⚠️  WARNING: Lambda Labs is frequently sold out!"
        echo "  • A6000 (48GB): \$0.80/hour - Almost always unavailable"
        echo "  • A100 (40GB): \$1.29/hour - Sometimes available"
        echo ""
        echo -e "${GREEN}Better Alternative: RunPod RTX 4090${NC}"
        echo "  ✓ Actually available (\$0.44-0.69/hour)"
        echo "  ✓ Better value than Lambda A100"
        echo "  ✓ 24GB VRAM is sufficient for SuperSVG"
        echo ""
        echo -e "${YELLOW}Setup command (RunPod):${NC}"
        echo "  1. Sign up at https://runpod.io"
        echo "  2. Deploy RTX 4090 Pod"
        echo "  3. Run: ./setup-lambda-labs.sh"
        ;;
esac

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Show alternatives
echo -e "${YELLOW}Alternative Options (in order of preference):${NC}"
echo ""
case $winner in
    "runpod")
        echo "  1. Vast.ai RTX 4090 (\$0.30-0.60/hour) - Cheapest"
        echo "  2. AWS EC2 g5.2xlarge spot (\$0.36-0.50/hour) - Best infrastructure"
        echo "  3. Lambda Labs A100 (\$1.29/hour) - If available"
        ;;
    "vast")
        echo "  1. RunPod RTX 4090 (\$0.44-0.69/hour) - More reliable"
        echo "  2. AWS EC2 g5.2xlarge spot (\$0.36-0.50/hour) - Best infrastructure"
        echo "  3. Lambda Labs A100 (\$1.29/hour) - If available"
        ;;
    "aws")
        echo "  1. RunPod RTX 4090 (\$0.44-0.69/hour) - Simpler setup"
        echo "  2. Vast.ai RTX 4090 (\$0.30-0.60/hour) - Cheapest"
        echo "  3. Lambda Labs A100 (\$1.29/hour) - If available"
        ;;
    "lambda")
        echo "  1. RunPod RTX 4090 (\$0.44-0.69/hour) - Best available option"
        echo "  2. Vast.ai RTX 4090 (\$0.30-0.60/hour) - Cheapest"
        echo "  3. AWS EC2 g5.2xlarge spot (\$0.36-0.50/hour) - Best infrastructure"
        ;;
esac

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Detailed comparison
echo -e "${BLUE}Detailed Comparison:${NC}"
echo ""
printf "%-20s %-15s %-15s %-15s %-15s\n" "Feature" "RunPod" "Vast.ai" "AWS EC2" "Lambda"
echo "────────────────────────────────────────────────────────────────────────────────"
printf "%-20s %-15s %-15s %-15s %-15s\n" "GPU" "RTX 4090" "RTX 4090" "A10G" "A100/A6000"
printf "%-20s %-15s %-15s %-15s %-15s\n" "VRAM" "24GB" "24GB" "24GB" "40-48GB"
printf "%-20s %-15s %-15s %-15s %-15s\n" "Cost (cheapest)" "\$0.44/hr" "\$0.30/hr" "\$0.36/hr" "\$0.80-1.29/hr"
printf "%-20s %-15s %-15s %-15s %-15s\n" "Setup Time" "10-15 min" "10-15 min" "15-20 min" "10-15 min"
printf "%-20s %-15s %-15s %-15s %-15s\n" "Availability" "Good" "Excellent" "Excellent" "Poor"
printf "%-20s %-15s %-15s %-15s %-15s\n" "Best Batch Size" "48-64" "48-64" "32-48" "96-128"

echo ""
echo -e "${GREEN}Ready to get started?${NC}"
echo "1. Read the full comparison: cat CLOUD_SETUP_README.md"
echo "2. Sign up for your chosen platform"
echo "3. Run the appropriate setup script"
echo "4. Follow the quick start guide generated after setup"
echo ""

# Offer to show more info
read -p "Would you like to see the full setup README? (y/n): " show_readme
if [ "$show_readme" = "y" ] || [ "$show_readme" = "Y" ]; then
    if [ -f "CLOUD_SETUP_README.md" ]; then
        less CLOUD_SETUP_README.md
    else
        echo "CLOUD_SETUP_README.md not found in current directory"
        echo "Make sure you're in the SuperSVG repository root"
    fi
fi

echo ""
echo -e "${CYAN}Good luck with your training! 🚀${NC}"
