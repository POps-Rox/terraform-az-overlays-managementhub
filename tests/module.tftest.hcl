# Functional tests for the management hub overlay.
#
# These use mock_provider, so they execute WITHOUT Azure credentials. The tests
# exercise module decision logic that terraform validate cannot prove: custom
# naming precedence and empty-string fallthrough, feature branching, tag merging,
# location passthrough, and firewall/bastion/DDoS route behavior.

mock_provider "azapi" {
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            role_name = "Network Contributor"
            id        = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000005"
          }
        ]
      }
    }
  }
}
mock_provider "random" {}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generatedname"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }

  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-test"
      name     = "rg-test"
      location = "eastus"
    }
  }

  mock_data "azurerm_network_watcher" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_eastus"
      name                = "NetworkWatcher_eastus"
      resource_group_name = "NetworkWatcherRG"
      location            = "eastus"
    }
  }
}

variables {
  location                     = "eastus"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "hub"
  org_name                     = "anoa"
  create_hub_resource_group    = false
  existing_resource_group_name = "rg-test"
  enable_firewall              = false
  enable_forced_tunneling      = false
  enable_private_dns_zones     = false

  virtual_network_address_space = ["10.10.0.0/16"]
  hub_subnets = {
    default = {
      name                                       = "default"
      address_prefixes                           = ["10.10.1.0/24"]
      service_endpoints                          = []
      private_endpoint_network_policies_enabled  = "Enabled"
      private_endpoint_service_endpoints_enabled = true
      nsg_subnet_rules                           = {}
    }
  }
}

run "generated_names_are_used_when_no_custom_names_are_given" {
  command = plan

  assert {
    condition     = local.hub_vnet_name == "generatedname"
    error_message = "Expected generated VNet name when hub_vnet_custom_name is unset, got: ${local.hub_vnet_name}"
  }

  assert {
    condition     = local.bastion_name == "generatedname"
    error_message = "Expected generated Bastion name when bastion_custom_name is unset, got: ${local.bastion_name}"
  }
}

run "custom_names_override_generated_names" {
  command = plan

  variables {
    hub_vnet_custom_name            = "explicit-vnet"
    hub_firewall_custom_name        = "explicit-fw"
    hub_firewall_policy_custom_name = "explicit-fw-policy"
    bastion_custom_name             = "explicit-bastion"
    ddos_plan_custom_name           = "explicit-ddos"
  }

  assert {
    condition     = local.hub_vnet_name == "explicit-vnet"
    error_message = "hub_vnet_custom_name must take precedence over generated name, got: ${local.hub_vnet_name}"
  }

  assert {
    condition     = local.hub_firewall_name == "explicit-fw"
    error_message = "hub_firewall_custom_name must take precedence over generated name, got: ${local.hub_firewall_name}"
  }

  assert {
    condition     = local.hub_firewall_policy_name == "explicit-fw-policy"
    error_message = "hub_firewall_policy_custom_name must take precedence over generated name, got: ${local.hub_firewall_policy_name}"
  }

  assert {
    condition     = local.bastion_name == "explicit-bastion"
    error_message = "bastion_custom_name must take precedence over generated name, got: ${local.bastion_name}"
  }

  assert {
    condition     = local.ddos_plan_name == "explicit-ddos"
    error_message = "ddos_plan_custom_name must take precedence over generated name, got: ${local.ddos_plan_name}"
  }
}

run "empty_custom_names_fall_through_to_generated_names" {
  command = plan

  variables {
    hub_vnet_custom_name            = ""
    hub_firewall_custom_name        = ""
    hub_firewall_policy_custom_name = ""
    bastion_custom_name             = ""
    ddos_plan_custom_name           = ""
  }

  assert {
    condition     = local.hub_vnet_name == "generatedname"
    error_message = "An empty hub_vnet_custom_name must fall through to the generated name, got: ${local.hub_vnet_name}"
  }

  assert {
    condition     = local.hub_firewall_name == "generatedname"
    error_message = "An empty hub_firewall_custom_name must fall through to the generated name, got: ${local.hub_firewall_name}"
  }

  assert {
    condition     = local.hub_firewall_policy_name == "generatedname"
    error_message = "An empty hub_firewall_policy_custom_name must fall through to the generated name, got: ${local.hub_firewall_policy_name}"
  }

  assert {
    condition     = local.bastion_name == "generatedname"
    error_message = "An empty bastion_custom_name must fall through to the generated name, got: ${local.bastion_name}"
  }

  assert {
    condition     = local.ddos_plan_name == "generatedname"
    error_message = "An empty ddos_plan_custom_name must fall through to the generated name, got: ${local.ddos_plan_name}"
  }
}

