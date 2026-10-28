# Liquidware Templates and Reference Manifests

Reusable reference configurations, guardrails, and catalogs for **ProfileUnity**, **FlexApp**, **Stratusphere UX**, and **CommandCTRL**. None of these files hold customer data, tenant IDs, or license material.

| File | Product | What it is |
|---|---|---|
| [profileunity/fslogix-portability-guardrails.json](profileunity/fslogix-portability-guardrails.json) | ProfileUnity + FSLogix | Canonical list of profile folders owned by FSLogix Profile/ODFC containers that must be excluded from ProfileUnity Portability rulesets (`Test-LwPortabilityOverlap` and `Export-LwPortabilityRuleset` read this) |
| [profileunity/sample-config-export.json](profileunity/sample-config-export.json) | ProfileUnity | Reference plain-text/JSON export of a ProfileUnity configuration (`enabledModules`, `portabilityPaths`, `applicationRestrictions`, `iniSha256`) used for offline diffing and promotion validation (`Compare-LwProfileUnityConfig`) |
| [flexapp/flexapp-package.example.json](flexapp/flexapp-package.example.json) | FlexApp | Example metadata manifest for a FlexApp VHDX/CimFS package (`New-LwFlexAppManifest`, `avd-liquidware`, and ring promotion scripts validate against this shape) |
| [stratusphere/inspector-catalog.json](stratusphere/inspector-catalog.json) | Stratusphere UX | Reference catalog of Stratusphere Hub `/lwl/api` Inspector IDs, default `basis` dimensions, sample columns, and SpotCheck thresholds (`ConvertTo-LwApiUrl` and `Get-LwSpotCheckThreshold` read this) |
| [commandctrl/multisession-baseline.json](commandctrl/multisession-baseline.json) | CommandCTRL | Security, privacy, and Stratusphere coexistence baseline for CommandCTRL on multi-session hosts (`Test-LwCommandCtrlBaseline` validates against this) |
