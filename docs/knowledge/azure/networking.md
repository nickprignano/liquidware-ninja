---
title: "Networking for Stratusphere in Azure"
summary: "The ports the appliances and Connector ID Keys need, egress without default outbound access, peering, and how routes affect callbacks"
topic: azure
status: verified
last_reviewed: 2026-10-29
---

# Networking for Stratusphere in Azure

The assessment environment sits in its own VNet, peered to the network the desktops are on. The
ports below are from Liquidware's
[ports article](https://support.liquidware.com/hc/en-us/articles/210639223-What-ports-does-Stratusphere-use)
and the 6.7.1 [Hub](https://docs.liquidware.com/stratusphere-671/en-us/hub-basic-facts/hub-basic-facts.htm) and
[Database](https://docs.liquidware.com/stratusphere-671/en-us/database-basic-facts/database-basic-facts.htm)
basic facts; a lab run hasn't exercised them yet.

| Traffic | Port | Between |
|---|---|---|
| Connector ID Key callbacks | TCP 443 | Desktops to the Hub or a CID Collector (TCP 5501 only before 6.0) |
| Collector communications | TCP 443 | Collectors to the Hub |
| Database | TCP 5432 (PostgreSQL) | The Hub and Collectors to the Database appliance; Collectors to the Hub only when there's no Database appliance |
| Upgrades | TCP 443 | The Database appliance to the Hub, to check for and run upgrades |
| Console | TCP 443 | Administrators to the Hub's web console |
| SSH | TCP 22 | Administrators to each appliance (through Bastion, or a peered jump host); the Hub to the Database during setup, upgrades and data migration |

## Egress

With default outbound access turned off on the subnet, the appliances need an explicit way out for
updates and time sync. This repo uses a NAT Gateway. A NAT Gateway bills while it exists, even with
every VM stopped ([lab-costs.md](lab-costs.md)).

## Peering and routes

- Peering fails if the two address spaces overlap, so check the assessment range against the peer
  VNet and the VNets already peered to it.
- With direct peering, Azure adds a system route for the assessment range. A user route wins only
  if it's at least as specific, so a forced-tunnel `0.0.0.0/0` to a firewall doesn't divert the
  callbacks.
- Without direct peering (the desktops reach the assessment VNet through a hub network), the covering
  route decides, and a firewall on that path must allow TCP 443 to the Hub.
- NSG rules are evaluated by priority and the first match wins. A deny above the allow for TCP 443
  silently stops the callbacks.

Routing and NSG behavior: Microsoft's [traffic routing](https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
(longest prefix wins; on a tie, a user route beats BGP and system routes),
[peering](https://learn.microsoft.com/azure/virtual-network/virtual-network-peering-overview) (address spaces can't overlap) and
[NSG](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#security-rules) (rules processed in priority order until one matches) docs.

The preflight checks all of this:
[stratusphere/docs/preflight.md](https://github.com/nickprignano/avd-liquidware/blob/main/stratusphere/docs/preflight.md).
