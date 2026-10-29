---
status: proposed
date: 2026-10-29
decision-makers: [maintainers]
---

# 0018. Family format: every scheduled KB issue has a way to a pull request or to closing itself

## Context and Problem Statement

The KB's scheduled workflows open issues (the weekly digest, the monthly freshness check), but only
the feedback forms had a path from an accepted issue to a pull request. Ticked digest items waited
for someone to copy them by hand, unticked digests piled up, and the freshness issue stayed open
after every item was fixed. On a new KB the freshness check also flagged every tracked expert for
zero digest yield before any digest existed, and a transient HTTP 500 from a feed dropped that
source for the week. How should each scheduled issue end?

## Considered Options

- Close each loop in the shared scripts and workflows: a label-gated path to a PR where the issue
  carries a change, and an automatic close where it's stale or clean
- Leave closing to the maintainer, and document the manual steps

## Decision Outcome

Chosen option: "Close each loop in the shared scripts and workflows", because issues that only a
person can close turn into noise, and noise hides the issues that matter.

- **Digest to PR.** `kb-accepted` on a `kb-digest` issue runs `kb-feedback.yml`: `feedback.py` adds
  each ticked item to the page its source names (or the item's own `→ docs/knowledge/<page>.md`
  note) under "From the KB digest", validates, and opens a PR with `Closes #<digest>`. The reviewer
  turns the links into facts before merging. Only https links and existing KB paths are taken from
  the issue.
- **Supersede.** When `kb-curator.yml` opens a digest, it closes older open digests with nothing
  ticked (`curate.py --superseded`), linking the new one.
- **Clean close.** `kb-freshness.yml` closes its open issue when the check finds 0 items.
- **No yield flags on a new KB.** An expert's yield counts only digests since the expert was scored,
  and waits for 4 of them.
- **One retry on 5xx** in `sources.http_get`.
- **Markers.** The freshness counter also matches `*(unverified)*`; prose that names the marker goes
  in backticks.

Unit tests in `scripts/kb/test_kb.py` cover each handler.

### Consequences

- Good, because every scheduled issue now ends in a reviewed PR or closes itself, and the freshness
  issue means "something to do".
- Good, because the label stays the review gate: nothing from an issue merges without a reviewed PR.
- Bad, because a digest PR lands links first; a reviewer who merges without working them in leaves a
  link list on the page.

## More Information

Found in liquidware-ninja, which runs the family format's scripts. Proposed for the family hub
([2ndbrain](https://github.com/nickprignano/2ndbrain)) and the other KBs; this repo applied it ahead
of the hub at the owner's request. The failure modes are in the
[known errors catalog](../troubleshooting/README.md) and [curation.md](../curation.md).
