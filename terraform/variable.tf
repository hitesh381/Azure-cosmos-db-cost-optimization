variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-billing-data"
}

variable "storage_account_name" {
  description = "Unique name for the Blob Storage account"
  type        = string
  default     = "billingdataarchivest"
}

variable "function_storage_account" {
  description = "Unique name for Function App storage"
  type        = string
  default     = "billingfuncst"
}

variable "cosmos_account_name" {
  description = "Name of the Cosmos DB account"
  type        = string
  default     = "billing-cosmos-account"
}

variable "cosmos_database_name" {
  description = "Cosmos DB database name"
  type        = string
  default     = "billing-db"
}

variable "cosmos_container_name" {
  description = "Cosmos DB container name"
  type        = string
  default     = "billing-records"
}

variable "blob_container_name" {
  description = "Blob container to archive cold billing records"
  type        = string
  default     = "cold-billing-archive"
}
