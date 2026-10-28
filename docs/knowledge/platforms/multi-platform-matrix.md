---
title: "Liquidware across desktop platforms"
summary: "How Stratusphere UX, ProfileUnity, FlexApp and CommandCTRL behave across AVD, Windows 365, Citrix, Horizon, RDS and physical PCs"
topic: platforms
status: verified
last_reviewed: 2026-10-28
---

# Liquidware across desktop platforms

Liquidware's suite is designed to bridge platform migrations—assessing a legacy physical, Citrix, or Horizon estate with Stratusphere UX, abstracting user state with ProfileUnity Portability, layering apps with FlexApp, and landing on Azure Virtual Desktop, Windows 365, or a refreshed VDI platform.

## Multi-platform matrix

| Platform | Stratusphere UX (CID Key & API) | ProfileUnity (UEM & Portability) | FlexApp (Application Layering) | Typical migration / operational pattern |
|---|---|---|---|---|
| **Physical Windows PCs** | CID Key deployed via Intune, SCCM, or GPO; reports hardware inventory, app usage, CPU/RAM/disk, and UX baseline | Captures user settings into Portability archives on file share or cloud storage; elevates/restricts apps | **FlexApp One** (`.exe` via Intune/SCCM) for offline support, or network FlexApp on LAN | Source estate for VDI/AVD sizing and persona discovery (`ux-assess --type sizing`) |
| **Citrix CVAD / Citrix DaaS** | Captures ICA/HDX session metrics alongside guest OS resource queues and login breakdowns | Coexists with or replaces Citrix Profile Management / FSLogix; applies contextual policies by Delivery Group or client IP | Native FlexApp layers mounted from SMB shares or cloud storage on non-persistent MCS/PVS workers | Source or target estate; `migration-baseline` compares HDX vs. RDP Shortpath / AVD |
| **Omnissa Horizon (VMware)** | Captures Blast/PCoIP session telemetry and guest OS metrics (plus optional vCenter/ESX host inspector `3`) | Coexists with FSLogix or Dynamic Environment Manager (DEM); Portability bridges Instant Clone pools | Native FlexApp layers on Instant Clones (complementing or replacing App Volumes) | Source estate for Horizon-to-AVD migrations; same single-assignment rule applies |
| **Windows Server RDS** | Multi-session guest telemetry per user and per RDSH server; identifies noisy-neighbor processes | Crucial when migrating users off Windows Server OS profiles (`v6`) to Windows 11 multi-session (`v6` client OS) via Portability | Isolates per-department apps on shared RDSH servers without installing for all users | High-value Portability use case because Server-to-Client OS profile containers shouldn't be mounted directly without migration |
| **Azure Virtual Desktop (AVD)** | Hub in Azure Marketplace (`avd-liquidware/stratusphere`); CID Key rolled out by Azure Run Command or image/Intune | FSLogix stays the VHDX profile container; ProfileUnity adds UEM, restrictions, and cross-pool Portability over Entra Kerberos Azure Files | Native **AVD App Attach** integration (`appattach` Azure Files share) or FlexApp One | Automated end-to-end by [`avd-liquidware`](https://github.com/nickprignano/avd-liquidware) |
| **Windows 365 (Cloud PC)** | CID Key via Intune Win32 app; measures persistent Cloud PC utilization for SKU right-sizing (step-up/step-down) | UEM policies and Portability for disaster recovery or reprovisioning across Cloud PCs | FlexApp One via Intune or cloud-native FlexApp layers | Right-sizing persistent Cloud PCs that are over-provisioned (`ux-assess --type sizing`) |

## Key cross-platform lessons

1. **Assessment pipeline is 100% platform-agnostic:** `ux-assess` queries the same Hub Inspectors (`0`, `1`, `4`, `10`), normalizes to the same five canonical tables, and applies the same SpotCheck thresholds regardless of whether the source machines are physical laptops, Citrix workers, Horizon Instant Clones, or AVD session hosts.
2. **Use `migration-baseline` with a persistent HMAC key across platforms:** When moving users from Citrix/Horizon/physical to AVD, run `ux-assess` before cutover (`baseline.json`) and again after cutover with `compare_to` pointing at the before baseline.
3. **Server OS to Client OS migrations need Portability:** Moving from Windows Server RDS/Citrix to Windows 11 Enterprise multi-session on AVD crosses a Windows Server-to-Client OS boundary where raw FSLogix VHDX reuse is unsupported; ProfileUnity Portability selectively migrates user application settings and registry state into a clean Windows 11 FSLogix container.
