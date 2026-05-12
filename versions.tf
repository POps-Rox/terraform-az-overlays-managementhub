# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_version = ">= 1.10"
  required_providers {
    # NOTE: pinned to azapi 1.x (not the fleet target of ~> 2.0) because the
    # transitive AVM module `azure/avm-res-network-virtualnetwork/azurerm@0.4.2`
    # declares `azapi < 2.0.0`. Bumping AVM to 0.17.1+ would lift this constraint
    # but is out of scope for the provider upgrade — track as Phase 2 work.
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
    popsrox = {
      source  = "POps-Rox/azutils"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# workaround for AVM-Resource module
provider "azapi" {
  environment = var.environment
}
