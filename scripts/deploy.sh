#!/bin/bash

# Terraform Deployment Script
# Automates Terraform deployment with validation and safety checks


set -euo pipefail

# Configuration
ENVIRONMENT="${1:-dev}"
ACTION="${2:-plan}"

# Colors
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

# Function to display usage
usage() {
    echo "Usage: $0 <environment> <action>"
    echo ""
    echo "Environments: dev, staging, prod"
    echo "Actions: plan, apply, destroy"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan      # Plan dev environment changes"
    echo "  $0 dev apply     # Apply dev environment changes"
    echo "  $0 prod destroy  # Destroy prod environment (requires confirmation)"
    exit 1
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|prod)
            log_info "Environment: ${ENVIRONMENT}"
            ;;
        *)
            log_error "Invalid environment: ${ENVIRONMENT}"
            usage
            ;;
    esac
}

# Validate action
validate_action() {
    case $ACTION in
        plan|apply|destroy)
            log_info "Action: ${ACTION}"
            ;;
        *)
            log_error "Invalid action: ${ACTION}"
            usage
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: ${TERRAFORM_VERSION}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log_info "AWS Account ID: ${ACCOUNT_ID}"
    
    log_success "Prerequisites check passed"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform..."
    
    cd "environments/${ENVIRONMENT}"
    
    terraform init -upgrade
    
    log_success "Terraform initialized"
}

# Validate Terraform configuration
validate_terraform() {
    log_info "Validating Terraform configuration..."
    
    terraform validate
    
    log_success "Terraform validation passed"
}

# Format Terraform files
format_terraform() {
    log_info "Formatting Terraform files..."
    
    terraform fmt -recursive
    
    log_success "Terraform files formatted"
}

# Run Terraform plan
run_plan() {
    log_info "Running Terraform plan..."
    
    terraform plan \
        -var-file="terraform.tfvars" \
        -out=tfplan
    
    log_success "Terraform plan completed"
    log_info "Review the plan above before applying"
}

# Run Terraform apply
run_apply() {
    log_info "Running Terraform apply..."
    
    # Run plan first
    terraform plan \
        -var-file="terraform.tfvars" \
        -out=tfplan
    
    # Show plan summary
    echo ""
    log_warning "Review the plan above carefully!"
    echo ""
    
    # Confirmation for production
    if [ "$ENVIRONMENT" = "prod" ]; then
        log_warning "You are about to apply changes to PRODUCTION!"
        read -p "Type 'yes' to continue: " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            log_error "Apply cancelled"
            exit 1
        fi
    else
        read -p "Apply changes? (yes/no): " CONFIRM
        if [ "$CONFIRM" != "yes" ]; then
            log_error "Apply cancelled"
            exit 1
        fi
    fi
    
    # Apply changes
    terraform apply tfplan
    
    log_success "Terraform apply completed"
    
    # Show outputs
    echo ""
    log_info "Infrastructure outputs:"
    terraform output
}

# Run Terraform destroy
run_destroy() {
    log_error "DANGER: You are about to destroy infrastructure!"
    echo ""
    
    if [ "$ENVIRONMENT" = "prod" ]; then
        log_error "Destroying production is disabled for safety"
        log_info "If you really need to destroy production, do it manually"
        exit 1
    fi
    
    log_warning "This will destroy all resources in the ${ENVIRONMENT} environment"
    read -p "Type 'destroy-${ENVIRONMENT}' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "destroy-${ENVIRONMENT}" ]; then
        log_error "Destroy cancelled"
        exit 1
    fi
    
    terraform destroy \
        -var-file="terraform.tfvars" \
        -auto-approve
    
    log_success "Infrastructure destroyed"
}

# Main execution
main() {
    echo "========================================"
    echo "Terraform Deployment"
    echo "========================================"
    
    validate_environment
    validate_action
    check_prerequisites
    
    init_terraform
    validate_terraform
    format_terraform
    
    case $ACTION in
        plan)
            run_plan
            ;;
        apply)
            run_apply
            ;;
        destroy)
            run_destroy
            ;;
    esac
    
    echo ""
    log_success "Deployment script completed successfully!"
}

# Run main function
main
