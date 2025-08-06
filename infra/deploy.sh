#!/bin/bash

# Azure AI Search Infrastructure Deployment Script
# This script deploys the AI Search infrastructure with private endpoints

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP_NAME="rg-aisearch-private"
LOCATION="usgovvirginia"  # Update to your desired location
TEMPLATE_FILE="infra/main.bicep"
PARAMETERS_FILE="infra/main.parameters.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    error "You are not logged in to Azure. Please run 'az login' first."
    exit 1
fi

log "Starting Azure AI Search infrastructure deployment..."

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
log "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Create resource group if it doesn't exist
log "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log "Creating resource group: $RESOURCE_GROUP_NAME"
    az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"
    success "Resource group created successfully"
else
    log "Resource group already exists"
fi

# Deploy the template
log "Deploying infrastructure..."
DEPLOYMENT_NAME="ai-search-deployment-$(date +%Y%m%d-%H%M%S)"

if az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --verbose; then
    success "Infrastructure deployment completed successfully!"
else
    error "Infrastructure deployment failed"
    exit 1
fi

# Get deployment outputs
log "Retrieving deployment outputs..."
OUTPUTS=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs \
    --output json)

# Display key outputs
log "Deployment Summary:"
echo "===================="
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Deployment Name: $DEPLOYMENT_NAME"
echo "Location: $LOCATION"
echo ""

# Extract and display specific outputs
SEARCH_SERVICE_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_SEARCH_SERVICE_NAME.value // "N/A"')
SEARCH_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.AZURE_SEARCH_SERVICE_ENDPOINT.value // "N/A"')
STORAGE_ACCOUNT_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_STORAGE_ACCOUNT_NAME.value // "N/A"')
VNET_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_VNET_NAME.value // "N/A"')

echo "Key Resources Created:"
echo "- AI Search Service: $SEARCH_SERVICE_NAME"
echo "- Search Endpoint: $SEARCH_ENDPOINT"
echo "- Storage Account: $STORAGE_ACCOUNT_NAME"
echo "- Virtual Network: $VNET_NAME"
echo ""

# Security reminders
warning "IMPORTANT SECURITY NOTES:"
echo "1. AI Search service keys are not included in outputs for security"
echo "2. Storage account keys are not included in outputs for security"
echo "3. Use Azure CLI or portal to retrieve service keys when needed"
echo "4. Consider using managed identities for application authentication"
echo ""

# Next steps
log "Next Steps:"
echo "1. Retrieve service keys using Azure CLI:"
echo "   az search admin-key show --resource-group $RESOURCE_GROUP_NAME --service-name $SEARCH_SERVICE_NAME"
echo "   az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME"
echo ""
echo "2. Test private connectivity from a VM in the same VNet"
echo "3. Configure your applications to use the private endpoints"
echo "4. Set up monitoring and alerting in Application Insights"
echo ""

success "Deployment script completed successfully!"
