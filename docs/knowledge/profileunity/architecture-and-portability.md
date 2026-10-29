---
title: "ProfileUnity architecture, Portability and configuration promotion"
summary: "How ProfileUnity manages user environments and Portability alongside profile containers, and how to promote configurations safely"
topic: profileunity
status: verified
last_reviewed: 2026-10-29
sources:
  - https://docs.liquidware.com/profileunity/en-us/695/installation-and-configuration-guide/welcome.htm
  - https://support.liquidware.com/hc/en-us/articles/46214053640077-Announcing-ProfileUnity-FlexApp-6-9-5
  - https://support.liquidware.com/hc/en-us/articles/48256257521037-ProfileUnity-License-Server-Errors-at-Logon-Not-Defined-and-Could-Not-Be-Contacted
---

# ProfileUnity architecture, Portability and configuration promotion

**Liquidware ProfileUnity** provides user environment management (UEM), contextual policy (drive/printer mappings, registry, folder redirection, privilege elevation, application restrictions), and **Profile Portability** across Windows OS versions and desktop platforms.

## Components

| Component | Role | Operational notes |
|---|---|---|
| **ProfileUnity Management Console** | Web-based administration console (Windows Server, embedded MongoDB, web console on TCP 8000 by default, licensing on TCP 443 from 6.8.5; clustered consoles talk MongoDB on TCP 27017) | Authors configurations and compiles them into `.ini` and `client.net.xml` files. Version floor in our Azure tier is **6.9.5** |
| **ProfileUnity Client** (`LwL.ProfileUnity.Client.*`) | Runs on each session host or desktop at startup, logon, and logoff | Reads `client.net.xml` (`CLIENTXML`) and executes the compiled `.ini` (`USERINI`) from a file share or cloud storage path |
| **Configuration share (`lwconfig`)** | SMB file share (or cloud object storage) holding the compiled `.ini` and XML | Session hosts need **read-only** (`SMB Share Reader`) access as the signing-in user; users must never hold write permissions on the live configuration share |
| **Portability share (`portability`)** | SMB file share storing per-user portable archive files (`.lwp` / `.bz2`) | Used when migrating across OS boundaries, clouds, or profile types; users need read/write on their own folder only (same NTFS creator-owner pattern as FSLogix) |

## Coexistence with FSLogix (and roaming profile containers)

When FSLogix Profile Containers (or ODFC) are present, **FSLogix owns the VHDX profile container** and ProfileUnity adds policy, UEM, and selective Portability on top ([avd/fit-with-avd-and-fslogix.md](../avd/fit-with-avd-and-fslogix.md)):

- **Never capture the same folder twice:** If FSLogix already persists `%LOCALAPPDATA%\Microsoft\OneDrive`, `%LOCALAPPDATA%\Packages`, Teams cache, or search indexes inside the profile VHDX, exclude those paths from ProfileUnity Portability rulesets (or vice versa via FSLogix `redirections.xml`). Capturing a path in both engines doubles logon/logoff I/O and causes last-writer-wins corruption on multi-session hosts.
- **Turn off overlapping container features:** Disable ProfileUnity's own full Profile Disk module on hosts where FSLogix Profile Containers are active.
- **Validate overlap offline:** Use `Test-LwPortabilityOverlap` in [`scripts/tools/LiquidwareNinja.psm1`](../../../scripts/tools/LiquidwareNinja.psm1) against [`templates/profileunity/fslogix-portability-guardrails.json`](../../../templates/profileunity/fslogix-portability-guardrails.json) before promoting a configuration.

## Two-step configuration promotion (staging to live)

In hardened environments (especially Entra-only Azure Virtual Desktop where machine accounts cannot authenticate over SMB to Azure Files, and where a compromised console should not be able to push logon scripts to every desktop unattended):

1. **Console writes locally and publishes to staging:** The console deploys its compiled `.ini` and plain-text export to a local folder (`C:\ProgramData\avd-liquidware\deploy`), and a scheduled task uploads them over HTTPS using its managed identity to an isolated `staging/<configName>/<timestamp>/` blob container.
2. **Offline policy and overlap checks:** Before promotion, tooling checks that the configuration is non-empty, matches the plain-text export hash, and introduces no FSLogix path overlap.
3. **Atomic ring promotion (`QA` then `All`):** An independent operator or approved runner copies the staged files into the live `lwconfig` share under a temporary name and renames them into place (`XML` before `INI`), targeting `-Ring QA` hosts first and `-Ring All` only after validation.

## Gotchas

- **Encrypted INI files in 6.9.5:** ProfileUnity 6.9.5 encrypts `.ini` content by default ([6.9.5 release announcement](https://support.liquidware.com/hc/en-us/articles/46214053640077-Announcing-ProfileUnity-FlexApp-6-9-5)), so automated policy diffing must inspect the console's plain-text/JSON export paired with the `.ini` hash. How the export and the hash pair up is still to be seen in the tier's sandbox (V23).
- **Swagger UI exposure:** From 6.9.5 the console's Swagger API documentation is configurable and off by default; keep it off outside initial setup to reduce attack surface on the management network.
- **Drained client rollout on multi-session hosts:** Installing or updating the ProfileUnity client on active multi-session hosts without draining (`allowNewSession: false` plus scaling exclusion) risks mid-session hook mismatches.
