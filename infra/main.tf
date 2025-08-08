# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  environment = "usgovernment"
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource naming convention using azurecaf
resource "azurecaf_name" "resource_group" {
  name          = var.project_name
  resource_type = "azurerm_resource_group"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "search_service" {
  name          = var.project_name
  resource_type = "azurerm_search_service"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "storage_account" {
  name          = var.project_name
  resource_type = "azurerm_storage_account"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "private_endpoint_search" {
  name          = "${var.project_name}-search"
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "private_endpoint_storage" {
  name          = "${var.project_name}-storage"
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "sql_server" {
  name          = var.project_name
  resource_type = "azurerm_mssql_server"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "sql_database" {
  name          = var.project_name
  resource_type = "azurerm_mssql_database"
  suffixes      = [var.environment]
}

resource "azurecaf_name" "private_endpoint_sql" {
  name          = "${var.project_name}-sql"
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment]
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = merge(var.tags, {
    "azd-env-name" = var.environment
  })
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "${azurecaf_name.search_service.result}-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Storage Account for AI Search ingestion
resource "azurerm_storage_account" "main" {
  name                     = azurecaf_name.storage_account.result
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"

  # Security settings
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  # Network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  # Blob properties for versioning and soft delete
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# Storage Container for documents
resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_name = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Azure AI Search Service
resource "azurerm_search_service" "main" {
  name                         = azurecaf_name.search_service.result
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  sku                          = var.search_sku
  replica_count                = var.search_replica_count
  partition_count              = var.search_partition_count
  public_network_access_enabled = false
  
  # Enable semantic search if using Standard tier or higher
  semantic_search_sku = var.search_sku == "basic" ? null : var.semantic_search_sku

  # Identity for accessing other Azure resources
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Azure SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = azurecaf_name.sql_server.result
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  
  # Security settings
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  # Azure AD authentication
  azuread_administrator {
    login_username = data.azurerm_client_config.current.object_id
    object_id      = data.azurerm_client_config.current.object_id
  }

  # Identity for accessing other Azure resources
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Azure SQL Database with vector capabilities
resource "azurerm_mssql_database" "main" {
  name           = azurecaf_name.sql_database.result
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = var.sql_database_sku
  zone_redundant = false

  # Enable automatic tuning for performance
  auto_pause_delay_in_minutes = var.sql_database_sku == "GP_S_Gen5_1" ? 60 : null
  min_capacity               = var.sql_database_sku == "GP_S_Gen5_1" ? 0.5 : null

  tags = var.tags
}

# Private DNS Zone for Search Service
resource "azurerm_private_dns_zone" "search" {
  name                = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Link Private DNS Zone to existing VNet for Search
resource "azurerm_private_dns_zone_virtual_network_link" "search" {
  name                  = "${azurecaf_name.search_service.result}-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.search.name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# Link Private DNS Zone to existing VNet for Storage
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "${azurecaf_name.storage_account.result}-blob-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# Link Private DNS Zone to existing VNet for SQL
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${azurecaf_name.sql_server.result}-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id

  tags = var.tags
}

# Private Endpoint for Azure AI Search
resource "azurerm_private_endpoint" "search" {
  name                = azurecaf_name.private_endpoint_search.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurecaf_name.search_service.result}-connection"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "search-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.search.id]
  }

  tags = var.tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = azurecaf_name.private_endpoint_storage.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurecaf_name.storage_account.result}-connection"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = var.tags
}

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql" {
  name                = azurecaf_name.private_endpoint_sql.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurecaf_name.sql_server.result}-connection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = var.tags
}

# Role assignment for AI Search to access Storage Account
resource "azurerm_role_assignment" "search_storage_blob_data_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_search_service.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Role assignment for User Assigned Identity to access Storage Account
resource "azurerm_role_assignment" "identity_storage_blob_data_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  principal_type       = "ServicePrincipal"
}

# Role assignment for AI Search to access SQL Database
resource "azurerm_role_assignment" "search_sql_reader" {
  scope                = azurerm_mssql_database.main.id
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_search_service.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${azurecaf_name.search_service.result}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Diagnostic settings for Search Service
resource "azurerm_monitor_diagnostic_setting" "search" {
  name                       = "${azurecaf_name.search_service.result}-diagnostics"
  target_resource_id         = azurerm_search_service.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "OperationLogs"
  }

  enabled_log {
    category = "SearchSlowLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${azurecaf_name.storage_account.result}-diagnostics"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  name                       = "${azurecaf_name.sql_database.result}-diagnostics"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "QueryStoreWaitStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_log {
    category = "DatabaseWaitStatistics"
  }

  enabled_log {
    category = "Timeouts"
  }

  enabled_log {
    category = "Blocks"
  }

  enabled_log {
    category = "Deadlocks"
  }

  metric {
    category = "AllMetrics"
  }
}
