// The docs graph on avd-ops.dev/docs/graph.html: reads graph.json (written by scripts/site/build-docs.mjs)
// and lays the pages out with a small force simulation in SVG. No libraries; colors come from the
// design system tokens through the classes in site.css.
(() => {
  const box = document.querySelector('.graph');
  if (!box) return;
  const svg = box.querySelector('svg');
  const NS = 'http://www.w3.org/2000/svg';
  const W = 800, H = 520;
  svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
  fetch(box.dataset.src).then((r) => r.json()).then(({ nodes, links }) => {
    const byId = new Map(nodes.map((n, i) => {
      const a = (i / nodes.length) * Math.PI * 2;
      return [n.id, Object.assign(n, { x: W / 2 + Math.cos(a) * 180, y: H / 2 + Math.sin(a) * 160, vx: 0, vy: 0, deg: 0 })];
    }));
    const edges = links.map((l) => ({ s: byId.get(l.source), t: byId.get(l.target) })).filter((e) => e.s && e.t);
    for (const e of edges) { e.s.deg++; e.t.deg++; }
    for (let step = 0; step < 400; step++) {
      const k = 1 - step / 400;
      for (const a of nodes) for (const b of nodes) {
        if (a === b) continue;
        const dx = a.x - b.x, dy = a.y - b.y, d2 = Math.max(dx * dx + dy * dy, 25);
        const f = 5200 / d2;
        a.vx += dx * f / Math.sqrt(d2); a.vy += dy * f / Math.sqrt(d2);
      }
      for (const { s, t } of edges) {
        const dx = t.x - s.x, dy = t.y - s.y, d = Math.sqrt(dx * dx + dy * dy) || 1, f = (d - 150) * 0.02;
        s.vx += dx / d * f; s.vy += dy / d * f; t.vx -= dx / d * f; t.vy -= dy / d * f;
      }
      for (const n of nodes) {
        n.vx += (W / 2 - n.x) * 0.002; n.vy += (H / 2 - n.y) * 0.003;
        n.x = Math.min(W - 40, Math.max(40, n.x + n.vx * k)); n.y = Math.min(H - 24, Math.max(24, n.y + n.vy * k));
        n.vx *= 0.6; n.vy *= 0.6;
      }
    }
    const el = (name, attrs, parent) => {
      const e = document.createElementNS(NS, name);
      for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v);
      parent.appendChild(e);
      return e;
    };
    for (const { s, t } of edges) el('line', { x1: s.x, y1: s.y, x2: t.x, y2: t.y, class: 'g-edge' }, svg);
    for (const n of nodes) {
      const a = el('a', { href: n.url, class: `g-node g-${n.topic}` }, svg);
      el('circle', { cx: n.x, cy: n.y, r: 5 + Math.min(n.deg, 10) }, a);
      el('text', { x: n.x, y: n.y - 10 - Math.min(n.deg, 10) }, a).textContent = n.title;
      el('title', {}, a).textContent = n.title;
    }
  });
})();
