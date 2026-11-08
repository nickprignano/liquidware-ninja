---
status: accepted
date: 2026-11-08
decision-makers: [maintainers]
---

# 0005. Bicep with pinned Azure Verified Modules alongside native Terraform (`~> 4.0`)

## Context and Problem Statement

The family's guardrails prefer Azure-native, GitHub, HashiCorp and open-source tooling. `avd-liquidware` deploys the ProfileUnity / FlexApp tier (`profileunity/`) and Stratusphere UX assessment appliances (`stratusphere/`) at subscription scope against an `avd-landing-zone` landing zone. Operators running from Azure Cloud Shell want zero-state Bicep by default, while Terraform operators across the family want HCL modules with full parameter, output, and security parity. Which infrastructure-as-code approach fits?

## Considered Options

- Bicep with pinned Azure Verified Modules (`bicep/`), following `avd-landing-zone`'s conventions
- Terraform with native `hashicorp/azurerm` (`~> 4.0`) resources (`terraform/`), matching `nerdio-hcl`
- Dual-engine (`-Engine Bicep|Terraform`) in the PowerShell entry points, keeping Bicep as the default and shipping native Terraform modules alongside it

## Decision Outcome

Chosen option: "Dual-engine (`-Engine Bicep|Terraform`): Bicep with Azure Verified Modules alongside native `hashicorp/azurerm` (`~> 4.0`) resources", because Bicep stays the zero-state Cloud Shell default while Terraform users get exact parameter, resource, role-assignment, and output parity tested offline with `terraform test` (`mock_provider "azurerm"`) and Pester static guards.

### Consequences

- Good, because Cloud Shell operators need no state backend (`-Engine Bicep`), and Terraform operators can run `profileunity/terraform/` and `stratusphere/terraform/` directly or via `-Engine Terraform`.
- Good, because using native `azurerm` resources (`~> 4.0`) rather than opaque module wrappers lets Pester and `terraform test` inspect every role assignment scope, NSG rule, and Marketplace `plan` block offline.
- Neutral, because Pester parity tests enforce that `variables.tf` and `outputs.tf` stay in lockstep with `main.bicep`.

## More Information

The Terraform choice for Nerdio is [nerdio-hcl 0001](https://github.com/nickprignano/nerdio-hcl/blob/main/docs/knowledge/decisions/0001-build-on-nerdio-provider.md).
