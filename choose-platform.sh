#!/bin/bash
################################################################################
# SuperSVG Cloud Platform Selector
# Interactive guide to help choose between Lambda Labs and AWS EC2
################################################################################

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║         SuperSVG Cloud Training Platform Selector        ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize scores
lambda_score=0
aws_score=0

# Question 1: Experience level
echo -e "${BLUE}Question 1 of 7${NC}"
echo "What is your cloud experience level?"
echo "  1) Beginner - I want the simplest setup"
echo "  2) Intermediate - I have some cloud experience"
echo "  3) Advanced - I'm comfortable with cloud infrastructure"
read -p "Your choice: " choice
case $choice in
    1) lambda_score=$((lambda_score + 3)) ;;
    2) lambda_score=$((lambda_score + 1)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 2)) ;;
esac
echo ""

# Question 2: Budget sensitivity
echo -e "${BLUE}Question 2 of 7${NC}"
echo "How important is minimizing cost?"
echo "  1) Critical - I need the lowest possible cost"
echo "  2) Important - I want good value"
echo "  3) Not critical - Performance is more important"
read -p "Your choice: " choice
case $choice in
    1) aws_score=$((aws_score + 3)) ;;
    2) aws_score=$((aws_score + 1)); lambda_score=$((lambda_score + 1)) ;;
    3) lambda_score=$((lambda_score + 2)) ;;
esac
echo ""

# Question 3: Dataset size
echo -e "${BLUE}Question 3 of 7${NC}"
echo "What is your dataset size?"
echo "  1) Small (< 50K samples) - Icon size datasets"
echo "  2) Medium (50K - 5M samples)"
echo "  3) Large (> 5M samples) - Quick Draw size"
read -p "Your choice: " choice
case $choice in
    1) lambda_score=$((lambda_score + 2)) ;;
    2) lambda_score=$((lambda_score + 1)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 2)) ;;
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
    1) lambda_score=$((lambda_score + 2)) ;;
    2) lambda_score=$((lambda_score + 1)); aws_score=$((aws_score + 1)) ;;
    3) aws_score=$((aws_score + 3)) ;;
esac
echo ""

# Question 5: Time sensitivity
echo -e "${BLUE}Question 5 of 7${NC}"
echo "How time-sensitive is your training?"
echo "  1) Not urgent - I can wait for availability"
echo "  2) Somewhat urgent - I need to start soon"
echo "  3) Very urgent - I need to start immediately"
read -p "Your choice: " choice
case $choice in
    1) lambda_score=$((lambda_score + 1)) ;;
    2) aws_score=$((aws_score + 2)) ;;
    3) aws_score=$((aws_score + 3)) ;;
esac
echo ""

# Question 6: VRAM requirements
echo -e "${BLUE}Question 6 of 7${NC}"
echo "Do you need more than 24GB VRAM?"
echo "  1) Yes - I want to use large batch sizes (128+)"
echo "  2) Not sure - Default batch sizes are fine"
echo "  3) No - 24GB is enough"
read -p "Your choice: " choice
case $choice in
    1) lambda_score=$((lambda_score + 3)) ;;
    2) lambda_score=$((lambda_score + 1)) ;;
    3) aws_score=$((aws_score + 1)) ;;
esac
echo ""

# Question 7: AWS experience
echo -e "${BLUE}Question 7 of 7${NC}"
echo "Are you already using AWS for other services?"
echo "  1) Yes - I have an AWS account with S3, etc."
echo "  2) No - I don't use AWS"
echo "  3) I'm open to either"
read -p "Your choice: " choice
case $choice in
    1) aws_score=$((aws_score + 3)) ;;
    2) lambda_score=$((lambda_score + 2)) ;;
    3) ;;
esac
echo ""

