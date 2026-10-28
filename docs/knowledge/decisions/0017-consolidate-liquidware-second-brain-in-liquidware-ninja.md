---
status: accepted
date: 2026-10-28
---

# 0017. Consolidate the Liquidware second brain and toolkit in liquidware-ninja

## Context and Problem Statement

Our Liquidware work spans multiple repositories: `avd-liquidware` (deploying Stratusphere UX, ProfileUnity, and FlexApp on Azure Virtual Desktop), `ux-assess` (pulling Stratusphere UX API data, running SpotCheck analysis, and rendering deliverables across any desktop platform), and general Liquidware templates and utilities. Previously, the 2ndbrain knowledge base lived inside `avd-liquidware`, while platform-agnostic Stratusphere API and SpotCheck notes lived separately in `ux-assess/docs/`. Where should the shared Liquidware second brain and general catchall toolkit live?

## Considered Options

- **Option 1: Keep the KB inside `avd-liquidware`.** Mixes Azure/AVD deployment Bicep and PowerShell with platform-agnostic Liquidware knowledge (Citrix, Horizon, physical PCs, SpotCheck methodology) and duplicates API docs in `ux-assess`.
- **Option 2: Create `liquidware-ninja` as the dedicated Liquidware second brain and catchall toolkit repository.** Move the 2ndbrain KB, curator workflows, and schemas into `liquidware-ninja`, merge the Stratusphere API and SpotCheck reference notes from `ux-assess`, expand the KB topics to cover all four Liquidware products across all desktop platforms, and house reusable templates (`templates/`) and cross-platform utilities (`scripts/tools/`). Leave `avd-liquidware` focused on Azure/AVD deployment and `ux-assess` focused on the assessment pipeline.

## Decision Outcome

Chosen option: **Option 2 (consolidate in `liquidware-ninja`)**, because it gives all Liquidware work one authoritative knowledge base (`nickprignano/liquidware-ninja`) in the [2ndbrain](https://github.com/nickprignano/2ndbrain) family format while keeping `avd-liquidware` and `ux-assess` clean, single-purpose execution repositories.

### Consequences

- Good, because Stratusphere UX API facts, SpotCheck thresholds, ProfileUnity/FlexApp patterns, and multi-platform guidance live in one place and are curated once by `kb-curator` and `kb-freshness`.
- Good, because `avd-liquidware` stays a focused Bicep/PowerShell deployment repo without carrying duplicate KB workflows.
- Neutral, because `family.yaml` in sibling repos (`avd-second-brain`, `nerdio-hcl`, `2ndbrain`) updates the `liquidware` entry's `repo` to `nickprignano/liquidware-ninja`.
