---
title: "FlexApp packaging, VHDX/CimFS and App Attach delivery"
summary: "How FlexApp packages applications into elastic layers and delivers them natively or through AVD App Attach"
topic: flexapp
status: partial
last_reviewed: 2026-10-29
sources:
  - https://docs.liquidware.com/profileunity/en-us/695/flexapp-packaging-console-guide/welcome.htm
---

# FlexApp packaging, VHDX/CimFS and App Attach delivery

**Liquidware FlexApp** decouples applications from the base OS image by capturing installers into virtualized disks (VHDX; CimFS as a FlexApp format is *unverified*) and filter-driver metadata so apps appear native to the OS without baking them into golden images.

## Delivery modes

| Mode | How it mounts and activates | Best for |
|---|---|---|
| **Native FlexApp (via ProfileUnity Client)** | ProfileUnity client mounts the VHDX/CimFS from an SMB share or cloud storage at logon or click-to-layer and applies registry/file filter rules | Citrix CVAD/DaaS, Omnissa Horizon, RDS, physical PCs, or AVD when context-aware filters inside ProfileUnity drive assignment |
| **AVD App Attach integration** | FlexApp package VHDX is stored on an Azure Files share (`appattach`) and registered as a `Microsoft.DesktopVirtualization/appAttachPackages` resource assigned to host pools and Entra groups; FlexApp inventory syncs with AVD app attach from 6.8.7 ([6.8.7 announcement](https://support.liquidware.com/hc/en-us/articles/32074165322765-Announcing-ProfileUnity-FlexApp-6-8-7-Elevate-Your-Workspace-Management)) | Azure Virtual Desktop where Azure control-plane visibility, RBAC, and host-pool-level lifecycle are preferred |
| **FlexApp One** | Bundles the captured layer into a self-contained `.exe` ([command line reference](https://support.liquidware.com/hc/en-us/articles/45348265831565-FlexApp-One-Command-Line-Reference)) that can run offline or be distributed via Intune, SCCM, or cloud storage without the full console stack | Physical laptops, offline/disconnected endpoints, or Intune-managed Windows 365 / AVD hosts |

## The single assignment system rule

Never assign the same application through both ProfileUnity's internal FlexApp rules and Azure Virtual Desktop App Attach (or native MSIX App Attach) on the same host pool:

- Pick **one assignment plane per application** (in `avd-liquidware`, the default is AVD App Attach registered with the operator's identity and assigned by ring).
- Run `Get-LwAssignmentConflict` (or check host pool packages against ProfileUnity's configuration export) to fail any build where an application appears in more than one assignment system.

## Packaging VM hygiene

- **Match the session host OS build on single-session Windows:** Capture packages on a clean, single-session VM running the exact same Windows feature update as the target session hosts (for example, Windows 11 Enterprise `win11-24h2-ent` for `win11-24h2-avd-m365` hosts).
- **Ephemeral packaging VMs:** Create the packaging VM on demand (or revert to a clean snapshot before every capture), never join it to a production session host pool, and destroy it when packaging completes so it does not accrue idle compute charges.
- **Record a fallback install method:** Every FlexApp package manifest should record its fallback install method (`base-image`, `intune-win32`, or `manual-msi`) in case an application with kernel drivers or unsupported services cannot be layered.

## Blue/green version swap

When updating a packaged application from `v1` to `v2`:

1. Upload `appattach/<app>/<v2>/` to the packages share without overwriting `v1`.
2. Register `<app>-<v2>` and assign it to the `QA` host pool / ring.
3. Promote `<app>-<v2>` to `All` and remove the host pool reference from `<app>-<v1>`.
4. Keep `<app>-<v1>` registered (unassigned) for instant rollback until explicitly retired.
