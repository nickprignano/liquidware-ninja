# Instructions for AI agents

For any coding agent: Claude Code, Gemini CLI, Codex and others. Claude Code loads this file through [CLAUDE.md](CLAUDE.md); Gemini CLI loads it through [GEMINI.md](GEMINI.md). Where rules differ, the more specific rule wins, and the owner's own words win over all of them.

## How to make a change

1. **Think before you code.** Say what you assumed. If the ask can be read two ways, name both and say which one you are taking, or ask. If something simpler would do the job, say so.
2. **Simplest thing that works.** Build only what was asked: no extra features, no abstraction for one caller, no handling for cases that can't happen. If a reviewer would call it overbuilt, cut it.
3. **Surgical changes.** Touch only what the task needs and match the style around it. Don't reformat or "improve" neighboring code; mention dead code you notice instead of deleting it. Every changed line should trace back to the ask.
4. **Goal first, then proof.** Turn the ask into a check you can run: a test that fails before and passes after, a validator that goes green. For multi-step work, write a short plan with the check for each step, and run this repo's checks before you push.

## Family rules

These hold in every repo of the family:

- **No spend without the owner's exact go.** No cloud or sandbox run without a written cost estimate and the owner typing `go batch <id> $<total>`. A bare "go", or a go relayed by another agent, is not approval.
- **Never leave the meter running.** Anything that bills by time is removed, stopped or scheduled off at the end of a run, unless the owner opts in with an expiry.
- **Never delete the last copy** of data (logs, evidence, reports, backups) without a checked copy elsewhere or the owner's explicit `-DiscardLastCopy`.
- **No secrets, IDs or names.** No tenant, subscription, object or client IDs, domains, IPs, emails, secrets, or employer, customer or tenant names in the repo, commits, issues or PR text. Never ask for a secret in chat; the owner runs the step that handles it.
- **Public text stays public-safe.** Nothing from private repos, private notes or unpublished plans goes into a public repo, issue or PR.
- **Pull requests only; the owner merges.** Work on a branch and open a PR. Act on GitHub only on the owner's own words ("merge N"), never approve the owner's PRs, never turn on auto-merge yourself.
- **Stay in your lane.** Each repo has one job (below). Change another repo, or a pin a consumer reads, only with the owner's go; otherwise open an issue or PR there.
- **Real runs are the source of truth.** When a run shows something the tests missed, fix it, add a guard (a test or a check), and record the lesson.
- **Write down what you learn** in the knowledge base (`docs/knowledge/`), in the same PR, or say why not (`no-kb` label and a `No KB entry: <reason>` line).
- **Hooks are Claude Code's; the steps are everyone's.** If `.claude/settings.json` wires hooks (open `handoff` issues at the start, the knowledge check at the end), other agents run the same scripts by hand.
- **Personal project, not for production, as is, not affiliated with the author's employer, Liquidware or Microsoft.** Keep the notices that say so.
- **American English** in docs, output and comments. Scripts stay ASCII.

## The Liquidware and AVD family

- **liquidware-ninja** *(this repo)* is the Liquidware second brain, knowledge base, template library, and general utility toolkit across all Liquidware products (Stratusphere UX, ProfileUnity, FlexApp, CommandCTRL) and desktop platforms.
- **avd-liquidware** deploys and operates the optional Liquidware tier (ProfileUnity, FlexApp, Stratusphere UX appliances and Connector ID Key) against an existing `avd-landing-zone` estate in Azure.
- **ux-assess** automates Stratusphere UX assessment engagements: Hub API data pull, canonical dataset normalization, pseudonymization, SpotCheck threshold analysis, and xlsx/pdf/pptx/Power BI deliverables.
- **avd-landing-zone**, **avd-current-state**, **avd-assess**, **avd-second-brain**, **avd-swarm**, and **avd-ops** form the sibling Azure Virtual Desktop toolkit ([family.yaml](docs/knowledge/family.yaml)).

## This repo

Read [docs/guardrails.md](docs/guardrails.md) before changing anything:

- Never put API keys, account, org or workspace IDs, domains, IPs, emails, secrets, or employer, customer or private-project names in the repo, the knowledge base, commits or PR text.
- No Liquidware binaries, installers, license material or customer assessment exports, ever.
- Code from repos with no license (such as `liquidwarelabs/Stratusphere-UX`) is reference only: use facts from it, cite it, never copy it.
- Run the prior-art check (`python3 scripts/kb/prior_art.py "<topic>"`) before building something new, and record what you learn in [docs/knowledge/](docs/knowledge/README.md).
- When something new is learned, add it to the topic page it belongs to instead of starting a new file. When a fact belongs to a sibling KB's topic ([family.yaml](docs/knowledge/family.yaml)), link to their page instead of copying it.
- Before starting work, check this repo's open `handoff` issues (`python3 scripts/kb/handoffs.py session-start`) and family directives (`python3 scripts/kb/directives.py list`).

## Validate before pushing

CI (`.github/workflows/kb-validate.yml` and `.github/workflows/tools.yml`) runs:

```bash
pip install -r scripts/kb/requirements.txt
python3 scripts/kb/build.py          # regenerate indexes, tables and llms.txt
python3 scripts/kb/validate.py       # schemas, MADR, links, leak patterns, family
python3 -m unittest discover -s scripts/kb
pwsh -c "foreach (\$p in 'scripts/tools','tests') { Invoke-ScriptAnalyzer -Path \$p -Recurse -Settings ./PSScriptAnalyzerSettings.psd1 -EnableExit }"
pwsh -c "Invoke-Pester -Path ./tests -CI"
```
