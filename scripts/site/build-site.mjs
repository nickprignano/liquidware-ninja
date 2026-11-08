// Builds site/docs/ (from docs/knowledge/), site/blog/ (from blog/), and site/llms.txt (from llms.txt).
// Personal project, not for production, as is; not affiliated with the author's employer, Liquidware or Microsoft.
//
//   node scripts/site/build-site.mjs           # write site/docs/, site/blog/, site/llms.txt
//   node scripts/site/build-site.mjs --check   # fail if generated site files are out of date (CI)
import { readFileSync, writeFileSync, readdirSync, mkdirSync, rmSync, existsSync, statSync } from 'node:fs';
import { dirname, join, relative, posix } from 'node:path';
import { fileURLToPath } from 'node:url';
import { marked } from 'marked';
import { graphHealth } from './graph-health.mjs';
import { shellHead, shellTop, shellFoot } from './shell.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const KB = 'docs/knowledge';
const BLOG = 'blog';
const OUT_DOCS = 'site/docs';
const OUT_BLOG = 'site/blog';
const REPO = 'https://github.com/nickprignano/liquidware-ninja/blob/main/';

const PUBLISHED_KB = [
  /^README\.md$/,
  /^liquidware\//,
  /^platforms\//,
  /^avd\//,
  /^stratusphere\//,
  /^profileunity\//,
  /^flexapp\//,
  /^commandctrl\//,
  /^azure\//,
  /^deployment\//,
  /^troubleshooting\/README\.md$/,
  /^roadmap\/README\.md$/,
  /^curation\.md$/,
  /^experts\.md$/,
  /^decisions\/(README|\d{4}-[\w-]+)\.md$/,
];

const SECTIONS = [
  ['Knowledge base', 'README.md'],
  ['Liquidware', 'liquidware/products.md'],
  ['Platforms', 'platforms/multi-platform-matrix.md'],
  ['AVD & FSLogix', 'avd/fit-with-avd-and-fslogix.md'],
  ['Stratusphere UX', 'stratusphere/api.md'],
  ['ProfileUnity', 'profileunity/architecture-and-portability.md'],
  ['FlexApp', 'flexapp/packaging-and-delivery.md'],
  ['CommandCTRL', 'commandctrl/overview.md'],
  ['Azure', 'azure/marketplace.md'],
  ['Deployment', 'deployment/gotchas.md'],
  ['Troubleshooting', 'troubleshooting/README.md'],
  ['Roadmap', 'roadmap/README.md'],
  ['Decisions', 'decisions/README.md'],
];

const walk = (d) => readdirSync(join(root, d)).flatMap((f) => {
  const p = `${d}/${f}`;
  return statSync(join(root, p)).isDirectory() ? walk(p) : [p];
});

