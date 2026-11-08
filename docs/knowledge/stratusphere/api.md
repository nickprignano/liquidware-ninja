---
title: "Stratusphere API"
summary: "The Hub's read-only data API: request shape, inspectors, basis, parameters, authentication, output formats and ecosystem prior art"
topic: stratusphere
status: partial
last_reviewed: 2026-10-29
sources:
  - https://docs.liquidware.com/stratusphere/en-us/common/stratusphere-getting-started-api-guide/using-the-api.htm
  - https://docs.liquidware.com/stratusphere/en-us/common/stratusphere-getting-started-api-guide/accessing-api-and-documentation.htm
  - https://support.liquidware.com/hc/en-us/articles/21156817491981-Stratusphere-REST-API-Automation-using-PowerShell-Script
  - https://docs.liquidware.com/stratusphere-671/en-us/security-addendum/hub-advanced-configuration.htm
---

# Stratusphere API

The Stratusphere Hub serves a read-only data API for what Stratusphere collects; Liquidware's [Hub Advanced Configuration](https://docs.liquidware.com/stratusphere-671/en-us/security-addendum/hub-advanced-configuration.htm) describes every kind of API access as read-only, so Hub settings stay in the console ([hub-setup.md](hub-setup.md)). Every Hub serves its own full option reference, examples, and per-inspector column catalog at `https://<hub>/lwl/api`—a real Hub's built-in documentation always wins over anything recorded here.

## Request shape and authentication

From Liquidware's [Using the API](https://docs.liquidware.com/stratusphere/en-us/common/stratusphere-getting-started-api-guide/using-the-api.htm) and [Accessing the API](https://docs.liquidware.com/stratusphere/en-us/common/stratusphere-getting-started-api-guide/accessing-api-and-documentation.htm) guides:

- **Endpoint:** `https://<hub>/lwl/api?json={...}`, called with `GET` or `POST`.
- **Fields:** only `inspector` (the data table, by ID or name such as `applications`) is required. `basis` sets the group-by dimension, such as `users` returning `user_id` and `user_name`, or `machines` returning `node_id` and `node_name`; several can be given as a list. Without a time window, the default period is `yesterday`.
- **Authentication:** HTTP Basic as `username@domain`, for users with **Allow API Access** (Inventory > Users), from addresses on the API **Whitelist** (**Hub Administration > Configuration > Security Settings**). Addresses in **API Client IPs** skip authentication entirely, so keep that field empty ([hub-setup.md](hub-setup.md)).
- **Output formats:** JSON, CSV, or Excel.

## Inspectors and parameters seen in public samples

From Liquidware's public [Stratusphere-UX SE PowerTools](https://github.com/liquidwarelabs/Stratusphere-UX) samples (reference only, no license; see [community-projects.md](../liquidware/community-projects.md)) and [SE Field Articles](https://support.liquidware.com/hc/en-us/articles/21156817491981-Stratusphere-REST-API-Automation-using-PowerShell-Script):

| Inspector ID | Dataset | Typical `basis` | Notes |
|---|---|---|---|
| `0` | Users / summary | `users`, `machines` | Overall user or machine summary metrics |
| `1` | Applications | `applications`, `users`, `machines` | Application load counts, load time, CPU/memory by process |
| `2` | Connections / remoting | `users`, `machines` | Session protocol and connection metrics |
| `3` | Virtualization hosts | `hosts` | Hypervisor / ESX host metrics |
| `4` | Machine inventory | `machines` | OS version, hardware make/model/type, CPU cores/speed, disk size, allocated memory, last boot |
| `10` | Login details | `users`, `machines` | Logon breakdown and timing |

Common request parameters:

- **Time window:** `date` (`today`, `yesterday`, `2 hours`, `24 hours`, `1 day`), `custom_start_date` / `custom_end_date` (`YYYY-MM-DD`), `start_time` / `end_time` (hour integers, used for business-hour slicing), `resolution` (`Day-Hour`).
- **Projection and filtering:** `columns` (array or comma-separated list of column names), `filter` (expressions such as `app_load_count gt 0`, `user_name not like '...'`, `d_id eq 5308 OR ...`), `only_process` (`user`), `node_group_name` with `unbasis`.
- **Paging and formatting:** `limit` (`0` for all rows), `sort_col`, `output` (`1` with `output_name` for background file generation), `header`, `csv_eof`.

## Ecosystem and reporting patterns

- **Background generation for large queries:** Large API responses are built asynchronously on the Hub. Liquidware's SE automation article retries after 30 seconds with a 180-second timeout.
- **Power BI integration:** Liquidware's [2019 blog post](https://www.liquidware.com/blog/extracting-liquidware-stratusphere-ux-data-with-microsoft-powerbi) points Power BI's Web connector directly at the Hub API URL, which requires an on-premises data gateway, a trusted Hub certificate, and the Hub remaining online for every refresh. Exporting to a normalized local dataset first (the pattern used by `ux-assess`, see [spotcheck-and-sizing.md](spotcheck-and-sizing.md)) avoids gateway and certificate dependencies and feeds Power BI the same pseudonymized dataset as written reports.
- **Built-in Executive Summary report:** Stratusphere 6.7+ includes an [Executive Summary UX custom report](https://support.liquidware.com/hc/en-us/articles/27956754389261-Stratusphere-template-for-Executive-Summary-User-Experience-report) comparing KPIs across two time periods inside the Hub.

## Gotchas

- **Self-signed TLS certificate:** The Hub uses a self-signed certificate by default. Trust that certificate on the exporting machine instead of disabling TLS verification globally (Liquidware's older `BatchReport.ps1` sample disables TLS checks).
- **Inspector Excel export row cap:** Exporting an Inspector grid directly to Excel from the UI caps at 99,999 rows per sheet *(unverified)*. Use the API with `limit: 0` or slice by day/hour for larger estates.
- **Unverified column names and units:** Until confirmed against a live Hub's `/lwl/api` page, exact column names for login duration and composite UX score, the units of `memory_allocated` and `application_load_time_avg`, and whether `resolution: Day-Hour` emits a clean timestamp column remain *unverified*.
- **PII in exports:** Raw API responses contain real user and machine names. Keep raw exports in git-ignored `output/` directories and pseudonymize with HMAC before data leaves the customer environment.
