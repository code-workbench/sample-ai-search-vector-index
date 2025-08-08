# Azure AI Search with VNet Integration - Terraform Infrastructure

This Terraform configuration creates an Azure AI Search instance with VNet integration and a storage account for document ingestion. The infrastructure is designed for secure, private access to AI Search services with proper monitoring and access controls.

## 🏗️ Infrastructure Components

This Terraform configuration deploys a comprehensive Azure AI Search solution with:

- **🔍 Azure AI Search Service** - Cognitive search with vector capabilities
- **📦 Azure Storage Account** - Document ingestion and blob storage
- **🗃️ Azure SQL Database** - Vector database for advanced indexing
- **🔐 Managed Identities** - Secure service-to-service authentication
- **🌐 Private Endpoints** - All services connected via private networking
- **📊 Log Analytics** - Comprehensive monitoring and diagnostics

## Prerequisites

- Azure subscription with appropriate permissions
- Existing Virtual Network (VNet) and subnet for private endpoints
- Terraform >= 1.0
- Azure CLI or Azure PowerShell for authentication

## Quick Start

1. **Clone and navigate to the infra directory**:
   ```bash
   cd infra
   ```

2. **Update the terraform.tfvars.json file** with your specific values:
   ```json
   {
     "project_name": "your-project-name",
     "environment": "dev",
     "location": "East US",
     "vnet_id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}",
     "subnet_id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}/subnets/{subnet-name}"
   }
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `project_name` | Name of your project | `"my-ai-search-project"` |
| `vnet_id` | Resource ID of existing VNet | `"/subscriptions/.../virtualNetworks/vnet-name"` |
| `subnet_id` | Resource ID of existing subnet | `"/subscriptions/.../subnets/subnet-name"` |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environment` | `"dev"` | Environment name (dev, staging, prod) |
| `location` | `"East US"` | Azure region for deployment |
| `search_sku` | `"standard"` | AI Search service tier |
| `search_replica_count` | `1` | Number of search replicas (1-12) |
| `search_partition_count` | `1` | Number of search partitions (1,2,3,4,6,12) |
| `semantic_search_sku` | `"free"` | Semantic search tier (disabled, free, standard) |
| `storage_account_tier` | `"Standard"` | Storage account tier |
| `storage_replication_type` | `"LRS"` | Storage replication type |

## Security Features

### Network Security
- **Private Endpoints**: Both AI Search and Storage Account are accessible only through private endpoints
- **Network Isolation**: Public access is disabled for both services
- **Private DNS**: Custom DNS zones ensure private name resolution

### Identity and Access Management
- **System Assigned Identity**: AI Search service has a system-assigned managed identity
- **User Assigned Identity**: Additional identity for fine-grained access control
- **RBAC**: Proper role assignments for service-to-service communication
- **Least Privilege**: Services only have necessary permissions

### Data Protection
- **Encryption**: All data encrypted at rest and in transit
- **TLS 1.2**: Minimum TLS version enforced
- **Blob Versioning**: Version control for stored documents
- **Soft Delete**: Protection against accidental deletion

## Monitoring and Diagnostics

The infrastructure includes comprehensive monitoring:

- **Log Analytics Workspace**: Centralized logging
- **Diagnostic Settings**: Enabled for both AI Search and Storage Account
- **Operation Logs**: Track AI Search operations
- **Metrics**: Performance and usage metrics
- **Search Slow Logs**: Monitor slow queries

## Resource Naming Convention

Resources are named using the `azurecaf` provider with the following pattern:
- `{project_name}-{resource_type}-{environment}`

Examples:
- Resource Group: `myproject-rg-dev`
- AI Search: `myproject-search-dev`
- Storage Account: `myprojectstrdev` (storage accounts have naming restrictions)

## Outputs

After deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `search_service_url` | URL for the AI Search service |
| `search_service_name` | Name of the AI Search service |
| `storage_account_name` | Name of the storage account |
| `search_service_identity_principal_id` | Principal ID for RBAC assignments |

## Cost Optimization

- **Right-sizing**: Start with minimal replicas and partitions
- **Storage Tier**: Use Standard tier for development
- **Log Retention**: 30-day retention for Log Analytics
- **Semantic Search**: Free tier for development/testing

## Troubleshooting

### Common Issues

1. **Private Endpoint Connection Issues**:
   - Verify subnet has sufficient IP addresses
   - Check DNS resolution from your VNet
   - Ensure proper NSG rules

2. **Access Denied Errors**:
   - Verify RBAC role assignments
   - Check managed identity configuration
   - Confirm private endpoint status

3. **DNS Resolution Problems**:
   - Verify private DNS zone links
   - Check DNS zone records
   - Test from within the VNet

### Useful Commands

```bash
# Check AI Search service status
az search service show --name <search-service-name> --resource-group <resource-group>

# Test private endpoint connectivity
nslookup <search-service-name>.search.windows.net

# View diagnostic logs
az monitor log-analytics query --workspace <workspace-id> --analytics-query "AzureDiagnostics | limit 10"
```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources. Ensure you have backups of any important data.

## Contributing

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test configurations in development environment
4. Use semantic versioning for releases

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure AI Search documentation
3. Open an issue in the repository

## 🗃️ SQL Database Integration

The Azure SQL Database is configured with:

- **Vector Support**: Ready for vector embeddings and similarity search
- **Private Connectivity**: Accessed only through private endpoints
- **Azure AD Authentication**: Integrated with your Azure AD tenant
- **Performance Tuning**: Automatic tuning enabled for optimal performance
- **Monitoring**: Comprehensive diagnostic logging to Log Analytics

### Vector Database Capabilities

The SQL Database supports:
- Vector similarity search using built-in functions
- Indexing strategies optimized for AI Search integration
- Scalable storage for large vector datasets
- Advanced query capabilities for hybrid search scenarios
