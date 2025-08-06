# Azure AI Search Infrastructure with Private Endpoints

This Bicep template creates a complete Azure AI Search infrastructure with private endpoints for secure, private network access.

## Architecture Components

### Core Resources
- **Azure AI Search Service** - Standard tier with semantic search enabled
- **Storage Account** - Standard LRS for data storage with blob endpoint
- **Virtual Network** - Contains subnets for AI Search and private endpoints
- **Private Endpoints** - Secure connection to AI Search and Storage
- **Private DNS Zones** - DNS resolution for private endpoints

### Network Components
- **Virtual Network**: 10.0.0.0/16 address space
  - **AI Search Subnet**: 10.0.1.0/24 with service endpoints
  - **Private Endpoints Subnet**: 10.0.2.0/24 for private endpoint connections

### Security Features
- All resources are configured for private access only
- Storage account blocks public access and uses network ACLs
- AI Search service has public network access disabled
- Private DNS zones ensure proper name resolution

### Monitoring
- **Log Analytics Workspace** for centralized logging
- **Application Insights** for application performance monitoring

## Deployment

### Prerequisites
- Azure CLI or PowerShell
- Appropriate Azure permissions (Contributor role)
- Resource group created

### Deploy with Azure CLI

```bash
# Create resource group (if not exists)
az group create --name rg-aisearch-private --location eastus

# Deploy the template
az deployment group create \
  --resource-group rg-aisearch-private \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Deploy with PowerShell

```powershell
# Create resource group (if not exists)
New-AzResourceGroup -Name "rg-aisearch-private" -Location "East US"

# Deploy the template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-aisearch-private" `
  -TemplateFile "infra/main.bicep" `
  -TemplateParameterFile "infra/main.parameters.json"
```

## Configuration

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `projectName` | string | `aisearch-private` | Name of the project |
| `location` | string | Resource group location | Azure region for deployment |
| `environment` | string | `dev` | Environment name (dev, staging, prod) |
| `tags` | object | `{}` | Additional tags for resources |

### Network Configuration

The template creates a virtual network with specific subnets:

- **AI Search Subnet** (`10.0.1.0/24`): Contains service endpoints for Azure Search and Storage
- **Private Endpoints Subnet** (`10.0.2.0/24`): Hosts private endpoints for secure connectivity

### Security Configuration

1. **Storage Account Security**:
   - Public blob access disabled
   - HTTPS traffic only enforced
   - Minimum TLS version 1.2
   - Network ACLs restricting access to VNet only

2. **AI Search Security**:
   - Public network access disabled
   - System-assigned managed identity enabled
   - Standard semantic search enabled

3. **Private Connectivity**:
   - Private endpoints for both AI Search and Storage
   - Private DNS zones for proper name resolution
   - Network policies configured appropriately

## Outputs

The template provides the following outputs:

- `AZURE_SEARCH_SERVICE_NAME`: Name of the AI Search service
- `AZURE_SEARCH_SERVICE_ENDPOINT`: AI Search service URL
- `AZURE_STORAGE_ACCOUNT_NAME`: Storage account name
- `AZURE_STORAGE_BLOB_ENDPOINT`: Storage blob endpoint URL
- `AZURE_VNET_NAME`: Virtual network name
- `AZURE_SEARCH_SUBNET_NAME`: AI Search subnet name
- `AZURE_PRIVATE_ENDPOINTS_SUBNET_NAME`: Private endpoints subnet name
- `AZURE_RESOURCE_GROUP`: Resource group name
- `AZURE_LOCATION`: Deployment location
- `AZURE_LOG_ANALYTICS_WORKSPACE_NAME`: Log Analytics workspace name
- `AZURE_APPLICATION_INSIGHTS_NAME`: Application Insights name
- `AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING`: Application Insights connection string

## Post-Deployment Steps

1. **Retrieve Service Keys**: Use Azure CLI or Portal to get AI Search admin keys and storage account keys
2. **Configure Applications**: Update application configuration with the service endpoints and keys
3. **Test Connectivity**: Verify that resources can communicate through private endpoints
4. **Set up Monitoring**: Configure alerts and monitoring dashboards in Application Insights

## Access from Applications

To access the AI Search service and Storage account from your applications:

1. **Deploy applications in the same VNet** or set up VNet peering
2. **Use private endpoints** for secure connectivity
3. **Configure DNS resolution** to use the private DNS zones
4. **Implement proper authentication** using managed identities where possible

## Security Considerations

- All network traffic flows through private endpoints
- Storage account and AI Search service block public internet access
- Network security groups can be added for additional traffic control
- Consider using Azure Key Vault for storing connection strings and keys
- Enable diagnostic logging for security monitoring

## Cost Optimization

- AI Search Standard tier provides good balance of features and cost
- Storage account uses Standard LRS for cost-effectiveness
- Log Analytics workspace set to 30-day retention
- Consider scaling resources based on actual usage patterns

## Troubleshooting

Common issues and solutions:

1. **DNS Resolution**: Ensure private DNS zones are properly linked to VNet
2. **Network Connectivity**: Verify subnet configurations and NSG rules
3. **Private Endpoints**: Check private endpoint connections are approved
4. **Service Endpoints**: Ensure subnets have correct service endpoint configurations
