---
title: "Known errors"
summary: "Errors hit in this project: symptom, cause, fix and source"
topic: troubleshooting
status: verified
last_reviewed: 2026-10-29
---

# Known errors

Errors we've hit, what caused them and what fixed them. The table is generated from
[known-errors.yaml](known-errors.yaml); fixes marked `*(unverified)*` haven't been confirmed yet.

<!-- BEGIN GENERATED: known-errors (edit the YAML, then run scripts/kb/build.py) -->
| Symptom | Cause | Fix | Source |
|---|---|---|---|
| Connector ID Keys are installed but the Hub shows no data from them | The key calls the address in its mgrcert.pem, taken from the Hub's DNS name when the installer was downloaded; the address is wrong or unreachable on TCP 443 | Set the Hub's DNS name (Configuration > Edit Network Configuration), download the installer again and reinstall, or edit mgrcert.pem and restart the key's service; allow TCP 443 from the desktops to the Hub | [link](https://support.liquidware.com/hc/en-us/articles/210640563-My-Stratusphere-does-not-receive-the-data-from-systems-where-Connector-ID-is-installed) |
| On a multi-session AVD host using FlexApp through app attach or RemoteApp, the first user's app launches but the next user's never does | The Click-To-Layer engine's extra validation fails falsely for the second session | As an administrator, set Validate to False in C:\Program Files\ProfileUnity\FlexApp\CTL\JitCut.dll.config, then restart the host to clear stuck sessions | [link](https://support.liquidware.com/hc/en-us/articles/44141398744845-Second-user-gets-no-FlexApp-on-Multi-Session-AVD-using-AppAttach-RemoteApp) |
| "License Not Authorized" from the Stratusphere API after the license was updated | The API module caches the previous license | Restart the Hub appliance | [link](https://support.liquidware.com/hc/en-us/articles/210641343-After-updating-the-license-API-access-returns-License-Not-Authorized-error) |
| kb-freshness lists every tracked expert as "nothing in the digests since <date>; check the feed still works" on a new KB | Expert yield was computed from digest issues before any existed, or before a newly scored expert had a month of digests | freshness.py counts only digests since the expert was scored and skips the check until MIN_DIGESTS (4) exist | [curation.md](../curation.md#freshness-check-kb-freshness) |
| kb-freshness counts unverified claims on a page whose only match is prose about the marker, and misses claims marked *(unverified)* | The inline-marker regex matched the word inside instructions and bold **Unverified labels, and didn't allow a parenthesis after the asterisk | The regex now matches *(unverified)* and skips bold labels; write prose that names the marker in backticks so it's ignored | [curation.md](../curation.md#freshness-check-kb-freshness) |
| Unticked kb-digest issues pile up week after week, and the kb-freshness issue stays open after every item is fixed | The curator only opened digests and the freshness job only ran its issue step when items != 0; nothing closed an issue once it was stale or clean | A new digest closes older open digests with nothing ticked, linking the new one; the freshness job closes its issue when the check finds 0 items | [curation.md](../curation.md#weekly-digest-kb-curator) |
| A curator source fails with "HTTPError: HTTP Error 500: Internal Server Error" (seen in the family on YouTube channel feeds) | The feed host returns transient 5xx responses | sources.http_get retries a 5xx once after 5 seconds; a source that still fails is listed at the bottom of the digest | [curation.md](../curation.md#weekly-digest-kb-curator) |
<!-- END GENERATED: known-errors -->

## Adding an entry

Add an entry to [known-errors.yaml](known-errors.yaml) with the exact error text as the symptom,
the versions it was seen on in `applies_to`, and a `source` (a KB page or an https link). Or open a
**Known error** issue, and a maintainer turns it into a pull request.
