---
title: "Stratusphere in Azure Marketplace"
summary: "Liquidware's Marketplace offer: finding the plan for a region, the plan block a VM needs, and accepting terms per subscription"
topic: azure
status: verified
last_reviewed: 2026-11-10
sources:
  - https://learn.microsoft.com/azure/virtual-machines/marketplace-images
---

# Stratusphere in Azure Marketplace

The appliances are deployed from Liquidware's Azure Marketplace image: publisher `liquidware`,
offer `stratusphere`. Four things have to line up before a VM deploys.

1. **The plan (SKU) offered in your region.** Plan names aren't on the public listing. List them
   with `az vm image list-skus -l <region> -p liquidware -f stratusphere`, or
   `Get-AzVMImageSku`. Liquidware publishes three plans: the Hub, and optional Database and
   Collector plans, available in each region
   ([Installing on Microsoft Azure](https://docs.liquidware.com/stratusphere-671/en-us/installation-guide/installing-on-microsoft.htm)).
   In `centralus` (verified on Stratusphere 6.7), the published plans are `670-2-hub`, `670-2-db`,
   and `670-2-collector`. The Hub plan is bring-your-own-license. The images are Gen 1 VMs
   (`hyperVGeneration: V1`), so Gen 2-only VM series (such as `Dasv5`/`Ddsv5`/`Dasv6`) fail
   deployment with `BadRequest: The selected VM size is not valid for the selected image's
   hyperVGeneration` — choose a SKU whose `HyperVGenerations` capability includes `V1` (such as
   `Standard_D4s_v5`, `Standard_D4s_v4`, or `Standard_D4s_v3`).
2. **A matching `plan` block.** The image carries a purchase plan, so the VM must send a `plan`
   (name, publisher, product) that matches its `imageReference`, or Azure refuses it. The repo's
   Pester tests guard this.
3. **Explicit `FromImage` data disks (`LUN 0` and `LUN 1`).** The `670-2-hub` Marketplace image
   includes two pre-baked data disk images (`lun: 0` and `lun: 1`) alongside the OS disk. When
   deploying via ARM or Bicep (including Azure Verified Modules `avm/res/compute/virtual-machine`),
   passing an empty `dataDisks: []` array fails with
   `InvalidParameter (storageProfile.dataDisks): Keep existing data disks vs. deleting is not supported`.
   Every data disk LUN defined in the Marketplace image must be declared with
   `createOption: 'FromImage'`.
4. **Accepted terms.** Acceptance is per subscription and per plan, and accepting again is harmless:
   `az vm image terms accept` or `Get-AzMarketplaceTerms ... | Set-AzMarketplaceTerms -Accept`
   (in `Az.MarketplaceOrdering`, pipe `$terms` into `Set-AzMarketplaceTerms -Accept` rather than
   combining `-Publisher`/`-Product`/`-Name` with `-Terms`, which belong to different parameter
   sets). It's done by script, not Bicep: the `Microsoft.MarketplaceOrdering` agreement resource
   needs the full terms record read back from Azure first, which a template can't do on its own.

## Gotchas

- **`/var` is mounted `noexec` on the appliance:** Liquidware doesn't support VM extensions or
  cloud-init on Stratusphere appliances, and the 6.7 image mounts `/var` with the `noexec` flag.
  Although `waagent` runs on the appliance, invoking `Invoke-AzVMRunCommand` (`RunShellScript` /
  `Microsoft.CPlat.Core.RunCommandLinux`) fails with exit code `126` (`Permission denied` executing
  `/var/lib/waagent/Microsoft.CPlat.Core.RunCommandLinux-.../bin/run-command-shim`). Use direct
  HTTPS (`443`) to `/lwl/api` or SSH (`22`) from a subnet/jumphost for automation rather than Azure
  VM Run Command.
- An organization that blocks Marketplace purchases, or limits images with Azure Policy, fails the
  deployment at the VM. Check the subscription's policy before the first run.
- A VM's plan can't change after creation.
- Liquidware also offers a VHD download; deploying from it isn't covered here yet.

How-to: [stratusphere/docs/marketplace.md](https://github.com/avd-ops/avd-liquidware/blob/main/stratusphere/docs/marketplace.md).

