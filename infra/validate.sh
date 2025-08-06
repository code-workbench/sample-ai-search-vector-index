#!/bin/bash

# Azure AI Search Infrastructure Validation Script
# This script validates the deployed infrastructure

set -e

# Configuration
RESOURCE_GROUP_NAME="rg-aisearch-private"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check function
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local description=$3
    
    log "Checking $description..."
    
    if az resource show --resource-group "$RESOURCE_GROUP_NAME" --resource-type "$resource_type" --name "$resource_name" &> /dev/null; then
        success "$description exists"
        return 0
    else
        error "$description not found"
        return 1
    fi
}

# Function to check private endpoint connections
check_private_endpoint() {
    local pe_name=$1
    local description=$2
    
    log "Checking $description..."
    
    local connection_state=$(az network private-endpoint show \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$pe_name" \
        --query "privateLinkServiceConnections[0].privateLinkServiceConnectionState.status" \
        --output tsv 2>/dev/null)
    
    if [ "$connection_state" = "Approved" ]; then
        success "$description is approved and connected"
        return 0
    else
        warning "$description connection state: $connection_state"
        return 1
    fi
}

log "Starting infrastructure validation..."

# Get deployment outputs to find resource names
LATEST_DEPLOYMENT=$(az deployment group list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "max_by([], &properties.timestamp).name" \
    --output tsv)

if [ -z "$LATEST_DEPLOYMENT" ]; then
    error "No deployments found in resource group $RESOURCE_GROUP_NAME"
    exit 1
fi

log "Using latest deployment: $LATEST_DEPLOYMENT"

OUTPUTS=$(az deployment group show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$LATEST_DEPLOYMENT" \
    --query properties.outputs \
    --output json)

# Extract resource names
SEARCH_SERVICE_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_SEARCH_SERVICE_NAME.value // ""')
STORAGE_ACCOUNT_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_STORAGE_ACCOUNT_NAME.value // ""')
VNET_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_VNET_NAME.value // ""')
LOG_WORKSPACE_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_LOG_ANALYTICS_WORKSPACE_NAME.value // ""')
APP_INSIGHTS_NAME=$(echo "$OUTPUTS" | jq -r '.AZURE_APPLICATION_INSIGHTS_NAME.value // ""')

echo "=============================================="
log "INFRASTRUCTURE VALIDATION REPORT"
echo "=============================================="
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Subscription: $SUBSCRIPTION_ID"
echo "Timestamp: $(date)"
echo ""

# Track validation results
VALIDATION_PASSED=true

# Check core resources
echo "Core Resources:"
echo "---------------"

if ! check_resource "Microsoft.Search/searchServices" "$SEARCH_SERVICE_NAME" "AI Search Service"; then
    VALIDATION_PASSED=false
fi

if ! check_resource "Microsoft.Storage/storageAccounts" "$STORAGE_ACCOUNT_NAME" "Storage Account"; then
    VALIDATION_PASSED=false
fi

if ! check_resource "Microsoft.Network/virtualNetworks" "$VNET_NAME" "Virtual Network"; then
    VALIDATION_PASSED=false
fi

if ! check_resource "Microsoft.OperationalInsights/workspaces" "$LOG_WORKSPACE_NAME" "Log Analytics Workspace"; then
    VALIDATION_PASSED=false
fi

if ! check_resource "Microsoft.Insights/components" "$APP_INSIGHTS_NAME" "Application Insights"; then
    VALIDATION_PASSED=false
fi

echo ""

# Check private endpoints
echo "Private Endpoints:"
echo "------------------"

PE_SEARCH="pe-$SEARCH_SERVICE_NAME"
PE_STORAGE="pe-$STORAGE_ACCOUNT_NAME-blob"

if ! check_private_endpoint "$PE_SEARCH" "AI Search Private Endpoint"; then
    VALIDATION_PASSED=false
fi

if ! check_private_endpoint "$PE_STORAGE" "Storage Account Private Endpoint"; then
    VALIDATION_PASSED=false
fi

echo ""

# Check DNS zones
echo "Private DNS Zones:"
echo "------------------"

DNS_ZONES=("privatelink.search.windows.net" "privatelink.blob.core.windows.net")
for zone in "${DNS_ZONES[@]}"; do
    if ! check_resource "Microsoft.Network/privateDnsZones" "$zone" "Private DNS Zone: $zone"; then
        VALIDATION_PASSED=false
    fi
done

echo ""

# Check network configuration
echo "Network Configuration:"
echo "----------------------"

log "Checking VNet subnets..."
SUBNETS=$(az network vnet subnet list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --vnet-name "$VNET_NAME" \
    --query "[].{name:name, addressPrefix:addressPrefix, serviceEndpoints:serviceEndpoints}" \
    --output json)

SUBNET_COUNT=$(echo "$SUBNETS" | jq length)
if [ "$SUBNET_COUNT" -eq 2 ]; then
    success "VNet has correct number of subnets (2)"
else
    error "VNet subnet count: $SUBNET_COUNT (expected: 2)"
    VALIDATION_PASSED=false
fi

# Check service endpoints
SEARCH_SUBNET_ENDPOINTS=$(echo "$SUBNETS" | jq -r '.[] | select(.name=="subnet-ai-search") | .serviceEndpoints | length')
if [ "$SEARCH_SUBNET_ENDPOINTS" -eq 2 ]; then
    success "AI Search subnet has correct service endpoints"
else
    warning "AI Search subnet service endpoints: $SEARCH_SUBNET_ENDPOINTS (expected: 2)"
fi

echo ""

# Check security configuration
echo "Security Configuration:"
echo "-----------------------"

log "Checking AI Search public access..."
SEARCH_PUBLIC_ACCESS=$(az search service show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$SEARCH_SERVICE_NAME" \
    --query "publicNetworkAccess" \
    --output tsv)

if [ "$SEARCH_PUBLIC_ACCESS" = "disabled" ]; then
    success "AI Search public access is disabled"
else
    error "AI Search public access is enabled (should be disabled)"
    VALIDATION_PASSED=false
fi

log "Checking Storage Account public access..."
STORAGE_PUBLIC_ACCESS=$(az storage account show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --query "publicNetworkAccess" \
    --output tsv)

if [ "$STORAGE_PUBLIC_ACCESS" = "Disabled" ]; then
    success "Storage Account public access is disabled"
else
    error "Storage Account public access: $STORAGE_PUBLIC_ACCESS (should be Disabled)"
    VALIDATION_PASSED=false
fi

echo ""

# Final validation result
echo "=============================================="
if [ "$VALIDATION_PASSED" = true ]; then
    success "VALIDATION PASSED - Infrastructure is correctly deployed"
    echo ""
    log "Your Azure AI Search infrastructure with private endpoints is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Test connectivity from a VM in the same VNet"
    echo "2. Configure your applications with the service endpoints"
    echo "3. Set up monitoring and alerts"
    echo "4. Retrieve service keys when needed for application configuration"
else
    error "VALIDATION FAILED - Some issues found"
    echo ""
    warning "Please review the errors above and redeploy if necessary"
fi
echo "=============================================="
