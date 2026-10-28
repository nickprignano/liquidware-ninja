# liquidware-ninja

Part of [avd-ops](https://avd-ops.dev/), the open toolkit for Azure Virtual Desktop.

The **Liquidware second brain** and general catchall repository: a living knowledge base, architecture reference, technical blog, template library, and utility toolkit for running **Liquidware** products (**Stratusphere UX**, **ProfileUnity**, **FlexApp**, and **CommandCTRL**) across virtual and physical desktops (Azure Virtual Desktop, Windows 365, Citrix, Omnissa Horizon, RDS, and physical PCs).

> [!WARNING]
> **Personal project. Research and learning only. Not for production. No warranty.**
>
> - This is my own personal project, built on my own time **for research and learning**. It is **not affiliated with, endorsed by or supported by my employer**, and it does not represent my employer's views, products or guidance.
> - It is **not affiliated with or endorsed by Liquidware** or Microsoft. Bring your own Liquidware licenses. Liquidware, ProfileUnity, FlexApp, Stratusphere and CommandCTRL are trademarks of Liquidware Labs, Inc.; Azure, Microsoft Entra, Intune and FSLogix are trademarks of Microsoft.
> - **Do not run it in production** or against subscriptions and tenants that matter. Test it first in a dedicated lab environment.
> - It is provided **"as is", without warranty of any kind**, under the [MIT License](LICENSE), with the knowledge base tooling under Apache-2.0 (see [License](#license)). You use it at your own risk.
> - **Contributions and forks are welcome and encouraged.** See [Contributing](#contributing).

## How the Liquidware repositories fit together

| Repository | Role | Scope |
|---|---|---|
| **[liquidware-ninja](https://github.com/nickprignano/liquidware-ninja)** *(this repo)* | **The why and the reference (Second Brain & Toolkit)** | Living 2ndbrain knowledge base across all Liquidware products and platforms, technical field notes (`blog/`), reusable templates (`templates/`), and cross-platform PowerShell utilities (`scripts/tools/`) |
| **[avd-liquidware](https://github.com/nickprignano/avd-liquidware)** | **The Azure / AVD deployment tier** | Bicep and PowerShell to deploy Stratusphere UX appliances, Connector ID Key rollouts, ProfileUnity consoles/clients, and FlexApp App Attach against an [avd-landing-zone](https://github.com/avd-ops/avd-landing-zone) estate |
| **[ux-assess](https://github.com/nickprignano/ux-assess)** | **The Stratusphere UX assessment & deliverable pipeline** | Platform-agnostic Hub API exporter, canonical dataset normalizer, HMAC pseudonymizer, SpotCheck analyzer, and multi-format deliverable generator (`.xlsx`, `.pdf`, `.pptx`, Power BI PBIP) |

## What's here

| Folder | What it is |
|---|---|
| [docs/knowledge/](docs/knowledge/README.md) | The Liquidware knowledge base: product architecture, Stratusphere API & SpotCheck reference, ProfileUnity & FlexApp patterns, multi-platform matrix, AVD & FSLogix coexistence, troubleshooting known errors, decision records, and watched upstream sources |
| [blog/](blog/README.md) | Deep-dive technical posts and field notes on Entra-only AVD with ProfileUnity/FlexApp, Stratusphere UX SpotCheck to Power BI PBIP pipelines, and Windows Server RDS to Windows 11 multi-session Portability migrations |
| [templates/](templates/README.md) | Reusable reference templates: ProfileUnity FSLogix-coexistence guardrails, ProfileUnity sample config export, FlexApp package metadata manifests, Stratusphere API Builder query catalog, and CommandCTRL multi-session security/privacy baseline |
| [scripts/tools/](scripts/tools/LiquidwareNinja.psm1) | `LiquidwareNinja.psm1` (9 cross-platform functions) and `Test-LwCidKeyHealth.ps1` (PS 5.1/7+ endpoint health check for the Stratusphere Connector ID Key agent) |
| [scripts/kb/](scripts/kb/build.py) | The 2ndbrain knowledge base curator, validator, freshness checker, and prior-art search tools |
| [tests/](tests/LiquidwareNinja.Tests.ps1) | Offline Pester tests for `LiquidwareNinja.psm1`, `Test-LwCidKeyHealth.ps1`, and `blog/` (`scripts/kb/test_kb.py` covers the KB scripts) |

## PowerShell Toolkit (`scripts/tools/`)

`LiquidwareNinja.psm1` exports nine pure, offline-testable functions across the four Liquidware products:

| Function | Product | Purpose |
|---|---|---|
| `Test-LwPortabilityOverlap` | ProfileUnity + FSLogix | Checks candidate Portability paths and enabled modules against `templates/profileunity/fslogix-portability-guardrails.json` |
| `Export-LwPortabilityRuleset` | ProfileUnity + FSLogix | Filters candidate Portability paths to remove any overlap with `fslogixOwnedPaths` and emits a clean `liquidware-ninja-portability-ruleset/v1` object |
| `Compare-LwProfileUnityConfig` | ProfileUnity | Diffs two ProfileUnity configuration exports (`sample-config-export.json` shape) and reports module, Portability path, restriction, and INI SHA-256 changes |
| `Test-LwFlexAppCandidate` | FlexApp + Stratusphere | Scores an application for `BaseImage`, `FlexAppAppAttach`, `FlexAppOne`, `VersionConsolidationFirst`, or `NotRecommendedForLayering` |
| `New-LwFlexAppManifest` | FlexApp | Builds and validates a `liquidware-ninja-flexapp-package/v1` metadata manifest (including SHA-256 format and single-assignment-plane rules) |
| `Get-LwAssignmentConflict` | FlexApp + AVD | Detects applications assigned in more than one delivery plane (`AvdAppAttach`, `ProfileUnityFlexApp`, `NativeMsix`) |
| `Get-LwSpotCheckThreshold` | Stratusphere UX | Returns canonical Liquidware SpotCheck thresholds from `templates/stratusphere/inspector-catalog.json` |
| `ConvertTo-LwApiUrl` | Stratusphere UX | Builds URL-encoded `/lwl/api?json=...` Inspector queries with explicit date and business-hour slices |
| `Test-LwCommandCtrlBaseline` | CommandCTRL | Validates a CommandCTRL endpoint configuration against `templates/commandctrl/multisession-baseline.json` |

For endpoint troubleshooting on session hosts or physical PCs (Windows PowerShell 5.1 and PowerShell 7+):

```powershell
./scripts/tools/Test-LwCidKeyHealth.ps1 -HubAddress 10.60.0.4
```

## The knowledge base

[docs/knowledge/](docs/knowledge/README.md) holds what this project has learned about Liquidware products across virtual and physical desktops, how they fit with AVD and FSLogix, Stratusphere UX API and SpotCheck methodology, and deployment gotchas—written for people, tools, and AI agents alike. It follows the [2ndbrain](https://github.com/nickprignano/2ndbrain) family format ([family.yaml](docs/knowledge/family.yaml)) and keeps itself current with GitHub Actions: a weekly digest of upstream changes, a monthly freshness check, and issue forms that turn field reports into pull requests. Read [llms.txt](llms.txt) for a map.

Before building something new, run the prior-art check:

```bash
python3 scripts/kb/prior_art.py "<topic>"
```

## Validate before pushing

```bash
pip install -r scripts/kb/requirements.txt
python3 scripts/kb/build.py          # regenerate indexes, tables and llms.txt
python3 scripts/kb/validate.py       # schemas, MADR, links, leak patterns, family
python3 -m unittest discover -s scripts/kb
pwsh -c "foreach (\$p in 'scripts/tools','tests') { Invoke-ScriptAnalyzer -Path \$p -Recurse -Settings ./PSScriptAnalyzerSettings.psd1 -EnableExit }"
pwsh -c "Invoke-Pester -Path ./tests -CI"
```

## Guardrails

The repo is public. Nothing in it identifies a real tenant, subscription, employer or customer, secrets never pass through it or through chat, no Liquidware binaries, installers or license material are committed, and every change goes through a reviewed pull request. The full rules are in [docs/guardrails.md](docs/guardrails.md) and [AGENTS.md](AGENTS.md).

## Contributing

Contributions and forks are welcome and encouraged. Before opening a pull request, run the checks in [AGENTS.md](AGENTS.md) and follow the [guardrails](docs/guardrails.md). Keep tenant data, IDs and secrets out of the repo, issues and pull requests. No Liquidware binaries, license material or assessment exports, ever.

## License

MIT ([LICENSE](LICENSE)). The knowledge base tooling is adapted from [2ndbrain](https://github.com/nickprignano/2ndbrain) under Apache-2.0 ([LICENSE-APACHE](LICENSE-APACHE)); [NOTICE](NOTICE) lists the paths each license covers.
