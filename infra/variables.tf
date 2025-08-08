# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "East US"
}

# Networking Configuration
variable "vnet_id" {
  description = "ID of the existing Virtual Network"
  type        = string
}

variable "subnet_id" {
  description = "ID of the existing subnet for private endpoints"
  type        = string
}

# Azure AI Search Configuration
variable "search_sku" {
  description = "SKU for the Azure AI Search service"
  type        = string
  default     = "standard"
  validation {
    condition = contains([
      "free", "basic", "standard", "standard2", "standard3",
      "storage_optimized_l1", "storage_optimized_l2"
    ], var.search_sku)
    error_message = "The search_sku must be one of: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "search_replica_count" {
  description = "Number of replicas for the Azure AI Search service"
  type        = number
  default     = 1
  validation {
    condition     = var.search_replica_count >= 1 && var.search_replica_count <= 12
    error_message = "The search_replica_count must be between 1 and 12."
  }
}

variable "search_partition_count" {
  description = "Number of partitions for the Azure AI Search service"
  type        = number
  default     = 1
  validation {
    condition = contains([1, 2, 3, 4, 6, 12], var.search_partition_count)
    error_message = "The search_partition_count must be one of: 1, 2, 3, 4, 6, 12."
  }
}

variable "semantic_search_sku" {
  description = "Semantic search SKU for Azure AI Search"
  type        = string
  default     = "free"
  validation {
    condition = contains(["disabled", "free", "standard"], var.semantic_search_sku)
    error_message = "The semantic_search_sku must be one of: disabled, free, standard."
  }
}

# Storage Account Configuration
variable "storage_account_tier" {
  description = "Tier for the storage account"
  type        = string
  default     = "Standard"
  validation {
    condition = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The storage_account_tier must be either Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"
    ], var.storage_replication_type)
    error_message = "The storage_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

# SQL Server configuration
variable "sql_admin_username" {
  description = "The administrator username for the SQL Server"
  type        = string
  default     = "sqladmin"
  validation {
    condition     = length(var.sql_admin_username) >= 1 && length(var.sql_admin_username) <= 128
    error_message = "SQL admin username must be between 1 and 128 characters."
  }
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL Server"
  type        = string
  sensitive   = true
  validation {
    condition = length(var.sql_admin_password) >= 8 && length(var.sql_admin_password) <= 128 && can(regex("[a-z]", var.sql_admin_password)) && can(regex("[A-Z]", var.sql_admin_password)) && can(regex("[0-9]", var.sql_admin_password)) && can(regex("[@$!%*?&]", var.sql_admin_password))
    error_message = "SQL admin password must be 8-128 characters and contain at least one lowercase letter, one uppercase letter, one digit, and one special character (@$!%*?&)."
  }
}

variable "sql_database_sku" {
  description = "The SKU for the SQL Database"
  type        = string
  default     = "GP_S_Gen5_1"
  validation {
    condition = contains([
      "Basic", "S0", "S1", "S2", "S3", "S4", "S6", "S7", "S9", "S12",
      "P1", "P2", "P4", "P6", "P11", "P15",
      "GP_Gen4_1", "GP_Gen4_2", "GP_Gen4_3", "GP_Gen4_4", "GP_Gen4_5", "GP_Gen4_6", "GP_Gen4_7", "GP_Gen4_8", "GP_Gen4_9", "GP_Gen4_10", "GP_Gen4_16", "GP_Gen4_24",
      "GP_Gen5_2", "GP_Gen5_4", "GP_Gen5_6", "GP_Gen5_8", "GP_Gen5_10", "GP_Gen5_12", "GP_Gen5_14", "GP_Gen5_16", "GP_Gen5_18", "GP_Gen5_20", "GP_Gen5_24", "GP_Gen5_32", "GP_Gen5_40", "GP_Gen5_80",
      "GP_S_Gen5_1", "GP_S_Gen5_2", "GP_S_Gen5_4", "GP_S_Gen5_6", "GP_S_Gen5_8", "GP_S_Gen5_10", "GP_S_Gen5_12", "GP_S_Gen5_14", "GP_S_Gen5_16", "GP_S_Gen5_18", "GP_S_Gen5_20", "GP_S_Gen5_24", "GP_S_Gen5_32", "GP_S_Gen5_40",
      "BC_Gen4_1", "BC_Gen4_2", "BC_Gen4_3", "BC_Gen4_4", "BC_Gen4_5", "BC_Gen4_6", "BC_Gen4_7", "BC_Gen4_8", "BC_Gen4_9", "BC_Gen4_10", "BC_Gen4_16", "BC_Gen4_24",
      "BC_Gen5_2", "BC_Gen5_4", "BC_Gen5_6", "BC_Gen5_8", "BC_Gen5_10", "BC_Gen5_12", "BC_Gen5_14", "BC_Gen5_16", "BC_Gen5_18", "BC_Gen5_20", "BC_Gen5_24", "BC_Gen5_32", "BC_Gen5_40", "BC_Gen5_80"
    ], var.sql_database_sku)
    error_message = "Invalid SQL Database SKU. Please choose a valid SKU."
  }
}

# Resource Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default = {
    "environment"   = "development"
    "project"       = "ai-search-vector-index"
    "managed-by"    = "terraform"
  }
}
