---
title: "First-time Hub setup"
summary: "What has to be set in the Hub console after deployment (license, API user, API allow list) and what might move to the API"
topic: stratusphere
status: verified
last_reviewed: 2026-10-29
---

# First-time Hub setup

After the Hub VM is running, these are set by hand in its web console (signed in as `ssadmin`; see
[appliances.md](appliances.md#credentials)). The API can't do them: Liquidware documents it as read-only
data access ([api.md](api.md)).

1. **License.** Apply your Stratusphere license (the License screen opens on first sign-in).
2. **API user.** Give a dedicated user API access: Inventory > Users, open the user, tick
   **Allow API Access**. API usernames are `username@domain` as on the Hub's sign-in page. A
   dedicated read-only user is still the practice here, rather than `ssadmin`.
3. **API addresses.** In Hub Administration > Configuration > Security Settings:
   - **Whitelist:** the addresses authenticated API users may call from. Put the exporting machine here.
   - **API Client IPs:** leave it empty. Any address listed there reads the API with **no
     credentials at all**.
   - **Blacklist:** addresses that are refused even with valid credentials.

Source: Liquidware's [Hub Advanced Configuration](https://docs.liquidware.com/stratusphere-671/en-us/security-addendum/hub-advanced-configuration.htm)
and [Configuring Hub settings](https://docs.liquidware.com/stratusphere-671/en-us/installation-guide/configuring-hub-app-settings.htm)
(6.7.1). Change the default `ssadmin` password at first sign-in.

Then, if they exist: point the Hub at the Database appliance, and register each Collector with the
Hub from the Collector's console ([appliances.md](appliances.md)).

Until the API covers these, this stays a checklist in the
[Stratusphere README](https://github.com/nickprignano/avd-liquidware/blob/main/stratusphere/README.md).
