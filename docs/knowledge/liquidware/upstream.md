---
title: "Asks for Liquidware"
summary: "Gaps found while automating Stratusphere in Azure, with the evidence, to raise with Liquidware"
topic: liquidware
status: verified
last_reviewed: 2026-10-29
---

# Asks for Liquidware

Gaps this project has hit, worth raising with Liquidware. Each says what's missing, the evidence,
and its status. *(The family keeps these in an `upstream.yaml` data file; this KB can't yet, because
the shared scripts read that file from a fixed path. A family format proposal is open:
[decision 0012](../decisions/0012-family-format-upstream-path-in-kb-toml.md).)*

| Ask | Evidence | Status |
|---|---|---|
| Configure a new Hub through the API (license, API user, allow list) so first-time setup can be automated | Liquidware documents all API access as read-only data access ([hub-setup.md](../stratusphere/hub-setup.md)) | Open |
| Publish the Database and Collector roles in Azure Marketplace, or document how to deploy them in Azure | Liquidware's Azure guide documents Database and Collector plans next to the Hub ([azure/marketplace.md](../azure/marketplace.md)) | Done (Liquidware already does) |
| A sample that keeps TLS verification on | The SE PowerTools batch script disables certificate checks ([community-projects.md](community-projects.md)) | Open |
| A license on the liquidwarelabs sample repos, so the community can adapt them | No license file ([community-projects.md](community-projects.md)) | Open |
| Document the Connector ID Key installer's exit codes for scripted rollouts | Service names, settings key and switches are in support articles; exit codes aren't ([connector-id-key.md](../stratusphere/connector-id-key.md)) | Open |
| Make the API Client IPs field's no-authentication behavior obvious in the console | Addresses there read the API without credentials ([hub-setup.md](../stratusphere/hub-setup.md)) | Open |
