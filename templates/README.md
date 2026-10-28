# Liquidware Templates and Reference Manifests

Reusable reference configurations, guardrails, and catalogs for **ProfileUnity**, **FlexApp**, and **Stratusphere UX**. None of these files hold customer data, tenant IDs, or license material.

| File | Product | What it is |
|---|---|---|
| [profileunity/fslogix-portability-guardrails.json](profileunity/fslogix-portability-guardrails.json) | ProfileUnity + FSLogix | Canonical list of profile folders owned by FSLogix Profile/ODFC containers that must be excluded from ProfileUnity Portability rulesets (`Test-LwPortabilityOverlap` reads this) |
| [flexapp/flexapp-package.example.json](flexapp/flexapp-package.example.json) | FlexApp | Example metadata manifest for a FlexApp VHDX/CimFS package (`avd-liquidware` and ring promotion scripts validate against this shape) |
| [stratusphere/inspector-catalog.json](stratusphere/inspector-catalog.json) | Stratusphere UX | Reference catalog of Stratusphere Hub `/lwl/api` Inspector IDs, default `basis` dimensions, sample columns, and SpotCheck thresholds (`ConvertTo-LwApiUrl` and `Get-LwSpotCheckThreshold` read this) |
