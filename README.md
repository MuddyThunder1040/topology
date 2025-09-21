# AWS Load Balancer + Auto Scaling Infrastructure

This project creates a highly available web application infrastructure on AWS with the following components:

## 🏗️ Architecture Overview

- **VPC**: Custom VPC with public subnets across 2 availability zones
- **EC2 Instances**: 2-4 instances running Apache web servers (t2.micro)
- **Application Load Balancer (ALB)**: Distributes traffic across instances
- **Auto Scaling Group (ASG)**: Scales between 2 (min) and 4 (max) instances
- **CloudWatch Alarms**: CPU-based scaling policies (scale up >70%, scale down <30%)
- **Security Groups**: Proper network security configuration

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **Jenkins** with AWS credentials configured (credential ID: `Aws-cli`)
3. **Terraform** installed
4. **Apache Bench** (for load testing - script will install if needed)

## 🚀 Deployment Instructions

### Step 1: Deploy Infrastructure via Jenkins

1. **Access Jenkins** and navigate to your pipeline job
2. **Build with Parameters**:
   - **TF_OPERATION**: Select `apply`
3. **Run the Pipeline** - it will:
   - Initialize Terraform
   - Create all AWS resources
   - Output the Load Balancer URL

### Step 2: Verify Deployment

After successful deployment, you'll get outputs including:
- Load Balancer DNS name
- Load Balancer URL
- VPC and subnet IDs
- Auto Scaling Group name

### Step 3: Test the Web Application

Visit the Load Balancer URL to see:
- Instance information (ID, AZ, type, IP)
- Server status and metrics
- Load balancing in action (refresh to see different instances)

## 🔥 Load Testing

### Quick Start
```bash
# Run default load test (10 concurrent users, 5 minutes)
./load-test.sh

# Custom load test (50 concurrent users, 10 minutes)
./load-test.sh 50 600
```

### Load Test Features
- **Health Check**: Verifies infrastructure is ready
- **Real-time Monitoring**: Shows Auto Scaling Group changes
- **Multiple Endpoints**: Tests both main page and load-test endpoint
- **Distribution Analysis**: Shows which instances are serving requests
- **Comprehensive Reporting**: Detailed results and metrics

### Expected Behavior During Load Test
1. **Initial State**: 2 instances running
2. **Load Applied**: CPU usage increases
3. **Scale Up**: When CPU > 70% for 2 periods, new instances launch
4. **Maximum Scale**: Up to 4 instances total
5. **Scale Down**: When CPU < 30% for 2 periods, instances terminate
6. **Final State**: Returns to 2 instances

## 📊 Monitoring

### CloudWatch Metrics to Watch
- **EC2 Instance CPU Utilization**
- **ALB Request Count**
- **ALB Target Response Time**
- **Auto Scaling Group Metrics**

### Scaling Triggers
- **Scale Up**: CPU > 70% for 4 minutes (2 periods × 2 minutes)
- **Scale Down**: CPU < 30% for 4 minutes (2 periods × 2 minutes)
- **Cooldown**: 5 minutes between scaling actions

## 🛠️ Infrastructure Components

### Network Configuration
```
VPC: 10.0.0.0/16
├── Public Subnet 1: 10.0.1.0/24 (us-east-1a)
├── Public Subnet 2: 10.0.2.0/24 (us-east-1b)
├── Internet Gateway
└── Route Tables (public routing)
```

### Security Groups
- **ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **Web Security Group**: Allows HTTP (80) from ALB and SSH (22) from anywhere

### Auto Scaling Configuration
- **Minimum Instances**: 2
- **Maximum Instances**: 4
- **Desired Capacity**: 2
- **Health Check**: ELB health checks
- **Launch Template**: Amazon Linux 2 with Apache

## 📁 Project Files

- **`aws.tf`**: Main Terraform configuration
- **`Jenkinsfile`**: Jenkins pipeline for deployment
- **`load-test.sh`**: Load testing script
- **`README.md`**: This documentation

## 🔧 Management Operations

### Scale Testing
```bash
# Manual scaling (via AWS CLI)
aws autoscaling set-desired-capacity --auto-scaling-group-name web-asg --desired-capacity 4

# Reset to default
aws autoscaling set-desired-capacity --auto-scaling-group-name web-asg --desired-capacity 2
```

### Cleanup
To destroy all resources:
1. Go to Jenkins pipeline
2. Set **TF_OPERATION** to `destroy`
3. Run the pipeline

## 🔍 Troubleshooting

### Common Issues

1. **Load Balancer not responding**
   - Check security groups
   - Verify instances are healthy in target group
   - Wait for instances to pass health checks

2. **Auto Scaling not working**
   - Check CloudWatch alarms status
   - Verify scaling policies are attached
   - Monitor CPU metrics in CloudWatch

3. **High costs**
   - Remember to destroy resources when done testing
   - Use `terraform destroy` or Jenkins destroy operation

### Health Check Endpoints
- **Main Page**: `http://[ALB-URL]/`
- **Load Test Page**: `http://[ALB-URL]/load-test.html`
- **Health Check**: Internal health checks on port 80

## 💰 Cost Estimation

**Hourly costs (approximate)**:
- EC2 instances (2-4 × t2.micro): $0.0116 - $0.0464/hour
- Application Load Balancer: $0.0225/hour
- Data transfer: Variable based on usage
- CloudWatch: Minimal for basic metrics

**Daily cost range**: ~$0.50 - $2.00 depending on usage and scaling

## 🎯 Load Testing Results

The load testing script will show:
- Request success rates
- Response times
- Instance distribution
- Auto Scaling events
- CloudWatch alarm states

Monitor these metrics to validate that:
- Load is distributed across instances
- Auto Scaling triggers correctly
- Applications remain responsive under load
- Infrastructure scales and heals automatically

---

**Happy Load Testing! 🚀**