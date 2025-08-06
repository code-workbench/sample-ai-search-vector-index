// ========================================================
// Azure AI Search Infrastructure with Private Endpoints
// ========================================================

targetScope = 'resourceGroup'

@description('The name of the project')
param projectName string = 'aisearch-private'

@description('The location where the resources will be deployed')
param location string = resourceGroup().location

@description('Environment name')
param environment string = 'dev'

@description('Tags for the resources')
param tags object = {}

// Variables for consistent naming
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, location))
var baseName = '${projectName}-${environment}-${resourceToken}'

// Network configuration
var vnetAddressSpace = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.1.0/24'
var privateEndpointSubnetAddressPrefix = '10.0.2.0/24'

// ========================================================
// Virtual Network and Subnets
// ========================================================

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${baseName}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'subnet-ai-search'
        properties: {
          addressPrefix: subnetAddressPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Search'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'subnet-private-endpoints'
        properties: {
          addressPrefix: privateEndpointSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ========================================================
// Storage Account
// ========================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${resourceToken}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: virtualNetwork.properties.subnets[0].id
          action: 'Allow'
        }
      ]
    }
  }
}

// ========================================================
// Azure AI Search Service
// ========================================================

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: 'srch-${baseName}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  sku: {
    name: 'standard'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'disabled'
    semanticSearch: 'standard'
    networkRuleSet: {
      ipRules: []
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// ========================================================
// Private DNS Zones
// ========================================================

resource privateSearchDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.search.windows.net'
  location: 'global'
  tags: union(tags, { 'azd-env-name': environment })
  properties: {}
}

resource privateStorageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
  location: 'global'
  tags: union(tags, { 'azd-env-name': environment })
  properties: {}
}

// ========================================================
// Private DNS Zone Virtual Network Links
// ========================================================

resource searchDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateSearchDnsZone
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource storageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateStorageBlobDnsZone
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

// ========================================================
// Private Endpoints
// ========================================================

// Private Endpoint for Azure AI Search
resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${searchService.name}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'search-connection'
        properties: {
          privateLinkServiceId: searchService.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

// Private Endpoint for Storage Account (Blob)
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-${storageAccount.name}-blob'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// ========================================================
// Private DNS Zone Groups for Private Endpoints
// ========================================================

resource searchPrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: searchPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'search-config'
        properties: {
          privateDnsZoneId: privateSearchDnsZone.id
        }
      }
    ]
  }
}

resource storagePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob-config'
        properties: {
          privateDnsZoneId: privateStorageBlobDnsZone.id
        }
      }
    ]
  }
}

// ========================================================
// Log Analytics Workspace (for monitoring)
// ========================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${baseName}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
  }
}

// ========================================================
// Application Insights
// ========================================================

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${baseName}'
  location: location
  tags: union(tags, { 'azd-env-name': environment })
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ========================================================
// Outputs
// ========================================================

@description('The name of the Azure AI Search service')
output AZURE_SEARCH_SERVICE_NAME string = searchService.name

@description('The endpoint URL of the Azure AI Search service')
output AZURE_SEARCH_SERVICE_ENDPOINT string = 'https://${searchService.name}.search.windows.net/'

@description('The name of the storage account')
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name

@description('The blob endpoint of the storage account')
output AZURE_STORAGE_BLOB_ENDPOINT string = storageAccount.properties.primaryEndpoints.blob

@description('The name of the virtual network')
output AZURE_VNET_NAME string = virtualNetwork.name

@description('The name of the AI Search subnet')
output AZURE_SEARCH_SUBNET_NAME string = virtualNetwork.properties.subnets[0].name

@description('The name of the private endpoints subnet')
output AZURE_PRIVATE_ENDPOINTS_SUBNET_NAME string = virtualNetwork.properties.subnets[1].name

@description('The resource group name')
output AZURE_RESOURCE_GROUP string = resourceGroup().name

@description('The location where resources were deployed')
output AZURE_LOCATION string = location

@description('The name of the Log Analytics workspace')
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalyticsWorkspace.name

@description('The name of the Application Insights component')
output AZURE_APPLICATION_INSIGHTS_NAME string = applicationInsights.name

@description('The Application Insights connection string')
output AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString

@description('The Application Insights instrumentation key')
output AZURE_APPLICATION_INSIGHTS_INSTRUMENTATION_KEY string = applicationInsights.properties.InstrumentationKey
