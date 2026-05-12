# v1.0.0 - date

## [v2.1.0] - 2026-05-12

### Changed

Bumped all AVM modules to `azurerm` 4.x-compatible versions. This also lifts the temporary `azapi ~> 1.13` pin from v2.0.0 — the fleet target `azapi ~> 2.0` is now in effect everywhere (root and all six example `versions.tf`).

| File | Module | Old | New |
|---|---|---|---|
| `modules.management.hub.vnet.tf` | `avm-res-network-virtualnetwork` | 0.4.2 | **0.17.1** |
| `modules.management.hub.vnet.tf` | `avm-res-network-ddosprotectionplan` | 0.2.0 | **0.3.0** |
| `modules.management.hub.nsg.tf` | `avm-res-network-networksecuritygroup` | 0.2.0 | **0.5.1** |
| `modules.management.hub.storage.account.tf` | `avm-res-storage-storageaccount` | 0.2.7 | **0.7.0** |
| `modules.management.hub.fw.policy.tf` | `avm-res-network-firewallpolicy` (+ `rule_collection_groups`) | 0.3.1 | **0.3.4** |
| `modules.management.hub.fw.tf` / `modules.management.hub.snet.tf` / `modules.management.hub.bastion.tf` | `avm-res-network-virtualnetwork//modules/subnet` | 0.4.2 | **0.17.1** |
| `modules.management.hub.fw.tf` / `modules.management.hub.bastion.tf` | `avm-res-network-publicipaddress` | 0.1.2 | **0.2.1** |
| `modules.management.hub.bastion.tf` | `avm-res-network-bastionhost` | 0.3.0 | **0.4.0** (transitively required for `azurerm ~> 4.x`) |
| `examples/Government/hub_w_force_tunnel_and_dns_cmk/dependencies.tf` | `avm-res-keyvault-vault` | 0.9.1 | **0.10.2** |
| `modules.management.hub.dns.tf` (commented-out reference) | `avm-ptn-network-private-link-private-dns-zones` | 0.4.0 | **0.23.1** |

### Schema migration notes

* **`avm-res-network-virtualnetwork` 0.17.1** is an `azapi`-based rewrite:
  * `resource_group_name` removed → replaced by `parent_id` (resource-group ARM ID). A new local `local.resource_group_id` was added in `locals.naming.tf` to source this.
  * Subnet sub-module `virtual_network = { resource_id = … }` removed → replaced by `parent_id = module.hub_vnet.resource_id`.
  * Subnet sub-module `service_endpoints = list(string)` removed → replaced by `service_endpoints_with_location = list(object({ service, locations }))`. Consumer-supplied lists are now wrapped into the new object shape.
  * Output schema changed: `module.hub_vnet.resource.body.properties.addressSpace.addressPrefixes` → `module.hub_vnet.address_spaces`; per-subnet `resource.body.properties.addressPrefixes` → `address_prefixes`. `outputs.tf` updated to match.

* **`avm-res-storage-storageaccount` 0.7.0** is an `azapi`-based rewrite (the v1.0.0 rewrite):
  * `resource_group_name` removed → replaced by `parent_id`.
  * `blob_properties` input removed entirely. The 30-day `container_delete_retention_policy` / `delete_retention_policy` block previously configured in `modules.management.hub.storage.account.tf` has been removed; a comment in the file records the recommended replacement (a downstream `Microsoft.Storage/storageAccounts/blobServices@2024-01-01` `azapi_resource`). **This is a behavioural change** — consumers relying on the 30-day retention defaults must declare it themselves.
  * `module.hub_vnet_ddos[0].resource.id` is now exposed as `resource_id`; `outputs.tf` and `modules.management.hub.vnet.tf` updated.

* **`avm-res-network-networksecuritygroup` 0.5.1**: input shape for `security_rules` is unchanged (still a `map(object({…}))` keyed off the same fields). No call-site changes other than the `version` bump.

* **`avm-res-network-bastionhost` 0.4.0**: bumped to lift the transitive `azurerm ~> 3.105` pin from 0.3.0. Inputs unchanged (`resource_group_name`, `ip_configuration = { name, subnet_id, public_ip_address_id }`).

### Known gaps (intentional)

* `examples/Commerical/hub_w_force_tunnel_ddos_encrypted_transport/main.tf` calls `module "mod_vnet_hub"` with `depends_on = [azurerm_log_analytics_workspace.laws]`. Because the root module declares a `provider "azapi"` block, Terraform treats it as a legacy module and rejects `count`/`for_each`/`depends_on` on its callers. **This error already exists on `main` (`v2.0.0`)** — it is not a regression from this bump. Fixing it requires either removing the `provider "azapi"` block from the root or removing the `depends_on` from that example; both are out of scope for an AVM-version bump.

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