run "optional_network_features_are_disabled_by_default" {
  command = plan

  assert {
    condition     = length(module.hub_bastion_host) == 0 && length(module.hub_bastion_pip) == 0
    error_message = "Bastion modules must not be planned when enable_bastion_host is false."
  }

  assert {
    condition     = length(module.hub_fw) == 0 && length(module.hub_firewall_policy) == 0 && length(azurerm_route.force_internet_tunneling) == 0
    error_message = "Firewall modules and forced-tunnel route must not be planned when enable_firewall is false."
  }

  assert {
    condition     = length(module.hub_vnet_ddos) == 0
    error_message = "DDoS protection plan must not be planned when create_ddos_plan is false."
  }
}

run "bastion_branch_creates_bastion_resources" {
  command = plan

  variables {
    enable_bastion_host                 = true
    azure_bastion_subnet_address_prefix = ["10.10.10.0/27"]
  }

  assert {
    condition     = length(module.abs_snet) == 1 && length(module.hub_bastion_pip) == 1 && length(module.hub_bastion_host) == 1
    error_message = "enable_bastion_host must create the Bastion subnet, public IP, and Bastion host modules."
  }
}

run "firewall_branch_creates_firewall_without_forced_tunnel_route" {
  command = plan

  variables {
    enable_firewall                = true
    enable_forced_tunneling        = false
    firewall_subnet_address_prefix = ["10.10.2.0/26"]
  }

  assert {
    condition     = length(module.firewall_client_snet) == 1 && length(module.hub_firewall_client_pip) == 1 && length(module.hub_firewall_policy) == 1 && length(module.hub_fw) == 1
    error_message = "enable_firewall must create firewall subnet, public IP, policy, and firewall modules."
  }

  assert {
    condition     = length(module.firewall_management_snet) == 0 && length(module.hub_firewall_management_pip) == 0 && length(azurerm_route.force_internet_tunneling) == 0
    error_message = "Forced tunneling resources must not be planned unless enable_forced_tunneling is true."
  }
}

run "forced_tunneling_adds_management_path_and_default_route" {
  command = plan

  variables {
    enable_firewall         = true
    enable_forced_tunneling = true
  }

  assert {
    condition     = length(module.firewall_management_snet) == 1 && length(module.hub_firewall_management_pip) == 1 && length(azurerm_route.force_internet_tunneling) == 1
    error_message = "enable_forced_tunneling must add management subnet, management public IP, and default route."
  }

  assert {
    condition     = azurerm_route.force_internet_tunneling[0].address_prefix == "0.0.0.0/0"
    error_message = "Forced tunneling route must target 0.0.0.0/0."
  }
}

run "ddos_branch_creates_plan_and_attaches_to_vnet" {
  command = plan

  variables {
    create_ddos_plan = true
  }

  assert {
    condition     = length(module.hub_vnet_ddos) == 1
    error_message = "create_ddos_plan must create exactly one DDoS protection plan module."
  }

  assert {
    condition     = local.ddos_plan_name == "generatedname"
    error_message = "create_ddos_plan must use the generated DDoS plan name when no custom name is supplied."
  }
}

run "tags_and_location_are_passed_through" {
  command = plan

  variables {
    add_tags = {
      costCenter = "cc-1234"
    }
  }

  assert {
    condition     = azurerm_route_table.routetable.tags["costCenter"] == "cc-1234"
    error_message = "Tags passed via add_tags must appear on native route table resources."
  }

  assert {
    condition     = azurerm_route_table.routetable.location == "eastus"
    error_message = "The data/resource-group location must be passed through to native resources."
  }
}
