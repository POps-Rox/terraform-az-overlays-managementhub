# v1.0.0 - date

## [v2.0.0] - 2026-05-11

### Breaking changes

* Upgraded to `azurerm` provider `~> 4.20` (previously `>= 3.7.0, < 4.0`).
* Raised Terraform CLI floor from `>= 1.9.2` to `>= 1.10`.
* Consumers must set `ARM_SUBSCRIPTION_ID` (azurerm 4.x makes `subscription_id` required for the `azurerm` provider).

### Notes — `azapi` constraint kept at `~> 1.13`

The fleet-wide target was `azapi ~> 2.0`, **but the transitive AVM dependency `azure/avm-res-network-virtualnetwork/azurerm@0.4.2` declares `azapi < 2.0.0`** and uses the legacy `body = jsonencode(...)` shape that azapi 2.x rejects. Bumping the AVM module to `0.17.1+` (which supports azapi 2.x) is out of scope for the provider upgrade and is tracked as Phase 2 work.

### Audited (no change needed)

* `azurerm_network_watcher_flow_log.retention_policy { … }` block — **still valid in 4.x** (per the 4.72 docs). Kept as-is.
* `azurerm_storage_account` `container_delete_retention_policy` / `delete_retention_policy` — these are module inputs to the sibling `-storageaccount` overlay (a map passed into `blob_properties`), not direct azurerm attributes. Kept as-is.
* `private_endpoint_network_policies_enabled` variables and resource args — already migrated in a prior maintenance pass; firewall/subnet resources use the 4.x name `private_endpoint_network_policies` and variables are `string` type with `"Disabled"`/`"Enabled"` defaults. One example (`hub_w_force_tunnel_ddos_encrypted_transport/variables.tf`) still types it as `bool` — that's pre-existing inconsistency, intentionally left alone.

### Example versions.tf
Every example previously declared only a bare `provider "azurerm" {}` block with no `terraform { required_providers {} }`. All six now declare the full fleet-pinned provider set (`azurerm ~> 4.20`, `azapi ~> 1.13`, `popsrox ~> 1.0`, `random ~> 3.1`).


Added

- Add Something you added
