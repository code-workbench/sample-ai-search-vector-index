# Sample AI Search Vector Index

This repository contains a complete Azure AI Search infrastructure solution with private endpoints, designed for secure vector search implementations.

## 🏗️ Infrastructure

The `infra/` folder contains a comprehensive Bicep template that creates:

### Core Components
- **Azure AI Search Service** - Standard tier with semantic search capabilities
- **Storage Account** - For data storage with private blob access
- **Virtual Network** - Secure network infrastructure with dedicated subnets
- **Private Endpoints** - Secure connectivity to AI Search and Storage services
- **Private DNS Zones** - Proper DNS resolution for private endpoints

### Security Features
- ✅ All public access disabled on AI Search and Storage
- ✅ Private endpoints for secure connectivity
- ✅ Network ACLs and service endpoints configured
- ✅ TLS 1.2+ enforcement
- ✅ System-assigned managed identity for AI Search

### Monitoring & Observability
- **Log Analytics Workspace** - Centralized logging
- **Application Insights** - Performance monitoring and diagnostics

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and configured
- Appropriate Azure permissions (Contributor role)
- Resource group (will be created if doesn't exist)

### Deploy Infrastructure

```bash
# Clone the repository
git clone <repository-url>
cd sample-ai-search-vector-index

# Deploy using the provided script
./infra/deploy.sh
```

Or deploy manually:
```bash
# Create resource group
az group create --name rg-aisearch-private --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group rg-aisearch-private \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Validate Deployment

```bash
# Run validation script
./infra/validate.sh
```

## 📁 Repository Structure

```
sample-ai-search-vector-index/
├── infra/                          # Infrastructure as Code
│   ├── main.bicep                  # Main Bicep template
│   ├── main.parameters.json        # Parameters file
│   ├── deploy.sh                   # Bash deployment script
│   ├── validate.sh                 # Validation script
│   ├── .env.template               # Environment configuration template
│   └── README.md                   # Infrastructure documentation
├── LICENSE                         # License file
└── README.md                       # This file
```

## 🔧 Configuration

### Customization Options

Edit `infra/main.parameters.json` to customize:

```json
{
  "projectName": {
    "value": "your-project-name"
  },
  "environment": {
    "value": "dev|staging|prod"
  },
  "location": {
    "value": "eastus|westus2|etc"
  },
  "tags": {
    "value": {
      "costCenter": "your-cost-center",
      "owner": "your-team"
    }
  }
}
```

### Network Configuration

Default network setup:
- **VNet**: 10.0.0.0/16
- **AI Search Subnet**: 10.0.1.0/24
- **Private Endpoints Subnet**: 10.0.2.0/24

Modify the `main.bicep` file to change network ranges if needed.

## 🔐 Security Considerations

### Access Control
- All services are configured for private access only
- Use managed identities where possible
- Retrieve service keys only when necessary
- Consider Azure Key Vault for sensitive configuration

### Network Security
- Private endpoints ensure traffic never leaves Azure backbone
- Service endpoints provide additional network-level security
- Network Security Groups can be added for additional control

### Monitoring
- All resources tagged for cost management
- Application Insights configured for performance monitoring
- Log Analytics workspace for centralized logging

## 📊 Cost Optimization

### Current Configuration Costs (Approximate)
- **AI Search Standard**: ~$250/month
- **Storage Account Standard LRS**: ~$20/month for 100GB
- **Private Endpoints**: ~$7.50/month per endpoint
- **Log Analytics**: Pay-per-GB ingested
- **Application Insights**: First 5GB free, then pay-per-GB

### Cost Optimization Tips
1. Choose appropriate AI Search tier based on usage
2. Use Standard LRS storage for cost-effectiveness
3. Set appropriate retention periods for logs
4. Monitor and optimize based on actual usage

## 🛠️ Development Workflow

### After Deployment

1. **Retrieve Service Keys**:
   ```bash
   # AI Search admin key
   az search admin-key show --resource-group rg-aisearch-private --service-name <search-service-name>
   
   # Storage account keys
   az storage account keys list --resource-group rg-aisearch-private --account-name <storage-account-name>
   ```

2. **Test Connectivity**: Deploy test VM in the same VNet to verify private endpoint connectivity

3. **Configure Applications**: Update your applications with the service endpoints and authentication

4. **Set up Monitoring**: Configure alerts and dashboards in Application Insights

### Application Integration

To use the AI Search service from your applications:

1. **Network Access**: Deploy in the same VNet or set up VNet peering
2. **Authentication**: Use managed identities or service keys
3. **SDK Integration**: Use Azure Cognitive Search SDKs with private endpoints
4. **Connection Strings**: Use the private endpoint URLs for connectivity

## 🔍 Troubleshooting

### Common Issues

1. **DNS Resolution Issues**
   - Ensure private DNS zones are linked to your VNet
   - Verify DNS settings on client machines

2. **Network Connectivity**
   - Check subnet configurations
   - Verify private endpoint connections are approved
   - Review NSG rules if applied

3. **Service Access**
   - Ensure applications are deployed in correct VNet
   - Verify service keys and authentication
   - Check firewall and network ACL settings

### Validation Commands

```bash
# Check private endpoint connections
az network private-endpoint list --resource-group rg-aisearch-private

# Verify DNS resolution (from VM in VNet)
nslookup <search-service-name>.search.windows.net

# Test service accessibility
curl -H "api-key: <admin-key>" https://<search-service-name>.search.windows.net/indexes
```

## 📚 Additional Resources

- [Azure AI Search Documentation](https://docs.microsoft.com/azure/search/)
- [Private Endpoints Documentation](https://docs.microsoft.com/azure/private-link/)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Vector Search in Azure AI Search](https://docs.microsoft.com/azure/search/vector-search-overview)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the infrastructure deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review deployment logs and validation results
3. Open an issue in this repository with detailed error information
This sample shows how to create an Azure AI Search with indexers for multiple data sources to support a rag implementation
