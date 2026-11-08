/* avd-ops docs: one screen at a time (docs/design-system.md, "One screen at a time"). MIT.
   Personal project, not for production, as is; not affiliated with the author's employer or Microsoft.
   A docs page (scripts/site/build-docs.mjs) is an article.screens of section.screen, an "On this page" list
   and the Back and Next bar. This shows one screen, moves with Back and Next (the first and last screens go to
   the previous and next page), follows the address's #anchor and the browser's back button, and keeps the
   step list current. Without it every screen shows in order. No libraries, no requests, nothing stored. */
(function () {
  function wire() {
    var article = document.querySelector('article.screens');
    if (!article) return;
    var screens = Array.prototype.slice.call(article.querySelectorAll('section.screen'));
    var steps = article.querySelectorAll('.sc-steps a');
    var back = article.querySelector('.sc-back');
    var next = article.querySelector('.sc-next');
    var where = article.querySelector('.sc-nav .where');
    var prevPage = back && back.getAttribute('href');
    var nextPage = next && next.getAttribute('href');
    var current = -1;
    article.classList.add('paged');

    // The screen that holds the address's #anchor: the screen itself, or one with that heading inside it. No
    // anchor is the first screen; an anchor outside the screens (the shell's "Skip to content") is n -1, no change.
    function fromHash() {
      var id = decodeURIComponent(location.hash.slice(1));
      if (!id) return { n: 0, el: null };
      var el = document.getElementById(id);
      for (var i = 0; el && i < screens.length; i++) if (screens[i] === el || screens[i].contains(el)) return { n: i, el: el };
      return { n: -1, el: el };
    }

    // "Next: <page>" on a wide screen; the page's name (span.pg) hides on a phone, so the button says "Next".
    function label(a, word, page) {
      a.textContent = word;
      if (!page) return;
      var pg = document.createElement('span');
      pg.className = 'pg';
      pg.textContent = ': ' + page;
      a.appendChild(pg);
    }

    function show(n, focus, target) {
      current = n;
      for (var i = 0; i < screens.length; i++) screens[i].classList.toggle('on', i === n);
      for (var j = 0; j < steps.length; j++) {
        if (j === n) steps[j].setAttribute('aria-current', 'step'); else steps[j].removeAttribute('aria-current');
        steps[j].classList.toggle('done', j < n);
      }
      if (where && screens.length > 1) where.textContent = (n + 1) + ' of ' + screens.length;
      // Back and Next move one screen; past the first or last they open the previous or next page, and hide
      // when there is none.
      if (back) {
        back.hidden = n === 0 && !prevPage;
        if (n > 0) { back.setAttribute('href', '#' + screens[n - 1].id); label(back, 'Back', ''); }
        else if (prevPage) { back.setAttribute('href', prevPage); label(back, 'Back', back.getAttribute('data-page')); }
      }
      if (next) {
        next.hidden = n === screens.length - 1 && !nextPage;
        if (n < screens.length - 1) { next.setAttribute('href', '#' + screens[n + 1].id); label(next, 'Next', ''); }
        else if (nextPage) { next.setAttribute('href', nextPage); label(next, 'Next', next.getAttribute('data-page')); }
      }
      // An #anchor inside a screen opens the "+ more" it sits in and scrolls to it; a new screen opens at the top,
      // its title focused for screen readers.
      for (var d = target && target.parentElement; d && d !== screens[n]; d = d.parentElement) if (d.tagName === 'DETAILS') d.open = true;
      if (target && target !== screens[n]) target.scrollIntoView();
      else window.scrollTo(0, 0);
      if (focus) screens[n].querySelector('h1,h2').focus({ preventScroll: true });
    }

    // Links to a screen on this page change the screen without reloading; the browser's back button returns.
    article.addEventListener('click', function (e) {
      var a = e.target.closest && e.target.closest('a[href^="#"]');
      if (!a || e.metaKey || e.ctrlKey || e.shiftKey) return;
      var el = document.getElementById(decodeURIComponent(a.getAttribute('href').slice(1)));
      if (!el || !article.contains(el)) return;
      e.preventDefault();
      history.pushState(null, '', a.getAttribute('href'));
      var at = fromHash();
      show(at.n, true, at.el);
    });
    window.addEventListener('popstate', function () { var at = fromHash(); if (at.n >= 0) show(at.n, false, at.el); });
    window.addEventListener('hashchange', function () { var at = fromHash(); if (at.n >= 0 && at.n !== current) show(at.n, false, at.el); });
    // A printout holds every screen with its "+ more" open, and the page goes back as it was afterwards.
    var closed = [];
    window.addEventListener('beforeprint', function () {
      closed = Array.prototype.filter.call(article.querySelectorAll('details.more'), function (d) { return !d.open; });
      for (var i = 0; i < closed.length; i++) closed[i].open = true;
    });
    window.addEventListener('afterprint', function () { for (var i = 0; i < closed.length; i++) closed[i].open = false; closed = []; });
    var start = fromHash();
    if (start.n < 0) start = { n: 0, el: null };
    show(start.n, false, start.el);
    // The browser jumps to the #anchor after load; put the screen back at the top unless it named a heading.
    if (!start.el || start.el === screens[start.n]) window.addEventListener('load', function () { setTimeout(function () { window.scrollTo(0, 0); }, 0); });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', wire);
  else wire();
}());
