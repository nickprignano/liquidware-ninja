---
title: "CommandCTRL overview and real-time support"
summary: "Where Liquidware CommandCTRL fits for real-time helpdesk diagnostics and remediation next to Stratusphere UX"
topic: commandctrl
status: partial
last_reviewed: 2026-10-28
sources:
  - https://www.liquidware.com/products/commandctrl
  - https://docs.liquidware.com/
---

# CommandCTRL overview and real-time support

**Liquidware CommandCTRL** is a cloud-hosted (SaaS) real-time endpoint monitoring, diagnostic, and remote support tool for virtual and physical desktops. While **Stratusphere UX** focuses on historical trend collection, SpotCheck assessments, right-sizing, and estate-wide baselining, CommandCTRL focuses on **live helpdesk triage and remediation**.

## Stratusphere UX vs. CommandCTRL

| Question | Tool | Why |
|---|---|---|
| "How should we size our AVD host pools based on the last 14 days of peak business hours?" | **Stratusphere UX** | Collects historical inspector time-series across the estate for SpotCheck analysis and sizing (`ux-assess`) |
| "Did our migration from Citrix to AVD improve p95 logon times and CPU queue length?" | **Stratusphere UX** | Before/after baseline comparison (`baseline.json`) across assessment windows |
| "A user is having high latency and a frozen app right now—what process or network hop is causing it, and can I fix it live?" | **CommandCTRL** | Second-by-second real-time process, network, GPU/protocol telemetry, remote shell, and remediation actions |

## Architecture notes

- **Control plane:** SaaS-delivered by Liquidware (no on-premises or customer-hosted Hub appliance to deploy, unlike Stratusphere UX).
- **Endpoint agent:** Installed on Windows (or macOS / thin client) endpoints; communicates outbound over HTTPS (TCP 443) to the CommandCTRL cloud service.
- **Security and governance in Azure estates:** Because CommandCTRL includes live remote shell and process termination capabilities, treat its agent and operator roles with the same change-control and audit guardrails as privileged administrative access (Phase L3 in `avd-liquidware` [`docs/spec.md`](https://github.com/nickprignano/avd-liquidware/blob/main/docs/spec.md)).