# Calculate results
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                    RECOMMENDATION                       ${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

if [ $lambda_score -gt $aws_score ]; then
    margin=$((lambda_score - aws_score))
    if [ $margin -gt 5 ]; then
        confidence="STRONGLY"
    else
        confidence="MODERATELY"
    fi
    
    echo -e "${GREEN}★★★ ${confidence} RECOMMENDED: Lambda Labs A6000 ★★★${NC}"
    echo ""
    echo -e "${GREEN}Why Lambda Labs is best for you:${NC}"
    echo "  ✓ Simpler setup (15 minutes vs 20 minutes)"
    echo "  ✓ More VRAM (48GB vs 24GB)"
    echo "  ✓ Predictable pricing (\$0.80/hour flat rate)"
    echo "  ✓ Great for research and experimentation"
    echo "  ✓ Fewer configuration steps"
    echo ""
    echo -e "${YELLOW}Setup command:${NC}"
    echo "  curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-lambda-labs.sh"
    echo "  chmod +x setup-lambda-labs.sh"
    echo "  ./setup-lambda-labs.sh"
    echo ""
    echo -e "${YELLOW}Estimated cost for your use case:${NC}"
    echo "  • Icon dataset (30K, 200 epochs): ~\$1.60-2.40"
    echo "  • Quick Draw (1M, 100 epochs): ~\$8-12"
    echo "  • Hourly rate: \$0.80/hour"
    
elif [ $aws_score -gt $lambda_score ]; then
    margin=$((aws_score - lambda_score))
    if [ $margin -gt 5 ]; then
        confidence="STRONGLY"
    else
        confidence="MODERATELY"
    fi
    
    echo -e "${BLUE}★★★ ${confidence} RECOMMENDED: AWS EC2 g5.2xlarge ★★★${NC}"
    echo ""
    echo -e "${BLUE}Why AWS EC2 is best for you:${NC}"
    echo "  ✓ 60-70% cost savings with spot instances"
    echo "  ✓ Better availability and reliability"
    echo "  ✓ S3 integration for data/backup"
    echo "  ✓ CloudWatch monitoring"
    echo "  ✓ Production-ready infrastructure"
    echo ""
    echo -e "${YELLOW}Setup command:${NC}"
    echo "  curl -O https://raw.githubusercontent.com/sjtuplayer/SuperSVG/master/setup-aws-ec2.sh"
    echo "  chmod +x setup-aws-ec2.sh"
    echo "  ./setup-aws-ec2.sh"
    echo ""
    echo -e "${YELLOW}Estimated cost for your use case:${NC}"
    echo "  • Icon dataset (30K, 200 epochs):"
    echo "    - Spot: ~\$0.80-1.20"
    echo "    - On-demand: ~\$2.42-3.64"
    echo "  • Quick Draw (1M, 100 epochs):"
    echo "    - Spot: ~\$4-6"
    echo "    - On-demand: ~\$12-18"
    echo "  • Hourly rate: \$0.36-0.50/hour (spot) or \$1.21/hour (on-demand)"
    
else
    echo -e "${YELLOW}★★★ TIE - Either Platform Works Well ★★★${NC}"
    echo ""
    echo -e "${YELLOW}Both platforms are suitable for your needs!${NC}"
    echo ""
    echo -e "${GREEN}Lambda Labs A6000:${NC}"
    echo "  • Simpler, faster setup"
    echo "  • More VRAM (48GB)"
    echo "  • \$0.80/hour flat rate"
    echo ""
    echo -e "${BLUE}AWS EC2 g5.2xlarge:${NC}"
    echo "  • Cheaper with spot (\$0.36-0.50/hour)"
    echo "  • Better for AWS ecosystem integration"
    echo "  • Higher availability"
    echo ""
    echo -e "${YELLOW}Suggestion:${NC} Try Lambda Labs for simplicity, or AWS for cost savings"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Show alternative option
echo -e "${YELLOW}Alternative Option:${NC}"
if [ $lambda_score -gt $aws_score ]; then
    echo "If Lambda Labs is unavailable, you can use AWS EC2:"
    echo "  • Use spot instances for 60-70% savings"
    echo "  • g5.2xlarge has 24GB VRAM (reduce batch_size if needed)"
    echo "  • Setup: ./setup-aws-ec2.sh"
else
    echo "If you prefer simpler setup, try Lambda Labs:"
    echo "  • 48GB VRAM allows larger batch sizes"
    echo "  • Straightforward \$0.80/hour pricing"
    echo "  • Setup: ./setup-lambda-labs.sh"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Detailed comparison
echo -e "${BLUE}Detailed Comparison:${NC}"
echo ""
printf "%-25s %-20s %-20s\n" "Feature" "Lambda Labs" "AWS EC2"
echo "────────────────────────────────────────────────────────────────"
printf "%-25s %-20s %-20s\n" "GPU" "A6000" "A10G"
printf "%-25s %-20s %-20s\n" "VRAM" "48GB" "24GB"
printf "%-25s %-20s %-20s\n" "Cost (cheapest)" "\$0.80/hour" "\$0.36/hour (spot)"
printf "%-25s %-20s %-20s\n" "Setup Time" "10-15 min" "15-20 min"
printf "%-25s %-20s %-20s\n" "Availability" "Limited" "High"
printf "%-25s %-20s %-20s\n" "Best Batch Size" "64-128" "32-64"
printf "%-25s %-20s %-20s\n" "S3 Integration" "Manual" "Native"
printf "%-25s %-20s %-20s\n" "Spot Instances" "No" "Yes"

echo ""
echo -e "${GREEN}Ready to get started?${NC}"
echo "1. Read the full comparison: cat CLOUD_SETUP_README.md"
echo "2. Run your chosen setup script"
echo "3. Follow the quick start guide generated after setup"
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
