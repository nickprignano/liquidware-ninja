// The app shell for liquidware-ninja.prignano.ai (vendored avd-ops design system v2.7.0).
// Builds the brand bar, switcher, research-only notice (including Liquidware and Microsoft disclaimers),
// side navigation, and footer.
// Personal project, not for production, as is; not affiliated with the author's employer, Liquidware or Microsoft.

export const GROUPS = [
  ['Start', [
    ['Overview', 'index.html'],
    ['Architecture', 'architecture.html'],
    ['PowerShell toolkit', 'toolkit.html'],
    ['Field notes (Blog)', 'blog/index.html'],
    ['Knowledge base', 'docs/index.html'],
  ]],
  ['Liquidware Repos', [
    ['liquidware-ninja', 'repos/liquidware-ninja.html'],
    ['avd-liquidware', 'repos/avd-liquidware.html'],
    ['ux-assess (private)', 'repos/ux-assess.html'],
    ['flexapp-factory (private)', 'repos/flexapp-factory.html'],
    ['avd-ops family', 'index.html#avd-ops'],
  ]],
  ['Knowledge Base', [
    ['Products & docs', 'docs/liquidware/products.html'],
    ['Multi-platform matrix', 'docs/platforms/multi-platform-matrix.html'],
    ['Fit with AVD & FSLogix', 'docs/avd/fit-with-avd-and-fslogix.html'],
    ['Stratusphere API', 'docs/stratusphere/api.html'],
    ['SpotCheck & sizing', 'docs/stratusphere/spotcheck-and-sizing.html'],
    ['ProfileUnity & Portability', 'docs/profileunity/architecture-and-portability.html'],
    ['FlexApp & App Attach', 'docs/flexapp/packaging-and-delivery.html'],
    ['CommandCTRL', 'docs/commandctrl/overview.html'],
    ['Deployment gotchas', 'docs/deployment/gotchas.html'],
    ['Known errors', 'docs/troubleshooting/index.html'],
    ['Decisions', 'docs/decisions/index.html'],
    ['Graph', 'docs/graph.html'],
  ]],
];

export const SWITCHER = [
  ['Liquidware', 'index.html'],
  ['KB', 'docs/index.html'],
  ['Blog', 'blog/index.html'],
  ['avd-ops.dev', 'https://avd-ops.dev/'],
];

export const brand = (href, src) => `<a class="brand" href="${href}"><img class="mark" src="${src}" alt="" width="44" height="44"><span class="name"><span class="word">liquidware-ninja</span><span class="tag">Second brain &amp; toolkit</span></span></a>`;
export const SKIP = '<a class="skip" href="#main">Skip to content</a>';
export const TRADEMARKS = '<p>Public repositories are open source under the MIT License (with 2ndbrain knowledge base tooling under Apache-2.0); private companion repositories reserve all rights. Liquidware, Stratusphere, ProfileUnity, FlexApp, Connector ID and CommandCTRL are trademarks of Liquidware Labs, Inc.; Azure, Azure Virtual Desktop, Windows 365, Microsoft Entra, Intune and FSLogix are trademarks of Microsoft.</p>';
export const CREDIT = '<p class="credit">A <a href="https://prignano.ai/">prignano.ai</a> production · Part of <a href="https://avd-ops.dev/">avd-ops</a></p>';

export const SUN = '<svg class="sun" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><circle cx="10" cy="10" r="3.5"/><path d="M10 1.8v2.2M10 16v2.2M1.8 10H4M16 10h2.2M4.2 4.2l1.6 1.6M14.2 14.2l1.6 1.6M4.2 15.8l1.6-1.6M14.2 5.8l1.6-1.6"/></svg>';
export const MOON = '<svg class="moon" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" aria-hidden="true"><path d="M16.5 12.4A7 7 0 0 1 7.6 3.5a7 7 0 1 0 8.9 8.9Z"/></svg>';
const MENU = '<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true"><path d="M3 5.5h14M3 10h14M3 14.5h14"/></svg>';

export const themeButton = () => `<button class="iconbtn theme" type="button" aria-label="Switch theme">${SUN}${MOON}</button>`;

export const NOTICE = (up) => `<details class="notice"><summary><strong class="long">Personal project. Research and learning only. Not for production. No warranty.</strong><strong class="short">Not for production</strong></summary>
<div class="full"><ul><li>Built on my own time for research and learning. Not affiliated with, endorsed by or supported by my employer, Liquidware or Microsoft.</li>
<li>Bring your own Liquidware licenses. Don't run any of it in production or against tenants and subscriptions that matter. Test in a dedicated lab first.</li>
<li>Provided "as is", without warranty of any kind, under each repository's license. You use it at your own risk and own the Azure charges it incurs.</li>
<li><strong>Contributions and forks are welcome and encouraged on public repos.</strong> See <a href="${up}index.html#contribute">Contribute</a>.</li></ul></div></details>`;

export function shellHead(up) {
  return `<link rel="icon" href="${up}assets/brand/favicon.svg" type="image/svg+xml">
<link rel="stylesheet" href="${up}assets/avd-ops.css">
<link rel="stylesheet" href="${up}assets/avd-ops-shell.css">
<link rel="stylesheet" href="${up}assets/site.css">
<script src="${up}assets/theme.js"></script>`;
}

function mark(href, current) {
  if (href.includes('#')) return '';
  if (href === current) return ' aria-current="page"';
  if (href === 'docs/decisions/index.html' && current.startsWith('docs/decisions/')) return ' aria-current="true"';
  if (href === 'blog/index.html' && current.startsWith('blog/') && current !== 'blog/index.html') return ' aria-current="true"';
  return '';
}

function switcherCurrent(target, current) {
  if (target.startsWith('https://')) return '';
  if (target === 'docs/index.html' && current.startsWith('docs/')) return ' aria-current="true"';
  if (target === 'blog/index.html' && current.startsWith('blog/')) return ' aria-current="true"';
  if (target === 'index.html' && !current.startsWith('docs/') && !current.startsWith('blog/')) return ' aria-current="true"';
  return '';
}

export function shellTop(up, current) {
  const switcher = SWITCHER.map(([t, href]) => (href.startsWith('https://')
    ? `<a href="${href}">${t}</a>`
    : `<a href="${up}${href}"${switcherCurrent(href, current)}>${t}</a>`)).join('');
  const side = GROUPS.map(([g, items]) => `<p class="group">${g}</p>${items.map(([t, href]) => `<a href="${up}${href}"${mark(href, current)}>${t}</a>`).join('')}`).join('\n');
  return `${SKIP}
<header class="bar"><div class="bar-in">${brand(`${up}index.html`, `${up}assets/brand/mark.svg`)}
<nav class="switcher" aria-label="Site sections">${switcher}</nav>
${NOTICE(up)}
<div class="tools">${themeButton()}<button class="iconbtn menu" type="button" aria-label="Pages" aria-expanded="false" aria-controls="side">${MENU}</button></div></div></header>
<div class="layout"><nav class="side" id="side" aria-label="Pages">
${side}
</nav>`;
}

export function shellFoot(extra) {
  return `</div>
<footer class="foot"><div class="in">${extra}
${TRADEMARKS}
${CREDIT}</div></footer>
<button class="backdrop" type="button" tabindex="-1" aria-label="Close the pages list"></button>`;
}
