provider "azurerm" {
  features {}
}

#---------------------------#
# 1. Resource Group
#---------------------------#
resource "azurerm_resource_group" "main" {
  name     = "rg-billing-data"
  location = "East US"
}

#---------------------------#
# 2. Storage Account (Blob)
#---------------------------#
resource "azurerm_storage_account" "billing" {
  name                     = "billingdataarchivest"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "cold_data" {
  name                  = "cold-billing-archive"
  storage_account_name  = azurerm_storage_account.billing.name
  container_access_type = "private"
}

#---------------------------#
# 3. Cosmos DB
#---------------------------#
resource "azurerm_cosmosdb_account" "main" {
  name                = "billing-cosmos-account"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "billing" {
  name                = "billing-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

resource "azurerm_cosmosdb_sql_container" "records" {
  name                = "billing-records"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.billing.name
  partition_key_path  = "/id"
  throughput          = 400
}

#---------------------------#
# 4. Azure Function App
#---------------------------#
resource "azurerm_storage_account" "function" {
  name                     = "billingfuncst"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "function" {
  name                = "billing-func-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "cold_data_proxy" {
  name                       = "billing-cold-data-func"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.function.id
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  version                    = "~4"
  os_type                    = "linux"
  runtime_stack              = "python"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    COSMOS_ENDPOINT          = azurerm_cosmosdb_account.main.endpoint
    COSMOS_KEY               = azurerm_cosmosdb_account.main.primary_master_key
    COSMOS_DB                = azurerm_cosmosdb_sql_database.billing.name
    COSMOS_CONTAINER         = azurerm_cosmosdb_sql_container.records.name
    BLOB_CONN_STR            = azurerm_storage_account.billing.primary_connection_string
    BLOB_CONTAINER           = azurerm_storage_container.cold_data.name
  }
}

output "function_endpoint" {
  value = azurerm_function_app.cold_data_proxy.default_hostname
}
