---
title: "SpotCheck thresholds, canonical dataset and sizing"
summary: "How Stratusphere UX data turns into SpotCheck findings, sizing tiers and before/after migration baselines"
topic: stratusphere
status: verified
last_reviewed: 2026-10-28
sources:
  - https://github.com/liquidwarelabs/Stratusphere-UX
  - https://docs.liquidware.com/stratusphere/en-us/common/stratusphere-getting-started-api-guide/using-the-api.htm
---

# SpotCheck thresholds, canonical dataset and sizing

Liquidware's **SpotCheck** methodology evaluates desktop user experience by checking resource consumption and login metrics during active business hours rather than 24-hour averages, which wash out peaks. This page records the thresholds, canonical dataset structure, and engagement patterns implemented in `ux-assess`.

## SpotCheck thresholds and their sources

Every threshold used in an assessment should carry its provenance (`SpotCheck` when published in Liquidware's SpotCheck guidance in [liquidwarelabs/Stratusphere-UX](https://github.com/liquidwarelabs/Stratusphere-UX), or labeled as a toolkit default when overridable per engagement):

| Metric | Threshold | Direction | SpotCheck / Default provenance |
|---|---|---|---|
| CPU utilization (`cpu_used_pct`) | `> 80 %` (`p95` / business hours) | High is bad | Liquidware SpotCheck guidance (sustained high CPU indicates constrained compute or runaway processes) |
| CPU queue length (`cpu_queue_avg`) | `> 2.0` per core | High is bad | Liquidware SpotCheck guidance (threads waiting on processor scheduling) |
| Memory utilization (`memory_used_pct`) | `> 85 %` | High is bad | Liquidware SpotCheck guidance (risk of paging and out-of-memory pressure) |
| Disk queue length (`disk_queue_avg`) | `> 2.0` | High is bad | Liquidware SpotCheck guidance (storage latency or IOPS bottleneck) |
| Page file usage (`page_used_mb`) | `> 1024 MB` | High is bad | Liquidware SpotCheck / default indicator of active memory swapping |
| Application load time (`app_load_time_avg_s`) | `> 5.0 s` | High is bad | SpotCheck indicator of slow storage, profile bloat, or CPU contention |
| Login duration (`login_duration_s`) | `> 30.0 s` | High is bad | Liquidware SpotCheck guidance (GPO, profile load, or logon script delay) |
| Composite UX score (`ux_score`) | `< 70` | Low is bad | Toolkit default when Hub UX score column is mapped |

### Deterministic finding severity

To prevent a single spike from flagging an estate:

1. **Machine-level breach:** A machine is flagged on a metric only when it exceeds the threshold in at least a configured share of its active business hours (for example, `>= 20 %` of business hours).
2. **Estate-level severity:** The share of machines breaching the rule sets the finding's severity (`high` when `>= 25 %` of machines breach, `medium` when `>= 10 %`, `low` below that).
3. **Missing data is never a pass:** If a column is unmapped or absent from the export, the report marks the check `"not measured"` rather than passing it silently.

## Canonical assessment dataset

Normalizing Hub exports into five canonical tables decouples downstream analysis, deliverables, and Power BI models from Hub version differences:

| Table | Grain | Canonical columns |
|---|---|---|
| `machines` | `machine` | `machine`, `os_version`, `hw_make`, `hw_model`, `hw_type`, `is_vm`, `cpu_cores`, `cpu_speed_mhz`, `disk_size_gb`, `memory_allocated`, `last_boot_time` |
| `machine_hourly` | `machine x business hour` | `period_start`, `machine`, `cpu_used_pct`, `memory_used_pct`, `cpu_queue_avg`, `disk_queue_avg`, `page_used_mb`, `app_load_time_avg_s` |
| `app_usage` | `application x user x machine x day` | `period_start`, `application`, `version`, `process`, `machine`, `user` |
| `logins` | `user x machine x day` | `period_start`, `user`, `machine`, `login_duration_s` |
| `ux_daily` | `user x day` | `period_start`, `user`, `ux_score` |

Derived tables (`findings.csv`, `finding_machines.csv`, `machine_summary.csv`) hold per-machine `p95` utilization, active hours/days, and right-sized tier recommendations (`Light`, `Medium`, `Heavy`, `Power`).

## Engagement types

| Engagement type | Primary question | Core deliverable sections |
|---|---|---|
| `current-state` | What is in the estate and how healthy is it? | Scope, data quality, executive summary, SpotCheck findings, hardware/OS inventory, application inventory, right-sizing tiers, thresholds |
| `performance` | Why and when are users experiencing slowdowns? | Scope, data quality, summary, findings, time-of-day hotspot heatmaps (by business hour), top offending machines, thresholds |
| `sizing` | What VM SKUs and session host counts do we need? | Scope, data quality, summary, right-sizing tier distribution (`p95` CPU/RAM), hardware/OS inventory, application footprint, thresholds |
| `migration-baseline` | Did the new platform improve user experience compared to the old one? | Scope, data quality, summary, before-and-after KPI deltas (`baseline.json`), findings, inventory, thresholds |

When pseudonymizing with HMAC-SHA256, keeping the same customer-held key across the `before` and `after` runs ensures machine and user pseudonyms (`m-...`, `u-...`) line up without exposing real identifiers.
