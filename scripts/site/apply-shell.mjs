// Writes the shared app shell (scripts/site/shell.mjs) into the hand-written pages of site/ between their
// markers: <!-- shell:head --> in <head>, <!-- shell:top --> after <body class="shell">, and
// <!-- shell:foot --> before </body>. Generated pages in site/docs/ and site/blog/ get the same shell
// from build-site.mjs.
// Personal project, not for production, as is; not affiliated with the author's employer, Liquidware or Microsoft.
//
//   node scripts/site/apply-shell.mjs           # rewrite the shell in every hand-written page
//   node scripts/site/apply-shell.mjs --check   # fail if a page's shell is out of date (CI)
import { readFileSync, writeFileSync, readdirSync, statSync, realpathSync } from 'node:fs';
import { join, relative } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { shellHead, shellTop, shellFoot } from './shell.mjs';

const root = fileURLToPath(new URL('../../', import.meta.url));
const SITE = join(root, 'site');
const FOOT = '<p>Published from <a href="https://github.com/nickprignano/liquidware-ninja">nickprignano/liquidware-ninja</a>. Something wrong? Open an issue or a pull request in the repository it came from.</p>';

const walk = (d) => readdirSync(d).flatMap((f) => (statSync(join(d, f)).isDirectory() ? walk(join(d, f)) : [join(d, f)]));
const handWritten = () => walk(SITE).filter((f) => {
  const rel = relative(SITE, f).replace(/\\/g, '/');
  return f.endsWith('.html') && !rel.startsWith('docs/') && !rel.startsWith('blog/');
});

export function applyShell(html, current) {
  const up = '../'.repeat(current.split('/').length - 1);
  const put = (text, name, body) => {
    const re = new RegExp(`<!-- shell:${name} -->[\\s\\S]*?<!-- /shell:${name} -->`);
    if (!re.test(text)) throw new Error(`${current}: no <!-- shell:${name} --> markers`);
    return text.replace(re, () => `<!-- shell:${name} -->\n${body}\n<!-- /shell:${name} -->`);
  };
  return put(put(put(html, 'head', shellHead(up)), 'top', shellTop(up, current)), 'foot', shellFoot(FOOT));
}

if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) {
  const check = process.argv.includes('--check');
  const stale = [];
  for (const f of handWritten()) {
    const current = relative(SITE, f).replace(/\\/g, '/');
    const before = readFileSync(f, 'utf8').replace(/\r\n/g, '\n');
    const after = applyShell(before, current);
    if (after !== before) {
      stale.push(current);
      if (!check) writeFileSync(f, after);
    }
  }
  if (check && stale.length) {
    console.error(`the shell is out of date in ${stale.join(', ')}; run node scripts/site/apply-shell.mjs`);
    process.exit(1);
  }
  console.log(check ? 'the shell is up to date' : `rewrote the shell in ${stale.length} of ${handWritten().length} pages under ${relative(root, SITE)}/`);
}
