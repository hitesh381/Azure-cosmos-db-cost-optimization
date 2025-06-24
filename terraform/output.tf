output "function_app_name" {
  description = "Name of the deployed Azure Function"
  value       = azurerm_function_app.cold_data_proxy.name
}

output "function_app_url" {
  description = "URL endpoint for the Azure Function"
  value       = "https://${azurerm_function_app.cold_data_proxy.default_hostname}/api"
}

output "cosmosdb_account_endpoint" {
  description = "Cosmos DB endpoint URL"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "blob_container_url" {
  description = "URL to access the blob container (private)"
  value       = "https://${azurerm_storage_account.billing.name}.blob.core.windows.net/${azurerm_storage_container.cold_data.name}"
}
