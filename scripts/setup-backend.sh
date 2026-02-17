#!/bin/bash

# Terraform Backend Setup Script
# Creates S3 bucket and DynamoDB table for Terraform state management


set -euo pipefail

# Configuration
PROJECT_NAME="${1:-myapp}"
ENVIRONMENT="${2:-dev}"
AWS_REGION="${3:-us-east-1}"

BUCKET_NAME="terraform-state-${PROJECT_NAME}-${ENVIRONMENT}"
DYNAMODB_TABLE="terraform-state-lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials are not configured. Please configure them first."
    exit 1
fi

log_info "Setting up Terraform backend for ${PROJECT_NAME} in ${ENVIRONMENT} environment"

# Create S3 bucket for state
log_info "Creating S3 bucket: ${BUCKET_NAME}"

if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3api create-bucket \
        --bucket "${BUCKET_NAME}" \
        --region "${AWS_REGION}" \
        --create-bucket-configuration LocationConstraint="${AWS_REGION}" \
        2>/dev/null || true
    
    # Enable versioning
    log_info "Enabling versioning on S3 bucket"
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    log_info "Enabling encryption on S3 bucket"
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Block public access
    log_info "Blocking public access to S3 bucket"
    aws s3api put-public-access-block \
        --bucket "${BUCKET_NAME}" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Add lifecycle policy
    log_info "Adding lifecycle policy to S3 bucket"
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "${BUCKET_NAME}" \
        --lifecycle-configuration '{
            "Rules": [{
                "Id": "DeleteOldVersions",
                "Status": "Enabled",
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                }
            }]
        }'
    
    log_success "S3 bucket created and configured: ${BUCKET_NAME}"
else
    log_warning "S3 bucket already exists: ${BUCKET_NAME}"
fi

# Create DynamoDB table for state locking
log_info "Creating DynamoDB table: ${DYNAMODB_TABLE}"

if ! aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" &> /dev/null; then
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}" \
        --tags Key=Project,Value="${PROJECT_NAME}" Key=Environment,Value="${ENVIRONMENT}"
    
    # Wait for table to be active
    log_info "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}"
    
    log_success "DynamoDB table created: ${DYNAMODB_TABLE}"
else
    log_warning "DynamoDB table already exists: ${DYNAMODB_TABLE}"
fi

# Output backend configuration
echo ""
log_info "Backend setup complete!"
echo ""
log_info "Add this configuration to your Terraform backend:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"${BUCKET_NAME}\""
echo "    key            = \"${ENVIRONMENT}/terraform.tfstate\""
echo "    region         = \"${AWS_REGION}\""
echo "    encrypt        = true"
echo "    dynamodb_table = \"${DYNAMODB_TABLE}\""
echo "  }"
echo "}"
echo ""

log_success "Terraform backend is ready to use!"
echo ""
log_info "Next steps:"
echo "  1. Update your backend configuration in main.tf"
echo "  2. Run: terraform init"
echo "  3. Run: terraform plan"
echo "  4. Run: terraform apply"
