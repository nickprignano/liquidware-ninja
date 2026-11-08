---
status: accepted
date: 2026-10-30
---

# 0019. Publish the liquidware-ninja site on Cloudflare Workers under liquidware-ninja.prignano.ai

## Context and Problem Statement

`liquidware-ninja` is the Liquidware second brain, template library, technical blog, and PowerShell toolkit backing our Liquidware and Azure Virtual Desktop work (`avd-liquidware`, `ux-assess`, `flexapp-factory`, and the broader `avd-ops` ecosystem). We want a fast, browser-accessible web front door that presents the knowledge base, interactive graph, technical field notes, and high-level architectural descriptions of both the public and private companion repositories, hosted on Cloudflare under `liquidware-ninja.prignano.ai`.

## Considered Options

- **Option 1: Static site in `site/` built with the vendored `avd-ops` design system (`ds-v2.7.0`) and deployed via Cloudflare Workers Static Assets (`wrangler.jsonc`).** Uses a lightweight Node generator (`scripts/site/build-site.mjs` and `scripts/site/apply-shell.mjs`) to render `docs/knowledge/` (including the Obsidian-compatible link graph) and `blog/` into `site/` alongside hand-written overview pages for `liquidware-ninja`, `avd-liquidware`, `ux-assess` (high-level private overview), `flexapp-factory` (high-level private overview), and the `avd-ops` family. Deploys to `liquidware-ninja.prignano.ai` via `wrangler.jsonc` (`assets.directory = "./site"`).
- **Option 2: Heavyweight external documentation framework (Docusaurus, Astro, or VitePress).** Introduces a separate framework build pipeline, diverges from the `avd-ops` design system tokens and app shell, and duplicates page layouts.
- **Option 3: GitHub Pages only.** Does not use the Cloudflare Workers Static Assets pipeline (`wrangler.jsonc`) standardized across `prignano.ai` properties.

## Decision Outcome

Chosen option: **Option 1 (vendored `avd-ops` design system in `site/` + Cloudflare Workers Static Assets via `wrangler.jsonc`)**, because it keeps visual and structural parity with [avd-ops.dev](https://avd-ops.dev/), serves self-hosted fonts with zero third-party network requests, enforces public-safe guardrails via `tests/site.test.mjs`, and deploys directly to `liquidware-ninja.prignano.ai` on Cloudflare.

### Consequences

- Good, because every knowledge base page (`docs/knowledge/`), decision record, and technical blog post (`blog/`) is automatically rendered into `site/docs/` and `site/blog/` with an interactive link graph (`site/docs/graph.html`).
- Good, because `ux-assess` and `flexapp-factory` are documented at a high architectural level (pipeline stages, pseudonymization/packaging boundaries, and JSON handoff schemas) while keeping their implementation repositories private.
- Good, because `wrangler.jsonc` with `"custom_domain": true` provisions the `liquidware-ninja.prignano.ai` DNS record and TLS certificate directly on the `prignano.ai` Cloudflare zone without a Worker script entrypoint or legacy Cloudflare Pages project.
- Neutral, because editing `docs/knowledge/` or `blog/` requires running `npm run build:site` alongside `python3 scripts/kb/build.py` (enforced by CI in `.github/workflows/site.yml`), and `scripts/site/build-site.mjs` must normalize `\r\n` to `\n` at file-read boundaries so YAML front-matter stripping and responsive table `data-label` generation behave identically on Windows (`core.autocrlf=true`) and Linux CI runners.
