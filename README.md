AWS infrastructure with Terraform - VPC, EKS, RDS modules
[README.md](https://github.com/user-attachments/files/25355996/README.md)
AWS Infrastructure as Code with Terraform

[Terraform](https://www.terraform.io/)
[AWS](https://aws.amazon.com/)
[License](LICENSE)

Productionready Terraform modules for deploying a complete AWS infrastructure including VPC, EKS cluster, RDS, S3, monitoring, and security.

complete AWS environment with:

Netwoking: MultiAZ VPC with public/private subnets, NAT gateways, and route tables
Compute: Amazon EKS cluster with managed node groups and autoscaling
Database: RDS PostgreSQL with MultiAZ deployment and automated backups
Storage: S3 buckets with encryption and lifecycle policies
Monitoring: CloudWatch dashboards, alarms, and log groups
Security: IAM roles, security groups, KMS encryption, and AWS Secrets Manager

Features

Modular Design Reusable Terraform modules for each component  
MultiEnvironment Separate configurations for dev, staging, and production  
High Availability MultiAZ deployments with automatic failover  
Security Encryption at rest and in transit, least privilege IAM  
Cost Optimized Rightsized resources with autoscaling  
Monitoring Comprehensive CloudWatch metrics and alarms  
Disaster Recovery Automated backups and pointintime recovery  
GitOps Ready State management with S3 backend and DynamoDB locking

Prerequisites

AWS CLI configured with appropriate credentials
Terraform 1.6 or higher
kubectl (for EKS cluster access)

Installation

1. Clone the repository

bash
git clone https://github.com/yourusername/terraformawsinfrastructure.git
cd terraformawsinfrastructure

2. Initialize Terraform backend

bash
cd environments/dev
terraform init

3. Review the plan

bash
terraform plan varfile="terraform.tfvars"

4. Apply the configuration

bash
terraform apply varfile="terraform.tfvars"

5. Configure kubectl for EKS

bash
aws eks updatekubeconfig region useast1 name devekscluster
kubectl get nodes

Project Structure

terraformawsinfrastructure/
├── modules/
│ ├── vpc/ VPC with subnets, NAT, IGW
│ ├── eks/ EKS cluster with node groups
│ ├── rds/ RDS database instances
│ ├── s3/ S3 buckets with policies
│ ├── iam/ IAM roles and policies
│ ├── securitygroups/ Security group rules
│ ├── monitoring/ CloudWatch alarms and dashboards
│ └── bastion/ Bastion host for secure access
├── environments/
│ ├── dev/ Development environment
│ ├── staging/ Staging environment
│ └── prod/ Production environment
├── scripts/
│ ├── setupbackend.sh Initialize Terraform backend
│ ├── deploy.sh Deployment automation
│ └── destroy.sh Safe destruction script
└── docs/
├── ARCHITECTRE.md Architecture documentation
└── TROUBLESHOOTING.md Common issues and solutions

Configuration

Environment Variables

Create a `terraform.tfvars` file in your environment directory:

hcl
General
aws_region = "useast1"
environment = "dev"
project_name = "myapp"

VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["useast1a", "useast1b", "useast1c"]

EKS Configuration
eks_version = "1.28"
node_instance_types = ["t3.medium"]
desired_capacity = 3
min_capacity = 2
max_capacity = 10

RDS Configuration
db_instance_class = "db.t3.medium"
db_allocated_storage = 100
db_name = "appdb"

Tags
tags = {
Project = "MyApp"
Environment = "dev"
ManagedBy = "Terraform"
}

Backend Configuration

Initialize the S3 backend for state management:

bash
./scripts/setupbackend.sh

This creates:

S3 bucket for Terraform state with versioning enabled
DynamoDB table for state locking
KMS key for state encryption

Modules

VPC Module

Creates a productionready VPC with:

Public and private subnets across multiple AZs
NAT Gateways for outbound internet access
Internet Gateway for public subnet access
VPC Flow Logs for network monitoring
Route tables and associations

Usage:

hcl
module "vpc" {
source = "../../modules/vpc"

vpc_cidr = var.vpc_cidr
availability_zones = var.availability_zones
environment = var.environment
project_name = var.project_name
}

EKS Module

Provisions Amazon EKS cluster with:

Managed node groups with autoscaling
IRSA (IAM Roles for Service Accounts)
Cluster autoscaler
CloudWatch logging
Security group rules

Usage:

hcl
module "eks" {
source = "../../modules/eks"

cluster_name = "${var.project_name}${var.environment}eks"
cluster_version = var.eks_version
vpc_id = module.vpc.vpc_id
private_subnet_ids = module.vpc.private_subnet_ids
node_instance_types = var.node_instance_types
}

RDS Module

Creates RDS PostgreSQL instance with:

MultiAZ deployment for HA
Automated backups with retention
Encryption at rest with KMS
Enhanced monitoring
Parameter and subnet groups

Usage:

hcl
module "rds" {
source = "../../modules/rds"

identifier = "${var.project_name}${var.environment}db"
instance_class = var.db_instance_class
allocated_storage = var.db_allocated_storage
vpc_id = module.vpc.vpc_id
subnet_ids = module.vpc.private_subnet_ids
allowed_cidr_blocks = [module.vpc.vpc_cidr]
}

Monitoring Module

Sets up comprehensive monitoring:

CloudWatch dashboards for all resources
Alarms for critical metrics
SNS topics for notifications
Log groups with retention policies

Security Features

Network Isolation: Private subnets for all application resources
Encryption: KMS encryption for EBS, RDS, and S3
IAM: Least privilege roles and policies
Security Groups: Restrictive ingress/egress rules
Secrets Management: AWS Secrets Manager for sensitive data
VPC Flow Logs: Network traffic monitoring
WAF: Web Application Firewall for ALB (optional)

Monitoring & Observability

CloudWatch Dashboards

Automatically created dashboards for:

EKS cluster metrics (CPU, memory, network)
RDS performance (connections, IOPS, latency)
VPC network metrics
Application load balancer metrics

Alarms

Preconfigured alarms for:

High CPU utilization (>80%)
Low memory available (<20%)
Database connection failures
NAT Gateway errors
EKS node failures

Logs

Centralized logging with:

VPC Flow Logs → CloudWatch
EKS control plane logs → CloudWatch
RDS error and slow query logs → CloudWatch
Application logs via Fluent Bit

Cost Optimization

Autoscaling: Node groups scale based on demand
Spot Instances: Optional spot instance support for noncritical workloads
Rightsizing: Instance recommendations based on actual usage
Storage Lifecycle: Automated S3 lifecycle policies
Reserved Instances: Recommendations for predictable workloads

Deployment Strategies

Development Environment

bash
cd environments/dev
terraform apply autoapprove

Production Environment (with approval)

bash
cd environments/prod
terraform plan out=tfplan
Review the plan
terraform apply tfplan

BlueGreen Deployment

bash
Deploy to new environment
terraform apply var="environment=prodgreen"
Switch traffic
Destroy old environment
terraform destroy var="environment=prodblue"

Testing

Validate Configuration

bash
terraform validate
terraform fmt recursive

Security Scanning

bash
Run tfsec
tfsec .

Run Checkov
checkov d .

Cost Estimation

bash
Using Infracost
infracost breakdown path .

Disaster Recovery

Backup Strategy

RDS: Automated daily backups with 7day retention
EBS: Daily snapshots via AWS Backup
S3: Versioning enabled with crossregion replication
Terraform State: S3 versioning and replication enabled

Recovery Procedures

1. RDS pointintime recovery
2. EBS snapshot restoration
3. S3 version recovery
4. Infrastructure recreation from Terraform state

Documentation

[Architecture Overview](docs/ARCHITECTURE.md)
[Module Documentation](docs/MODULES.md)
[Troubleshooting Guide](docs/TROUBLESHOOTING.md)
[Security Best Practices](docs/SECURITY.md)

Author

Mounika A  
DevOps Engineer  
ananthojim123@gmail.com
