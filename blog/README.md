# Liquidware Technical Blog & Field Notes

Deep-dive architectural notes, operational patterns, and field engineering write-ups for running **Liquidware** (**Stratusphere UX**, **ProfileUnity**, **FlexApp**, and **CommandCTRL**) across Azure Virtual Desktop, Windows 365, Citrix, Omnissa Horizon, RDS, and physical Windows endpoints.

> [!WARNING]
> **Personal project. Research and learning only. Not for production. No warranty.**
> These posts are personal research notes, not affiliated with or endorsed by the author's employer, Liquidware, or Microsoft.

## Published Posts

| Date | Title | Tags | Status |
|---|---|---|---|
| 2026-10-28 | [Running ProfileUnity and FlexApp on Entra-Only Azure Virtual Desktop without Storage Keys](2026-10-28-entra-only-profileunity-flexapp-on-avd.md) | `profileunity`, `flexapp`, `avd`, `entra-id`, `azure-files`, `app-attach` | `published` |
| 2026-10-28 | [From Stratusphere UX SpotCheck to Reproducible Deliverables and Git-Backed Power BI Models](2026-10-28-stratusphere-spotcheck-to-powerbi.md) | `stratusphere-ux`, `spotcheck`, `powerbi`, `tmdl`, `pbip`, `assessment` | `published` |
| 2026-10-28 | [Crossing the Windows Server RDS to Windows 11 Multi-Session Boundary with ProfileUnity Portability and FSLogix](2026-10-28-rds-to-win11-multisession-portability.md) | `profileunity`, `fslogix`, `rds`, `windows-11`, `migration`, `portability` | `published` |

## Authoring Rules

Every post in `blog/` is validated by Pester (`tests/LiquidwareNinja.Tests.ps1`) and follows these conventions:

1. **Required YAML Front Matter:**
   - `title`: Full title matching the top-level `# H1` heading
   - `date`: ISO date (`YYYY-MM-DD`)
   - `summary`: Single-sentence abstract of the architectural problem and outcome
   - `tags`: Non-empty YAML list of topic tags
   - `status`: `published` or `draft`
2. **Zero Leaks:**
   - Never include tenant IDs, subscription IDs, object IDs, client secrets, storage account keys, real domain names, customer or employer names, or public IPv4 addresses outside RFC 5737 documentation blocks (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`) or RFC 1918 private space (`10.0.0.0/8`).
   - Use `contoso.com`, `10.60.x.x`, and `<subscription-id>` placeholders in all examples.
3. **Cross-References:**
   - Link durable rules back to canonical pages in [`docs/knowledge/`](../docs/knowledge/README.md) and reusable guardrails in [`templates/`](../templates/README.md).
