---
title: "Stratusphere UX appliances in Azure"
summary: "Hub, Database and Collector roles: when each is needed, sizes, addresses, credentials and what hasn't been confirmed on a real run"
topic: stratusphere
status: verified
last_reviewed: 2026-10-29
---

# Stratusphere UX appliances in Azure

Stratusphere UX runs as Linux appliances from Azure Marketplace. This repo deploys them with
[`Deploy-Stratusphere.ps1`](https://github.com/nickprignano/avd-liquidware/blob/main/stratusphere/docs/appliances.md); this page holds the facts
behind it, checked against Liquidware's 6.7.1 documentation. None of it has been through a lab run
on a real subscription yet.

Sources: [UX prerequisites](https://docs.liquidware.com/stratusphere-671/en-us/ux-preqs-preparation/ux-prerequisites-preparation.htm),
[Installing on Microsoft Azure](https://docs.liquidware.com/stratusphere-671/en-us/installation-guide/installing-on-microsoft.htm),
[Using the Database appliance](https://docs.liquidware.com/stratusphere/en-us/662/installation-guide/using-strat-database.htm).

## Roles

| Role | When | Size used here | Notes |
|---|---|---|---|
| Hub | Always | `Standard_D4s_v5`, 128 GB Premium SSD | Liquidware's minimum: 4 vCPU, 16 GB RAM, 60 GB disk |
| Database | Above about 1,000 devices at the default 60-minute callback, or more than 1,000 callbacks an hour | `Standard_D4s_v5`, 256 GB | Minimum 4 vCPU, 16 GB RAM, 94 GB disk. Trust is established, then the Hub is joined to it from the Hub's console |
| Collector | Optional: CID Data Collector (spreads callback load, or takes callbacks the Hub can't), or Network Collector | `Standard_D2s_v5`, 64 GB | Minimum 2 vCPU, 8 GB RAM, 22 GB disk. Each one is added and registered in the Hub's Collector Administration |

Liquidware sizes real deployments with its online Stratusphere Sizing Guide, recommends keeping the
Hub, Database and Collectors close (a proximity placement group, ideally the same host group), and
offers `Standard_D4s_v3` as the Hub's default size in the Marketplace flow.

- Each role has its own Marketplace plan (Hub, Database, Collector); see
  [azure/marketplace.md](../azure/marketplace.md).
- A VM's Marketplace plan can't change after it's created, so changing role or plan means a new VM.

## Credentials

- The administrator account Azure sets at creation is the appliance's SSH login. Liquidware's Azure
  guide recommends an SSH public key and supports a password.
- The web console has its own account: `ssadmin`, with Liquidware's documented default password
  until you change it (on AWS the default is the instance ID). Change it at first sign-in; it's a
  different credential from the Azure one.
- An appliance keeps the password it was created with, so a rerun has to reuse it. This repo
  generates it once and keeps it in Key Vault ([decision 0006](../decisions/0006-credentials-in-key-vault.md)).

## Licensing

Bring your own Stratusphere license (the Marketplace Hub is BYOL). Liquidware offers evaluation
licenses; their size and length come with the evaluation, not from the public docs
([licensing FAQs](https://docs.liquidware.com/stratusphere-671/en-us/licensing-faqs/licensing-faqs.htm)).
After a license change, the API can return "License Not Authorized" until the Hub is rebooted
([support article](https://support.liquidware.com/hc/en-us/articles/210641343-After-updating-the-license-API-access-returns-License-Not-Authorized-error)).
No license material belongs in the repo
([decision 0004](../decisions/0004-marketplace-appliances-no-vendor-binaries.md)).

## First-time setup

The Hub's license, API user and API allow list are set in its web console. See
[hub-setup.md](hub-setup.md).
