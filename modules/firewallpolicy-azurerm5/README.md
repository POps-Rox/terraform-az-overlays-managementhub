# Vendored avm-res-network-firewallpolicy module for azurerm 5.x

This directory vendors `Azure/avm-res-network-firewallpolicy/azurerm` from upstream repository `Azure/terraform-azurerm-avm-res-network-firewallpolicy`, version `v0.3.4`.
It exists because the upstream release currently constrains `azurerm` to `>= 3.71, < 5.0.0`, which is incompatible with this repository's root provider constraint of `>= 5.0, < 6.0`.

The upstream module is redistributed under the upstream MIT License, Copyright (c) Microsoft Corporation. The upstream `LICENSE` file is retained unchanged in this directory. This copy has been modified by POps-Rox.

## Changes from upstream v0.3.4

The following list was produced after running `diff -ru` against the upstream tag vendored here.

1. `terraform.tf`
   - `terraform.required_version`: upstream `~> 1.5` → vendored `>= 1.10`.
2. `terraform.tf`
   - `required_providers.azurerm.version`: upstream `>= 3.71, < 5.0.0` → vendored `>= 5.0, < 6.0`.
3. `modules/rule_collection_groups/terraform.tf`
   - `terraform.required_version`: upstream `~> 1.5` → vendored `>= 1.10`.
4. `modules/rule_collection_groups/terraform.tf`
   - `required_providers.azurerm.version`: upstream `>= 3.71, < 5.0.0` → vendored `>= 5.0, < 6.0`.
5. `main.tf`
   - `azurerm_monitor_diagnostic_setting.this for_each`: upstream `var.diagnostic_settings` → vendored `filtered map excluding entries with zero log categories, log groups, and metric categories`.
6. `main.tf`
   - `azurerm_monitor_diagnostic_setting.this dynamic block`: upstream `metric { category = metric.value }` → vendored `enabled_metric { category = enabled_metric.value }`.
7. Vendored packaging
   - Added `NOTICE` documenting upstream source, version, retrieval date, license, and POps-Rox modifications.
   - Replaced the upstream registry README with this provenance-focused README.
   - Omitted upstream ancillary repository files that are not used by this vendored module, including CI configuration, examples, tests, generated documentation fragments, and support/contribution docs. Terraform source files and the upstream `LICENSE` are retained.

No other Terraform source changes were made relative to the upstream tag.

## Maintenance

This vendored copy receives no Dependabot coverage. Upstream changes must be tracked manually.

Tracking issue: [POps-Rox/.github#27](https://github.com/POps-Rox/.github/issues/27). Delete this vendored copy and return to the registry module source once upstream supports azurerm 5.x.
