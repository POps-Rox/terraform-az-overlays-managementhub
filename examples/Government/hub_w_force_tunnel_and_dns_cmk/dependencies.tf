# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#----------------------------------------------
# Log Analytics Workspace
#----------------------------------------------
data "azurerm_client_config" "root" {}

resource "azurerm_resource_group" "laws_rg" {
  name     = "laws-rg-${var.default_location}-${var.org_name}"
  location = var.default_location
}

resource "azurerm_log_analytics_workspace" "laws" {
  name                = "laws-${var.default_location}-${var.org_name}"
  location            = var.default_location
  resource_group_name = azurerm_resource_group.laws_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = "30"
}

resource "azurerm_key_vault" "shared" {
  name                            = "kv-${var.default_location}-${var.org_name}"
  location                        = var.default_location
  resource_group_name             = azurerm_resource_group.laws_rg.name
  tenant_id                       = data.azurerm_client_config.root.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  public_network_access_enabled   = true
  rbac_authorization_enabled      = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["136.227.250.187"]
    virtual_network_subnet_ids = [
      module.mod_vnet_hub.subnet_ids["default"].id
    ]
  }
}

resource "azurerm_key_vault_key" "cmk_for_storage_account" {
  name         = "cmk-for-storage-account"
  key_vault_id = azurerm_key_vault.shared.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

resource "azurerm_role_assignment" "deployment_user_kv_admin" {
  scope                = azurerm_key_vault.shared.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.root.object_id
}

resource "azurerm_role_assignment" "deployment_user_certificates" {
  scope                = azurerm_key_vault.shared.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.root.object_id
}

resource "azurerm_role_assignment" "deployment_user_secrets" {
  scope                = azurerm_key_vault.shared.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.root.object_id
}

resource "azurerm_role_assignment" "cmk_admin_customer_managed_key" {
  scope                = azurerm_key_vault.shared.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity.principal_id
}

# Create a User Assigned Identity for Azure Encryption
resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  location            = var.default_location
  resource_group_name = azurerm_resource_group.laws_rg.name
  name                = "hub-st-usi"
}
