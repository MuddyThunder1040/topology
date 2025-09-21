#!/bin/bash

# Load Testing Script for AWS Infrastructure
# This script performs load testing on the deployed ALB + ASG infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONCURRENT_USERS=${1:-10}
DURATION=${2:-300}  # 5 minutes default
LOAD_BALANCER_URL=""

echo -e "${BLUE}🚀 AWS Load Testing Script${NC}"
echo -e "${BLUE}=========================${NC}"

# Function to get load balancer URL from Terraform output
get_lb_url() {
    echo -e "${YELLOW}📋 Getting Load Balancer URL from Terraform...${NC}"
    LOAD_BALANCER_URL=$(terraform output -raw load_balancer_url 2>/dev/null || echo "")
    
    if [ -z "$LOAD_BALANCER_URL" ]; then
        echo -e "${RED}❌ Could not get Load Balancer URL from Terraform output${NC}"
        echo -e "${YELLOW}💡 Make sure to run 'terraform apply' first${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Load Balancer URL: $LOAD_BALANCER_URL${NC}"
}

# Function to check if the load balancer is healthy
check_health() {
    echo -e "${YELLOW}🏥 Checking Load Balancer health...${NC}"
    
    for i in {1..30}; do
        if curl -s --connect-timeout 5 "$LOAD_BALANCER_URL" > /dev/null; then
            echo -e "${GREEN}✅ Load Balancer is healthy!${NC}"
            return 0
        fi
        echo -e "${YELLOW}⏳ Waiting for Load Balancer to be ready... (attempt $i/30)${NC}"
        sleep 10
    done
    
    echo -e "${RED}❌ Load Balancer is not responding after 5 minutes${NC}"
    exit 1
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Checking dependencies...${NC}"
    
    # Check if apache2-utils (ab) is installed
    if ! command -v ab &> /dev/null; then
        echo -e "${YELLOW}📥 Installing Apache Bench (ab)...${NC}"
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y apache2-utils
        elif command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools
        else
            echo -e "${RED}❌ Could not install apache2-utils. Please install manually.${NC}"
            exit 1
        fi
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl is required but not installed.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies are installed${NC}"
}

# Function to perform load test
perform_load_test() {
    echo -e "${BLUE}🔥 Starting Load Test${NC}"
    echo -e "${BLUE}===================${NC}"
    echo -e "${YELLOW}🎯 Target: $LOAD_BALANCER_URL${NC}"
    echo -e "${YELLOW}👥 Concurrent Users: $CONCURRENT_USERS${NC}"
    echo -e "${YELLOW}⏱️  Duration: $DURATION seconds${NC}"
    echo ""
    
    # Calculate total requests
    TOTAL_REQUESTS=$((CONCURRENT_USERS * 2))
    
    # Perform the load test
    echo -e "${GREEN}🚀 Running Apache Bench load test...${NC}"
    ab -n $TOTAL_REQUESTS -c $CONCURRENT_USERS -t $DURATION -g load_test_results.dat "$LOAD_BALANCER_URL/" || true
    
    echo ""
    echo -e "${GREEN}✅ Load test completed!${NC}"
}

# Function to monitor Auto Scaling during test
monitor_scaling() {
    echo -e "${BLUE}📊 Monitoring Auto Scaling Group${NC}"
    echo -e "${BLUE}================================${NC}"
    
    ASG_NAME=$(terraform output -raw autoscaling_group_name 2>/dev/null || echo "")
    
    if [ -z "$ASG_NAME" ]; then
        echo -e "${YELLOW}⚠️  Could not get ASG name from Terraform output${NC}"
        return
    fi
    
    echo -e "${YELLOW}📈 Auto Scaling Group: $ASG_NAME${NC}"
    echo ""
    
    # Monitor for 5 minutes
    for i in {1..30}; do
        echo -e "${BLUE}📊 Check $i/30 - $(date)${NC}"
        
        # Get current instances
        aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$ASG_NAME" \
            --query 'AutoScalingGroups[0].{DesiredCapacity:DesiredCapacity,MinSize:MinSize,MaxSize:MaxSize,Instances:length(Instances)}' \
            --output table 2>/dev/null || echo -e "${YELLOW}⚠️  Could not fetch ASG details${NC}"
        
        echo ""
        sleep 10
    done
}

# Function to generate load test report
generate_report() {
    echo -e "${BLUE}📄 Load Test Summary${NC}"
    echo -e "${BLUE}===================${NC}"
    
    # Basic connectivity test
    echo -e "${YELLOW}🔗 Testing connectivity to different endpoints:${NC}"
    
    endpoints=("/" "/load-test.html")
    
    for endpoint in "${endpoints[@]}"; do
        echo -e "${YELLOW}Testing: ${LOAD_BALANCER_URL}${endpoint}${NC}"
        response=$(curl -s -w "HTTP Status: %{http_code} | Response Time: %{time_total}s" "${LOAD_BALANCER_URL}${endpoint}" || echo "Failed to connect")
        echo -e "${GREEN}$response${NC}"
        echo ""
    done
    
    # Instance distribution test
    echo -e "${YELLOW}🔄 Testing load distribution (10 requests):${NC}"
    for i in {1..10}; do
        instance_info=$(curl -s "$LOAD_BALANCER_URL" | grep -o "Instance ID: [^<]*" | head -1 || echo "Instance ID: Unknown")
        echo -e "${GREEN}Request $i: $instance_info${NC}"
        sleep 1
    done
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up temporary files...${NC}"
    rm -f load_test_results.dat
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [concurrent_users] [duration_seconds]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Default: 10 users, 300 seconds"
    echo "  $0 20                 # 20 users, 300 seconds"
    echo "  $0 50 600             # 50 users, 600 seconds (10 minutes)"
    echo ""
    echo "Prerequisites:"
    echo "  - Terraform infrastructure must be deployed"
    echo "  - AWS CLI configured (optional, for ASG monitoring)"
    echo "  - apache2-utils package (will be installed automatically)"
}

# Main execution
main() {
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    echo -e "${GREEN}🎯 Starting AWS Load Test with $CONCURRENT_USERS concurrent users for $DURATION seconds${NC}"
    echo ""
    
    trap cleanup EXIT
    
    get_lb_url
    install_dependencies
    check_health
    
    echo -e "${YELLOW}🚀 Starting load test in 5 seconds...${NC}"
    sleep 5
    
    # Run load test in background
    perform_load_test &
    LOAD_TEST_PID=$!
    
    # Monitor scaling in background if AWS CLI is available
    if command -v aws &> /dev/null; then
        monitor_scaling &
        MONITOR_PID=$!
    fi
    
    # Wait for load test to complete
    wait $LOAD_TEST_PID
    
    # Kill monitoring if it's still running
    if [ ! -z "$MONITOR_PID" ]; then
        kill $MONITOR_PID 2>/dev/null || true
    fi
    
    echo ""
    generate_report
    
    echo ""
    echo -e "${GREEN}🎉 Load testing completed successfully!${NC}"
    echo -e "${YELLOW}💡 Check AWS CloudWatch for detailed metrics and scaling events${NC}"
}

# Run main function
main "$@"