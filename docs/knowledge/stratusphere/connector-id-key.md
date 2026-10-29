---
title: "Connector ID Key"
summary: "The Stratusphere agent on each desktop: installer switches, callbacks to the Hub, where its services and settings live, and images created later"
topic: stratusphere
status: verified
last_reviewed: 2026-10-29
sources:
  - https://support.liquidware.com/hc/en-us/articles/210640563-My-Stratusphere-does-not-receive-the-data-from-systems-where-Connector-ID-is-installed
  - https://support.liquidware.com/hc/en-us/articles/210640503-Where-are-all-the-Stratusphere-Connector-ID-settings-are-stored-on-the-system
  - https://support.liquidware.com/hc/en-us/articles/210640343-What-command-line-options-are-available-to-me-during-manual-connector-id-install
  - https://support.liquidware.com/hc/en-us/articles/25397734649741-Connector-ID-Exclusion-list-for-Antivirus
---

# Connector ID Key

The Connector ID Key is Stratusphere's agent on each desktop. It calls back to the Hub (or a
Collector) with what it measures. This repo rolls it out with
[`Deploy-CidKey.ps1`](https://github.com/nickprignano/avd-liquidware/blob/main/stratusphere/docs/agent-rollout.md); this page holds the facts.
Everything here cites Liquidware's support center or documentation; none of it has been through a
lab run on real machines yet. Paths and the settings key changed in 6.7, so check the version.

## Installer

- Download it from your own Hub (Hub Administration > Connector ID Keys). It's never stored in this
  repo.
- Silent install: `<installer>.exe /s HUBADDRESS=<hub-fqdn-or-ip>`. Other properties:
  `MACHINEGROUP=`, `USERGROUP=`, `INSTALLDIR=`, and logging with `/l="C:\full\path.txt"`.
- Silent uninstall: `<installer>.exe /x /s`, or `/s REMOVE=TRUE` (Liquidware notes it sometimes
  needs running twice).
- The MSI is for Group Policy only: used outside Group Policy it doesn't uninstall cleanly. Scripted
  installs use the EXE.
- Liquidware doesn't publish the installer's exit codes. Don't trust exit code 0 alone: check that
  the services exist and are running afterwards (an asked-for gap, [upstream.md](../liquidware/upstream.md)).

Sources: [command line options](https://support.liquidware.com/hc/en-us/articles/210640343-What-command-line-options-are-available-to-me-during-manual-connector-id-install),
[Intune deployment](https://support.liquidware.com/hc/en-us/articles/38733480781453-Deploy-the-Stratusphere-UX-Connector-ID-Key-with-Intune).

## On the machine

- Services: `tntgrd`, `tntdatasvc` and `tntupdsvc`
  ([antivirus exclusions article](https://support.liquidware.com/hc/en-us/articles/25397734649741-Connector-ID-Exclusion-list-for-Antivirus)).
- Settings key: `HKLM\SOFTWARE\Liquidware Labs\Connector ID` from 6.7. Up to 6.6.2-2 on 64-bit
  Windows it was `HKLM\SOFTWARE\Wow6432Node\Liquidware Labs\ConnectorID` (no space). It holds
  `hubAddress`, `GROUP` and `USERGROUP` for Group Policy installs.
- Program folder: `C:\Program Files\Liquidware\Connector ID` from 6.7; before 6.7,
  `C:\Program Files (x86)\Liquidware Labs\Connector ID`.
- `idcontrol.exe` in the program folder controls the key from a script: `start`, `stop`, `status`,
  `properties`, `callback` (force a report), `debug on|off`, `version`.
- A `ca\cert.txt` file in the program folder means the key received its first instructions from the Hub
  ([support article](https://support.liquidware.com/hc/en-us/articles/210640503-Where-are-all-the-Stratusphere-Connector-ID-settings-are-stored-on-the-system)).

## Callbacks

The key calls the Hub on TCP 443. An NSG or firewall between the desktops and the Hub must allow it
([azure/networking.md](../azure/networking.md)).

- The address it calls is the first line of `ca\public\mgrcert.pem` in the program folder. It
  comes from the Hub's DNS name (Configuration > Edit Network Configuration) when the installer was
  downloaded, so set the Hub's DNS name before downloading the installer. A key with the wrong
  address needs reinstalling from a fresh download, or `mgrcert.pem` edited and its service
  restarted
  ([support article](https://support.liquidware.com/hc/en-us/articles/210640563-My-Stratusphere-does-not-receive-the-data-from-systems-where-Connector-ID-is-installed)).
- Desktops that can't reach the Hub can register with a CID Collector instead (Stratusphere 6.5.1
  or later can use the Collector's name as the callback address)
  ([support article](https://support.liquidware.com/hc/en-us/articles/360016241452-Force-Connector-ID-Agents-to-Register-with-a-CID-Collector-using-Windows-Auto-register-Installer)).
  The `mgrcert.pem` can't be downloaded from a Collector; copy it from a working machine.

## Desktops created later

Azure Run Command reaches only the machines that exist when it runs. Session hosts created later
from an image need the key in the golden image, or an Intune or Group Policy assignment. The image
side belongs to the AVD knowledge base ([family.yaml](../family.yaml)).
