# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Azure AI Search Outputs
output "search_service_name" {
  description = "Name of the Azure AI Search service"
  value       = azurerm_search_service.main.name
}

output "search_service_id" {
  description = "ID of the Azure AI Search service"
  value       = azurerm_search_service.main.id
}

output "search_service_url" {
  description = "URL of the Azure AI Search service"
  value       = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "search_service_identity_principal_id" {
  description = "Principal ID of the Azure AI Search service system assigned identity"
  value       = azurerm_search_service.main.identity[0].principal_id
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_container_name" {
  description = "Name of the storage container for documents"
  value       = azurerm_storage_container.documents.name
}

# User Assigned Identity Outputs
output "user_assigned_identity_id" {
  description = "ID of the user assigned managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the user assigned managed identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the user assigned managed identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

# Private Endpoint Outputs
output "search_private_endpoint_id" {
  description = "ID of the Azure AI Search private endpoint"
  value       = azurerm_private_endpoint.search.id
}

output "storage_private_endpoint_id" {
  description = "ID of the storage account private endpoint"
  value       = azurerm_private_endpoint.storage.id
}

# Log Analytics Workspace Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Private DNS Zone Outputs
output "search_private_dns_zone_id" {
  description = "ID of the Azure AI Search private DNS zone"
  value       = azurerm_private_dns_zone.search.id
}

output "storage_private_dns_zone_id" {
  description = "ID of the storage account private DNS zone"
  value       = azurerm_private_dns_zone.storage_blob.id
}

# SQL Server outputs
output "sql_server_name" {
  description = "The name of the SQL Server"
  value       = azurerm_mssql_server.main.name
}

output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "sql_database_id" {
  description = "The ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
}

output "sql_server_identity_principal_id" {
  description = "The principal ID of the SQL Server system assigned identity"
  value       = azurerm_mssql_server.main.identity[0].principal_id
}
