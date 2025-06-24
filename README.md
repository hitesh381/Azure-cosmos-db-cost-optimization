# Terraform + GitHub Style Layout for Cost-Optimized Cosmos DB Archival

## 📁 Project Structure
```
.
├── terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf (optional)
└── azure-functions
    └── fetch_billing_record
        ├── __init__.py
        ├── function.json
        └── requirements.txt
```

---

## 📂 terraform/main.tf
<Insert the previously provided full Terraform configuration here>

---

## 📂 azure-functions/fetch_billing_record/__init__.py
```python
import logging
import azure.functions as func
import os
import json
from azure.cosmos import CosmosClient, exceptions
from azure.storage.blob import BlobServiceClient

# Cosmos DB
COSMOS_ENDPOINT = os.environ["COSMOS_ENDPOINT"]
COSMOS_KEY = os.environ["COSMOS_KEY"]
DATABASE_NAME = os.environ["COSMOS_DB"]
CONTAINER_NAME = os.environ["COSMOS_CONTAINER"]

# Blob
BLOB_CONN_STR = os.environ["BLOB_CONN_STR"]
BLOB_CONTAINER = os.environ["BLOB_CONTAINER"]

client = CosmosClient(COSMOS_ENDPOINT, COSMOS_KEY)
container = client.get_database_client(DATABASE_NAME).get_container_client(CONTAINER_NAME)
blob_service_client = BlobServiceClient.from_connection_string(BLOB_CONN_STR)
blob_container_client = blob_service_client.get_container_client(BLOB_CONTAINER)

def get_record_from_blob(record_id):
    try:
        blob_path = f"cold_data/{record_id}.json"
        blob_client = blob_container_client.get_blob_client(blob_path)
        content = blob_client.download_blob().readall()
        return json.loads(content)
    except Exception as e:
        logging.error(f"Blob fallback failed: {e}")
        return None

def main(req: func.HttpRequest) -> func.HttpResponse:
    record_id = req.route_params.get("id")
    if not record_id:
        return func.HttpResponse("Missing ID", status_code=400)

    try:
        item = container.read_item(item=record_id, partition_key=record_id)
        return func.HttpResponse(json.dumps(item), status_code=200, mimetype="application/json")
    except exceptions.CosmosResourceNotFoundError:
        record = get_record_from_blob(record_id)
        if record:
            return func.HttpResponse(json.dumps(record), status_code=200, mimetype="application/json")
        return func.HttpResponse("Record not found", status_code=404)
```

---

## 📂 azure-functions/fetch_billing_record/function.json
```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "route": "billing/{id}",
      "methods": ["get"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```

---

## 📂 azure-functions/fetch_billing_record/requirements.txt
```
azure-functions
azure-cosmos
azure-storage-blob
```

---

## ✅ Next Steps
- `cd terraform && terraform init && terraform apply`
- Deploy the function via VSCode or Azure CLI:
```bash
cd azure-functions/fetch_billing_record
func azure functionapp publish billing-cold-data-func
```
- Point your API Gateway to use this Function as fallback or primary handler.
