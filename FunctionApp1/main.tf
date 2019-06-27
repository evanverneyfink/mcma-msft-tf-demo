
provider "azurerm" {
  client_id       = "ab79c9dd-e3b8-4fa0-929f-aa1670567e98"
  client_secret   = "4OKofLOApxcQprCKtdHBoNybDdMhISjaT1IM+riWADQ="
  tenant_id       = "40e1b75f-bb2f-4862-b34e-2d990ae2d92a"
  subscription_id = "79d21867-c847-4bb1-ac8d-9d9883a6a542"
}

resource "azurerm_resource_group" "msft-tf-demo-rg" {
  name     = "msft-tf-demo-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "msft-tf-demo-sa" {
  name                     = "msfttfdemosa"
  resource_group_name      = "${azurerm_resource_group.msft-tf-demo-rg.name}"
  location                 = "${azurerm_resource_group.msft-tf-demo-rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "msft-tf-demo-sc" {
 name = "func"
 resource_group_name = "${azurerm_resource_group.msft-tf-demo-rg.name}"
 storage_account_name = "${azurerm_storage_account.msft-tf-demo-sa.name}"
 container_access_type = "private"
}

resource "azurerm_storage_blob" "msft-tf-demo-sb" {
 name = "MsftTfDemoFunction.zip"
 resource_group_name = "${azurerm_resource_group.msft-tf-demo-rg.name}"
 storage_account_name = "${azurerm_storage_account.msft-tf-demo-sa.name}"
 storage_container_name = "${azurerm_storage_container.msft-tf-demo-sc.name}"
 type = "block"
 source = "./bin/debug/netstandard2.0/publish/MsftTfDemoFunction.zip"
}

data "azurerm_storage_account_sas" "storage_sas" {
 connection_string = "${azurerm_storage_account.msft-tf-demo-sa.primary_connection_string}"
 https_only = false

resource_types {
 service = false
 container = false
 object = true
 }

services {
 blob = true
 queue = false
 table = false
 file = false
 }

start = "2019–03–21"
 expiry = "2020–03–21"

permissions {
 read = true
 write = false
 delete = false
 list = false
 add = false
 create = false
 update = false
 process = false
 }
}

resource "azurerm_app_service_plan" "msft-tf-demo-sp" {
  name                = "msft-tf-demo-service-plan"
  location            = "${azurerm_resource_group.msft-tf-demo-rg.location}"
  resource_group_name = "${azurerm_resource_group.msft-tf-demo-rg.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "msft-tf-demo-func" {
  name                      = "msft-tf-demo-func"
  location                  = "${azurerm_resource_group.msft-tf-demo-rg.location}"
  resource_group_name       = "${azurerm_resource_group.msft-tf-demo-rg.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.msft-tf-demo-sp.id}"
  storage_connection_string = "${azurerm_storage_account.msft-tf-demo-sa.primary_connection_string}"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    FUNCTION_APP_EDIT_MODE = "readonly"
    https_only = true

    HASH = "${filebase64sha256("./bin/debug/netstandard2.0/publish/MsftTfDemoFunction.zip")}"
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.msft-tf-demo-sa.name}.blob.core.windows.net/${azurerm_storage_container.msft-tf-demo-sc.name}/${azurerm_storage_blob.msft-tf-demo-sb.name}${data.azurerm_storage_account_sas.storage_sas.sas})}"
  }
}