function plain(html) {
  let out = '';
  let inTag = false;
  for (const c of html) {
    if (c === '<') inTag = true;
    else if (c === '>') inTag = false;
    else if (!inTag) out += c;
  }
  return out;
}
const unesc = (s) => s.replace(/&#39;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function frontMatter(text) {
  const norm = text.replace(/\r\n/g, '\n');
  const m = norm.match(/^---\n([\s\S]*?)\n---\n/);
  const meta = {};
  if (m) {
    let currentListKey = null;
    for (const line of m[1].split('\n')) {
      const listMatch = line.match(/^\s*-\s+(.+)$/);
      if (listMatch && currentListKey) {
        meta[currentListKey].push(listMatch[1].trim().replace(/^["']|["']$/g, ''));
        continue;
      }
      const kv = line.match(/^(\w[\w-]*):\s*(.*)$/);
      if (kv) {
        const key = kv[1];
        const val = kv[2].trim();
        if (!val) {
          currentListKey = key;
          meta[key] = [];
        } else {
          currentListKey = null;
          meta[key] = val.replace(/^["']|["']$/g, '');
        }
      }
    }
  }
  return { meta, body: m ? norm.slice(m[0].length) : norm };
}

function slugger() {
  const seen = new Map();
  return (text) => {
    const base = unesc(plain(text)).trim().toLowerCase().replace(/[^\w\- ]/g, '').replace(/ /g, '-');
    const n = seen.get(base) || 0;
    seen.set(base, n + 1);
    return n ? `${base}-${n}` : base;
  };
}

function stack(table) {
  const cols = [...(table.match(/<thead>[\s\S]*?<\/thead>/) || [''])[0].matchAll(/<th[^>]*>([\s\S]*?)<\/th>/g)].map((m) => unesc(plain(m[1])).trim());
  return table.replace('<table>', '<table class="stacked">').replace(/<tbody>[\s\S]*<\/tbody>/, (body) => body.replace(/<tr>([\s\S]*?)<\/tr>/g,
    (_, row) => { let i = 0; return `<tr>${row.replace(/<td([^>]*)>/g, (m, a) => `<td${a} data-label="${esc(cols[i++] || '')}">`)}</tr>`; }));
}

function urlOfKb(src) {
  if (src === 'README.md') return 'index.html';
  return src.replace(/README\.md$/, 'index.html').replace(/\.md$/, '.html');
}

function buildDocs() {
  const sources = walk(KB).map((p) => p.slice(KB.length + 1)).filter((p) => p.endsWith('.md') && PUBLISHED_KB.some((re) => re.test(p))).sort();
  const pages = sources.map((src) => {
    const { meta, body } = frontMatter(readFileSync(join(root, KB, src), 'utf8'));
    const h1 = (body.match(/^# (.+)$/m) || [, src])[1];
    return {
      src,
      url: urlOfKb(src),
      title: h1,
      summary: meta.summary || (src.startsWith('decisions/') ? `Decision record (${meta.status || 'proposed'})` : 'Knowledge base reference'),
      topic: meta.topic || (src.includes('/') ? src.split('/')[0] : 'overview'),
      status: meta.status || '',
      lastReviewed: meta.last_reviewed || meta.date || '',
      body,
      links: [],
    };
  });
  const bySrc = new Map(pages.map((p) => [p.src, p]));

  function rewriteKb(page, href) {
    if (/^([a-z]+:|#)/i.test(href)) return href;
    const [pathPart, hash] = href.split('#');
    let target = posix.normalize(posix.join(posix.dirname(page.src), pathPart));
    if (bySrc.has(`${target}/README.md`)) target = `${target}/README.md`;
    const to = bySrc.get(target);
    if (to) {
      if (!page.links.includes(to.src) && to.src !== page.src) page.links.push(to.src);
      return posix.relative(posix.dirname(page.url), to.url) + (hash ? `#${hash}` : '');
    }
    const repoRel = posix.normalize(posix.join(KB, posix.dirname(page.src), pathPart));
    return REPO + repoRel + (hash ? `#${hash}` : '');
  }

  function renderKb(page, md) {
    const renderer = new marked.Renderer();
    const link = renderer.link.bind(renderer);
    renderer.link = (token) => link({ ...token, href: rewriteKb(page, token.href) });
    return marked.parse(md, { renderer, gfm: true });
  }

  function screens(page) {
    const slug = slugger();
    const list = [];
    let fence = false;
    for (const line of page.body.split('\n')) {
      if (/^(```|~~~)/.test(line)) fence = !fence;
      const h = !fence && line.match(/^(#{1,2}) (.+)$/);
      if (h) list.push({ title: h[2].trim(), level: h[1].length, parts: [[]] });
      else if (list.length && !fence && /^<!-- more -->\s*$/.test(line)) list.at(-1).parts.push([]);
      else if (list.length) list.at(-1).parts.at(-1).push(line);
    }
    return list.map((s, idx) => {
      const id = slug(s.title);
      const [shown, ...rest] = s.parts.map((lines) => lines.join('\n'));
      const sub = (html) => html.replace(/<h([34])>([\s\S]*?)<\/h\1>/g, (_, n, t) => `<h${n} id="${slug(t)}">${t}</h${n}>`)
        .replace(/<table>[\s\S]*?<\/table>/g, (t) => `<div class="tbl" tabindex="0" role="region" aria-label="${esc(plain(s.title))} table">${stack(t)}</div>`);
      const head = marked.parseInline(s.title);
      const lead = sub(renderKb(page, shown)).replace(/^<p>/, '<p class="bl">');
      const more = rest.length ? `\n<details class="more"><summary>More</summary>\n${sub(renderKb(page, rest.join('\n')))}</details>\n` : '';
      const metaBar = idx === 0 && (page.status || page.lastReviewed)
        ? `<div class="kb-meta">${page.status ? `<span class="badge b-${esc(page.status.toLowerCase())}">${esc(page.status)}</span>` : ''}${page.lastReviewed ? `<span>Reviewed ${esc(page.lastReviewed)}</span>` : ''}<span>Source: <a href="${REPO}${KB}/${page.src}">${esc(page.src)}</a></span></div>\n`
        : '';
      return { id, title: plain(head), html: `<section class="screen" id="${id}">\n<h${s.level} tabindex="-1">${head}</h${s.level}>\n${metaBar}${lead}${more}</section>` };
    });
  }

  function wrapDoc({ url, title, summary, content }) {
    const up = '../'.repeat(url.split('/').length);
    const foot = `<p>Built from the 2ndbrain knowledge base in <a href="https://github.com/nickprignano/liquidware-ninja/tree/main/${KB}">${KB}/</a>. Open the folder in Obsidian to browse it as a vault.</p>`;
    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>${esc(title)} | liquidware-ninja KB</title>
<meta name="description" content="${esc(summary)}">
${shellHead(up)}
</head>
<body class="shell">
<!-- Generated by scripts/site/build-site.mjs from ${KB}/. Do not edit; edit the Markdown and rebuild. -->
${shellTop(up, `docs/${url}`)}
<main id="main"><div class="col">
${content}
</div></main>
${shellFoot(foot)}
</body>
</html>
`;
  }

  const files = new Map();
  for (const p of pages) p.screens = screens(p);

  const order = [];
  for (const [, s] of SECTIONS) {
    const prefix = s.includes('/') ? s.split('/')[0] + '/' : s;
    const groupPages = pages.filter((p) => (s.includes('/') ? p.src.startsWith(prefix) : p.src === s))
      .sort((a, b) => (a.src === s ? -1 : b.src === s ? 1 : a.src.localeCompare(b.src)));
    for (const gp of groupPages) if (!order.includes(gp)) order.push(gp);
  }
  for (const p of pages) if (!order.includes(p)) order.push(p);

  for (const [i, p] of order.entries()) {
    const rel = (q) => posix.relative(posix.dirname(p.url), q.url);
    const back = pages.filter((q) => q.links.includes(p.src));
    const backlinks = back.length
      ? `<details class="more linked"><summary>Linked from ${back.length === 1 ? 'one page' : `${back.length} pages`}</summary>\n<ul class="backlinks">${back.map((q) => `<li><a href="${rel(q)}">${esc(q.title)}</a></li>`).join('')}</ul></details>\n`
      : '';
    const prev = order[i - 1];
    const next = order[i + 1];
    const steps = p.screens.length > 1
      ? `<nav class="sc-steps" aria-label="On this page"><ol>${p.screens.map((s, n) => `<li><a href="#${s.id}" title="${esc(s.title)}"><span class="n">${n + 1}</span><span class="t">${esc(s.title)}</span></a></li>`).join('')}</ol></nav>\n`
      : '';
    const nav = `<nav class="sc-nav" aria-label="Back and next"><div class="in">${prev ? `<a class="sc-back" href="${rel(prev)}" data-page="${esc(prev.title)}">Back</a>` : '<a class="sc-back" hidden>Back</a>'}`
      + `<span class="where">${esc(p.screens[0].title)}</span>`
      + `${next ? `<a class="sc-next" href="${rel(next)}" data-page="${esc(next.title)}">Next<span class="pg">: ${esc(next.title)}</span></a>` : '<a class="sc-next" hidden>Next</a>'}</div></nav>`;
    const content = `<article class="screens">\n${steps}${p.screens.map((s, n) => (n === p.screens.length - 1 ? s.html.replace(/<\/section>$/, `${backlinks}</section>`) : s.html)).join('\n')}\n${nav}\n</article>\n<script src="${'../'.repeat(p.url.split('/').length)}assets/docs.js" defer></script>`;
    files.set(p.url, wrapDoc({ url: p.url, title: p.title, summary: p.summary, content }));
  }

  const graph = {
    nodes: pages.map((p) => ({
      id: p.src,
      title: p.title,
      url: p.url,
      topic: p.topic,
      ...(p.status ? { status: p.status } : {}),
      ...(SECTIONS.some(([, s]) => s === p.src) ? { section: true } : {}),
    })),
    links: pages.flatMap((p) => p.links.map((t) => ({ source: p.src, target: t }))),
  };
  files.set('graph.json', `${JSON.stringify(graph, null, 1)}\n`);
  const { hubs } = graphHealth(graph);
  files.set('graph.html', wrapDoc({
    url: 'graph.html',
    title: 'Knowledge Base Graph',
    summary: 'Every knowledge base page in liquidware-ninja and the links between them.',
    content: `<h1>Knowledge Base Graph</h1>
<p class="lede">Every page in the Liquidware second brain and the links between them—the same graph Obsidian draws from <code>docs/knowledge/</code>. Select a node to open its page.</p>
<h2 id="map">Map</h2>
<div class="graph" data-src="graph.json"><svg role="img" aria-label="Graph of the knowledge base pages and their links"></svg></div>
<h2 id="most-linked">Most linked</h2>
<p>The reference pages most other topics link to.</p>
<ol>${hubs.map((h) => `<li><a href="${h.url}">${esc(h.title)}</a> (linked from ${h.linkedFrom})</li>`).join('')}</ol>
<h2 id="pages">All pages (${pages.length})</h2>
<ul>${pages.map((p) => `<li><a href="${p.url}">${esc(p.title)}</a> <span class="mono">(${esc(p.topic)})</span></li>`).join('')}</ul>
<script src="../assets/graph.js" defer></script>`,
  }));

  return { files, bySrc };
}

function buildBlog(kbBySrc) {
  const postFiles = readdirSync(join(root, BLOG)).filter((f) => f.endsWith('.md') && f !== 'README.md').sort().reverse();
  const posts = postFiles.map((file) => {
    const { meta, body } = frontMatter(readFileSync(join(root, BLOG, file), 'utf8'));
    const slug = file.replace(/\.md$/, '.html');
    const h1 = (body.match(/^# (.+)$/m) || [, meta.title || file])[1];
    return {
      file,
      url: slug,
      title: meta.title || h1,
      date: meta.date || '',
      summary: meta.summary || '',
      tags: Array.isArray(meta.tags) ? meta.tags : [],
      status: meta.status || 'published',
      body,
    };
  });

  function rewriteBlogLink(href) {
    if (/^([a-z]+:|#)/i.test(href)) return href;
    const [pathPart, hash] = href.split('#');
    const repoRel = posix.normalize(posix.join(BLOG, pathPart));
    if (repoRel.startsWith(`${KB}/`)) {
      const kbRel = repoRel.slice(KB.length + 1);
      const to = kbBySrc.get(kbRel) || kbBySrc.get(`${kbRel}/README.md`);
      if (to) return `../docs/${to.url}${hash ? `#${hash}` : ''}`;
    }
    return REPO + repoRel + (hash ? `#${hash}` : '');
  }

  function renderBlog(post) {
    const slug = slugger();
    const renderer = new marked.Renderer();
    const link = renderer.link.bind(renderer);
    renderer.link = (token) => link({ ...token, href: rewriteBlogLink(token.href) });
    // Strip the redundant top-level # H1 and blockquote disclaimer so we render our structured post header
    const cleaned = post.body
      .replace(/^\s*# .+\n+/, '')
      .replace(/^\s*> \*\*Personal project\.[\s\S]*?\n\n/, '');
    const rawHtml = marked.parse(cleaned, { renderer, gfm: true });
    return rawHtml
      .replace(/<h([234])>([\s\S]*?)<\/h\1>/g, (_, n, t) => `<h${n} id="${slug(t)}">${t}</h${n}>`)
      .replace(/<table>[\s\S]*?<\/table>/g, (t) => `<div class="tbl" tabindex="0" role="region" aria-label="${esc(post.title)} data table">${stack(t)}</div>`);
  }

  function wrapBlog({ url, title, summary, content }) {
    const up = '../';
    const foot = `<p>Published from <a href="https://github.com/nickprignano/liquidware-ninja/tree/main/${BLOG}">${BLOG}/</a> in <a href="https://github.com/nickprignano/liquidware-ninja">nickprignano/liquidware-ninja</a>.</p>`;
    return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>${esc(title)} | liquidware-ninja</title>
<meta name="description" content="${esc(summary)}">
${shellHead(up)}
</head>
<body class="shell">
<!-- Generated by scripts/site/build-site.mjs from ${BLOG}/. Do not edit; edit the Markdown and rebuild. -->
${shellTop(up, `blog/${url}`)}
<main id="main"><div class="col">
${content}
</div></main>
${shellFoot(foot)}
</body>
</html>
`;
  }

  const files = new Map();
  for (const p of posts) {
    const tagsHtml = p.tags.length ? `<div class="chips">${p.tags.map((t) => `<span class="chip">${esc(t)}</span>`).join('')}</div>` : '';
    const content = `<article class="post-body">
<p class="eyebrow"><a href="index.html">Field notes</a> · ${esc(p.date)}</p>
<h1>${esc(p.title)}</h1>
<p class="lede">${esc(p.summary)}</p>
${tagsHtml}
${renderBlog(p)}
<hr>
<p><a class="cta ghost" href="index.html">All field notes</a> <a class="cta ghost" href="${REPO}${BLOG}/${p.file}">View Markdown on GitHub</a></p>
</article>`;
    files.set(p.url, wrapBlog({ url: p.url, title: p.title, summary: p.summary, content }));
  }

  const indexContent = `<h1>Technical Blog &amp; Field Notes</h1>
<p class="lede">Deep-dive architectural notes, operational patterns, and field engineering write-ups for running Liquidware Stratusphere UX, ProfileUnity, FlexApp, and CommandCTRL across Azure Virtual Desktop, Windows 365, Citrix, Omnissa Horizon, RDS, and physical Windows endpoints.</p>
<div class="post-list">
${posts.map((p) => `<article class="post-card">
<div class="post-meta"><span>${esc(p.date)}</span><span class="badge b-verified">${esc(p.status)}</span></div>
<h2><a href="${p.url}">${esc(p.title)}</a></h2>
<p>${esc(p.summary)}</p>
<div class="chips">${p.tags.map((t) => `<span class="chip">${esc(t)}</span>`).join('')}</div>
</article>`).join('\n')}
</div>`;
  files.set('index.html', wrapBlog({
    url: 'index.html',
    title: 'Technical Blog & Field Notes',
    summary: 'Deep-dive architectural notes and field engineering write-ups for Liquidware Stratusphere UX, ProfileUnity, FlexApp, and CommandCTRL.',
    content: indexContent,
  }));

  return files;
}

const { files: docFiles, bySrc } = buildDocs();
const blogFiles = buildBlog(bySrc);
const llmsTxt = readFileSync(join(root, 'llms.txt'), 'utf8').replace(/\r\n/g, '\n');

const check = process.argv.includes('--check');
const stale = [];

function syncDir(outDir, fileMap) {
  const onDisk = existsSync(join(root, outDir)) ? walk(outDir).map((p) => p.slice(outDir.length + 1)) : [];
  for (const [rel, text] of fileMap) {
    const p = join(root, outDir, rel);
    if (!existsSync(p) || readFileSync(p, 'utf8').replace(/\r\n/g, '\n') !== text) stale.push(`${outDir}/${rel}`);
  }
  for (const rel of onDisk) if (!fileMap.has(rel)) stale.push(`${outDir}/${rel}`);
  if (!check) {
    rmSync(join(root, outDir), { recursive: true, force: true });
    for (const [rel, text] of fileMap) {
      mkdirSync(dirname(join(root, outDir, rel)), { recursive: true });
      writeFileSync(join(root, outDir, rel), text);
    }
  }
}

syncDir(OUT_DOCS, docFiles);
syncDir(OUT_BLOG, blogFiles);

const siteLlms = join(root, 'site/llms.txt');
if (!existsSync(siteLlms) || readFileSync(siteLlms, 'utf8').replace(/\r\n/g, '\n') !== llmsTxt) {
  stale.push('site/llms.txt');
  if (!check) writeFileSync(siteLlms, llmsTxt);
}

if (check) {
  if (stale.length) {
    console.error(`generated site files are out of date (${stale.join(', ')}); run node scripts/site/build-site.mjs`);
    process.exit(1);
  }
  console.log('generated site files (site/docs/, site/blog/, site/llms.txt) are up to date');
} else {
  console.log(`wrote ${docFiles.size} docs files, ${blogFiles.size} blog files, and site/llms.txt`);
}
