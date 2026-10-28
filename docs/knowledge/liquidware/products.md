---
title: "Liquidware products and where they're documented"
summary: "Which Liquidware products this KB covers, how our repos divide the work, and where Liquidware publishes docs, support articles and news"
topic: liquidware
status: verified
last_reviewed: 2026-10-28
---

# Liquidware products and where they're documented

This knowledge base (`liquidware-ninja`) is the central second brain for all four **Liquidware** products across virtual and physical desktops, backing both [`avd-liquidware`](https://github.com/nickprignano/avd-liquidware) (Azure / AVD deployment automation) and [`ux-assess`](https://github.com/nickprignano/ux-assess) (Stratusphere UX assessment and deliverable automation).

| Product | What it does | Covered here |
|---|---|---|
| **Stratusphere UX** | Monitoring, SpotCheck diagnostics, right-sizing, and migration baselining of desktop user experience (Hub, Database, Collector appliances + Connector ID Key agent) | [Appliances](../stratusphere/appliances.md) · [Connector ID Key](../stratusphere/connector-id-key.md) · [Hub setup](../stratusphere/hub-setup.md) · [API](../stratusphere/api.md) · [SpotCheck & sizing](../stratusphere/spotcheck-and-sizing.md) |
| **ProfileUnity** | User environment management (UEM), contextual policy, privilege elevation, application restrictions, and Profile Portability | [Architecture & Portability](../profileunity/architecture-and-portability.md) · [Fit with AVD & FSLogix](../avd/fit-with-avd-and-fslogix.md) |
| **FlexApp** | Elastic application layering (VHDX, CimFS, FlexApp One) delivered natively or via Azure Virtual Desktop App Attach | [Packaging & delivery](../flexapp/packaging-and-delivery.md) · [Fit with AVD & FSLogix](../avd/fit-with-avd-and-fslogix.md) |
| **CommandCTRL** | SaaS real-time endpoint diagnostics, helpdesk triage, and remote support | [CommandCTRL overview](../commandctrl/overview.md) · [Fit with AVD & FSLogix](../avd/fit-with-avd-and-fslogix.md) |

For how the four products behave across Physical PCs, Citrix CVAD/DaaS, Omnissa Horizon, Windows Server RDS, Azure Virtual Desktop, and Windows 365, see [platforms/multi-platform-matrix.md](../platforms/multi-platform-matrix.md).

## Templates, toolkit, and field notes in this repo

Alongside the knowledge base, `liquidware-ninja` ships:

- **Templates (`templates/`):** FSLogix Portability coexistence guardrails (`profileunity/fslogix-portability-guardrails.json`), plain-text ProfileUnity configuration exports (`profileunity/sample-config-export.json`), FlexApp package manifests (`flexapp/flexapp-package.example.json`), Stratusphere Inspector and SpotCheck catalogs (`stratusphere/inspector-catalog.json`), and CommandCTRL multi-session security/privacy baselines (`commandctrl/multisession-baseline.json`).
- **PowerShell toolkit (`scripts/tools/`):** `LiquidwareNinja.psm1` (`Test-LwPortabilityOverlap`, `Export-LwPortabilityRuleset`, `Compare-LwProfileUnityConfig`, `Test-LwFlexAppCandidate`, `New-LwFlexAppManifest`, `Get-LwAssignmentConflict`, `Get-LwSpotCheckThreshold`, `ConvertTo-LwApiUrl`, `Test-LwCommandCtrlBaseline`) and `Test-LwCidKeyHealth.ps1` (PS 5.1/7+ endpoint health check for the Stratusphere Connector ID Key).
- **Technical blog & field notes (`blog/`):** Deep-dive engineering write-ups covering Entra-only AVD without storage keys, Stratusphere UX SpotCheck to git-backed Power BI PBIP/TMDL pipelines, and Windows Server RDS to Windows 11 multi-session Portability migrations.

## Where Liquidware publishes

- **Product documentation:** [docs.liquidware.com](https://docs.liquidware.com). The site renders in the browser and has no RSS feed, so the curator can't watch it automatically; check it by hand when a page here depends on it.
- **Release notes:** published per product and version in the documentation site and as "Product Releases" articles in the support center, which the curator watches.
- **Support center:** [support.liquidware.com](https://support.liquidware.com), a Zendesk help center covering every product, with Stratusphere, ProfileUnity, FlexApp, and CommandCTRL sections. The curator watches it through Zendesk's article API. The HTML site blocks automated requests; the API doesn't.
- **News and blog:** the RSS feed at `https://www.liquidware.com/rss.xml`, watched by the curator. The usual `/feed` paths return 404.
- **Azure Marketplace:** the `liquidware` publisher's `stratusphere` offer ([azure/marketplace.md](../azure/marketplace.md)). No feed; check by hand.
- **GitHub:** the [liquidwarelabs](https://github.com/liquidwarelabs) organization ([community-projects.md](community-projects.md)).
