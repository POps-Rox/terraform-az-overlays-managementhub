# Vendored avm-res-network-virtualnetwork module for azurerm 5.x

This directory vendors `Azure/avm-res-network-virtualnetwork/azurerm` from upstream repository `Azure/terraform-azurerm-avm-res-network-virtualnetwork`, version `v0.17.1`. It exists because the upstream release used by this repository constrained `azurerm` to `~> 4.0`, which is incompatible with this repository's root provider constraint of `>= 5.0, < 6.0`.

The upstream module is redistributed under the upstream MIT License, Copyright (c) Microsoft Corporation. The upstream `LICENSE` file is retained unchanged in this directory. This copy has been modified by POps-Rox.

## Changes from upstream v0.17.1

The following list was produced after running `diff -ru` against the upstream tag vendored here.

1. `terraform.tf`
   - `terraform.required_version`: upstream `>= 1.9, < 2.0` → vendored `>= 1.10`.
   - `required_providers.azurerm.version`: upstream `~> 4.0` → vendored `>= 5.0, < 6.0`.

2. `modules/peering/terraform.tf`
   - `terraform.required_version`: upstream `>= 1.9, < 2.0` → vendored `>= 1.10`.
   - `required_providers.azurerm.version`: upstream `~> 4.0` → vendored `>= 5.0, < 6.0`.

3. `modules/subnet/terraform.tf`
   - `terraform.required_version`: upstream `>= 1.9, < 2.0` → vendored `>= 1.10`.
   - `required_providers.azurerm.version`: upstream `~> 4.0` → vendored `>= 5.0, < 6.0`.

4. Vendored packaging
   - Added `NOTICE` documenting upstream source, version, retrieval date, license, and POps-Rox modifications.
   - Replaced the upstream registry README with this provenance-focused README.
   - Omitted upstream ancillary repository files that are not used by this vendored module, including CI configuration, examples, tests, generated documentation fragments, and support/contribution docs. Terraform source files and the upstream `LICENSE` are retained.

No other Terraform source changes were made relative to upstream `v0.17.1`.

## Maintenance

This vendored copy receives no Dependabot coverage. Upstream changes must be tracked manually.

Tracking issue: [POps-Rox/.github#27](https://github.com/POps-Rox/.github/issues/27). Delete this vendored copy and return to the registry module source once upstream supports azurerm 5.x and the repository's Terraform 1.10 baseline.
