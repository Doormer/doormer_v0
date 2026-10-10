# Public Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a distinctive, crawlable public Doormer website that sells the learning-first quest experience while preserving every existing Flutter application route.

**Architecture:** The public root and three policy pages are semantic static HTML in `web/`. A small synchronous route classifier decides whether `web/index.html` shows marketing content or boots Flutter; Nginx serves concrete files/directories before its SPA fallback. A dependency-free Node contract test verifies routing, content, links, accessibility hooks and built-output copying.

**Tech Stack:** HTML5, CSS, small dependency-free browser JavaScript, SVG, Node's built-in test runner, Flutter Web 3.27.1, Nginx

## Global Constraints

- The public root must be readable without Flutter and without nonessential JavaScript.
- Existing `/auth`, `/saved`, `/questions/...`, `/collection` and `/profile` Flutter routes must keep their current behavior.
- Use only current product capabilities; do not invent ratings, usage counts, testimonials, accuracy rates, solve times or school partnerships.
- The primary CTA copy is `Solve your first question` and its destination is `/auth/signup`.
- The primary headline is `Don't just get the answer. Unlock it.`
- Reuse Fredoka, Space Grotesk and the existing quest palette: night `#08060F`, ink `#150F2E`, violet `#6C4DFF`, pink `#FFABF3`, mint `#00E5A0`, amber `#FFD84D`, cream `#FFF4FF`.
- The root page must not load the Flutter bundle.
- Application paths must hide the marketing document before first paint and load `flutter_bootstrap.js`.
- Supporting public paths are `/about/`, `/privacy/` and `/terms/`.
- Do not publish a contact address, canonical URL, ad unit, rating or social-proof claim that is not known to be real.
- The page must remain useful without ads; do not place ads on the public marketing surface.
- Work from the approved design in `docs/superpowers/specs/2026-10-10-landing-page-design.md`.

## File map

| File | Responsibility |
|---|---|
| `web/marketing/route-mode.js` | Pure, synchronous pathname classification exposed as `DoormerRouting` |
| `web/index.html` | Root marketing document and conditional Flutter bootstrap host |
| `web/marketing/styles.css` | Shared landing, policy-page, responsive, focus and reduced-motion styles |
| `web/marketing/mark.svg` | Original Doormer quest-door brand mark |
| `web/about/index.html` | Public mission and product-principles page |
| `web/privacy/index.html` | Accurate service and advertising privacy disclosure |
| `web/terms/index.html` | Acceptable-use and generated-answer terms |
| `web/manifest.json` | Accurate Doormer PWA identity and quest theme colors |
| `web/robots.txt` | Allow normal crawling without inventing a sitemap URL |
| `nginx.conf` | Prefer concrete files and directory indexes before Flutter fallback |
| `tool/marketing_site_test.mjs` | Dependency-free source and built-output contract tests |
| `README.md` | Explain public routes and the focused marketing-site verification command |

---

### Task 1: Separate Public and Flutter Routes

**Files:**
- Create: `web/marketing/route-mode.js`
- Create: `tool/marketing_site_test.mjs`
- Modify: `web/index.html`
- Modify: `nginx.conf`

**Interfaces:**
- Consumes: browser `location.pathname`; Nginx request URI
- Produces: `globalThis.DoormerRouting.isMarketingPath(pathname): boolean`
- Produces: `globalThis.DoormerRouting.shouldBootFlutter(pathname): boolean`
- Produces: an HTML class of `marketing-route` or `app-route` before first paint

- [ ] **Step 1: Write the failing route contract**

Create `tool/marketing_site_test.mjs` with Node built-ins only:

```js
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const siteRoot = process.env.MARKETING_ROOT
  ? resolve(projectRoot, process.env.MARKETING_ROOT)
  : resolve(projectRoot, 'web');

function read(relativePath) {
  return readFileSync(resolve(siteRoot, relativePath), 'utf8');
}

function loadRouting() {
  const context = {};
  vm.runInNewContext(read('marketing/route-mode.js'), context);
  return context.DoormerRouting;
}

test('only public documents stay in marketing mode', () => {
  const routing = loadRouting();

  for (const path of ['/', '/about', '/about/', '/privacy/', '/terms/']) {
    assert.equal(routing.isMarketingPath(path), true, path);
    assert.equal(routing.shouldBootFlutter(path), false, path);
  }

  for (const path of [
    '/auth',
    '/auth/login',
    '/auth/signup',
    '/saved',
    '/questions/photo',
    '/questions/abc/solution',
    '/collection',
    '/profile',
    '/not-a-real-route',
  ]) {
    assert.equal(routing.isMarketingPath(path), false, path);
    assert.equal(routing.shouldBootFlutter(path), true, path);
  }
});

test('the root document classifies before loading Flutter', () => {
  const html = read('index.html');
  const classifier = html.indexOf('marketing/route-mode.js');
  const routeClass = html.indexOf('shouldBootFlutter');
  const bootstrap = html.indexOf('flutter_bootstrap.js');

  assert.ok(classifier > -1, 'route classifier script is present');
  assert.ok(routeClass > classifier, 'route class is set after classifier');
  assert.ok(bootstrap > routeClass, 'Flutter is considered after route mode');
  assert.doesNotMatch(
    html,
    /<script[^>]+src=["']flutter_bootstrap\.js["'][^>]*>/,
    'Flutter must not be loaded unconditionally',
  );
});

test('nginx serves public directories before the Flutter fallback', () => {
  const nginx = readFileSync(resolve(projectRoot, 'nginx.conf'), 'utf8');
  assert.match(nginx, /try_files\s+\$uri\s+\$uri\/\s+\/index\.html;/);
});
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
node --test tool/marketing_site_test.mjs
```

Expected: FAIL because `web/marketing/route-mode.js` does not exist.

- [ ] **Step 3: Implement the pure pathname classifier**

Create `web/marketing/route-mode.js`:

```js
(function defineDoormerRouting(global) {
  'use strict';

  const publicPaths = new Set([
    '/',
    '/about',
    '/about/',
    '/privacy',
    '/privacy/',
    '/terms',
    '/terms/',
  ]);

  function normalisePath(pathname) {
    if (typeof pathname !== 'string' || pathname.length === 0) return '/';
    return pathname.startsWith('/') ? pathname : `/${pathname}`;
  }

  function isMarketingPath(pathname) {
    return publicPaths.has(normalisePath(pathname));
  }

  global.DoormerRouting = Object.freeze({
    isMarketingPath,
    shouldBootFlutter(pathname) {
      return !isMarketingPath(pathname);
    },
  });
})(typeof window === 'undefined' ? globalThis : window);
```

- [ ] **Step 4: Make `index.html` select a mode synchronously**

In `web/index.html`, keep the Flutter `<base>` placeholder and viewport tags.
Load the classifier in the head without `async`, then set the route class and
conditionally append Flutter's bootstrap script:

```html
<script src="/marketing/route-mode.js"></script>
<script>
  (function selectRouteMode() {
    var bootsFlutter =
        window.DoormerRouting.shouldBootFlutter(window.location.pathname);
    document.documentElement.classList.add(
      bootsFlutter ? 'app-route' : 'marketing-route'
    );
    if (!bootsFlutter) return;

    var bootstrap = document.createElement('script');
    bootstrap.src = '/flutter_bootstrap.js';
    bootstrap.async = true;
    document.head.appendChild(bootstrap);

    window.addEventListener('flutter-first-frame', function removeLoading() {
      var loading = document.getElementById('app-loading');
      if (loading) loading.remove();
    }, { once: true });
  })();
</script>
```

Add two top-level body containers:

```html
<body>
  <div id="app-loading" role="status">
    <p>Opening Doormer…</p>
    <noscript>
      Doormer needs JavaScript to open the app.
      <a href="/">Return to the public site</a>.
    </noscript>
  </div>
  <div id="marketing-site">
    <main><h1>Don't just get the answer. Unlock it.</h1></main>
  </div>
</body>
```

Add a small critical style in the head so the wrong surface never flashes:

```html
<style>
  .app-route #marketing-site,
  .marketing-route #app-loading { display: none !important; }
</style>
```

- [ ] **Step 5: Make Nginx prefer directories**

Change the existing fallback in `nginx.conf`:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Do not add route-specific rewrites. Concrete public documents must win; every
other route falls back to `index.html`, which boots Flutter.

- [ ] **Step 6: Run the focused test**

Run:

```bash
node --test tool/marketing_site_test.mjs
```

Expected: 3 tests PASS.

- [ ] **Step 7: Commit the route boundary**

```bash
git add web/marketing/route-mode.js web/index.html nginx.conf tool/marketing_site_test.mjs
git commit -m "feat(marketing): separate public and app routes" \
  -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Build the Quest Landing Page

**Files:**
- Create: `web/marketing/styles.css`
- Create: `web/marketing/mark.svg`
- Create: `web/robots.txt`
- Modify: `web/index.html`
- Modify: `web/manifest.json`
- Modify: `tool/marketing_site_test.mjs`

**Interfaces:**
- Consumes: `DoormerRouting` from Task 1
- Produces: section anchors `how-it-works`, `why-doormer`, `subjects`, `faq`
- Produces: normal `/auth/signup` and `/auth/login` links for Flutter handoff
- Produces: reusable site classes consumed by the policy pages in Task 3

- [ ] **Step 1: Add failing landing-page contract tests**

Append:

```js
function assertContainsAll(actual, expectedValues, label) {
  for (const expected of expectedValues) {
    assert.match(actual, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), `${label}: ${expected}`);
  }
}

test('the landing page contains the approved story and conversion path', () => {
  const html = read('index.html');

  assertContainsAll(html, [
    '<header',
    '<nav',
    '<main',
    '<footer',
    '<h1>Don&#39;t just get the answer. <em>Unlock it.</em></h1>',
    'id="how-it-works"',
    'id="why-doormer"',
    'id="subjects"',
    'id="faq"',
    'Most tools rush to the answer.',
    'It reads the question, not the scribbles',
    'From question to collection',
    'Responsible learning',
    'Solve your first question',
    'href="/auth/signup"',
    'href="/auth/login"',
  ], 'landing page');

  assert.doesNotMatch(html, /\b(?:10M|million users|guaranteed|100% accurate)\b/i);
});

test('the landing page exposes accessibility and resilience hooks', () => {
  const html = read('index.html');
  const css = read('marketing/styles.css');

  assert.match(html, /href="#main-content"/);
  assert.match(html, /<figure[\s>]/);
  assert.match(html, /<figcaption[\s>]/);
  assert.match(html, /<details[\s>]/);
  assert.match(html, /<summary[\s>]/);
  assert.match(css, /:focus-visible/);
  assert.match(css, /@media\s*\(prefers-reduced-motion:\s*reduce\)/);
  assert.match(css, /@media\s*\(max-width:/);
});

test('the manifest and crawler identity describe Doormer', () => {
  const manifest = JSON.parse(read('manifest.json'));
  assert.equal(manifest.name, 'Doormer — Guided homework help');
  assert.equal(manifest.short_name, 'Doormer');
  assert.equal(manifest.theme_color, '#150F2E');
  assert.notEqual(manifest.description, 'A new Flutter project.');
  assert.match(read('robots.txt'), /User-agent: \*\s+Allow: \//);
});
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run:

```bash
node --test tool/marketing_site_test.mjs
```

Expected: route tests PASS; new landing, styles and manifest tests FAIL.

- [ ] **Step 3: Replace the temporary marketing shell with semantic page structure**

In `web/index.html`:

1. Set title to `Doormer — Understand the path, not just the answer`.
2. Set meta description to `Turn a photo of a school question into a guided quest with a clear plan, explained steps, helpful visuals and an answer you unlock.`
3. Add Open Graph title, description and `website` type. Do not add a false
   canonical URL or absolute image URL.
4. Link `/marketing/styles.css`, the local manifest, icon and theme color.
5. Keep Task 1's route classifier and conditional Flutter bootstrap unchanged.
6. Add a skip link to `#main-content`.
7. Build these exact sections in order:

```html
<div id="marketing-site">
  <a class="skip-link" href="#main-content">Skip to content</a>
  <header class="site-header">
    <!-- mark + Doormer, four anchor links, Log in, primary CTA -->
  </header>
  <main id="main-content">
    <section class="hero" aria-labelledby="hero-title">…</section>
    <section class="contrast" aria-labelledby="contrast-title">…</section>
    <section id="how-it-works" aria-labelledby="how-title">…</section>
    <section id="why-doormer" aria-labelledby="why-title">…</section>
    <section class="journey" aria-labelledby="journey-title">…</section>
    <section id="subjects" aria-labelledby="subjects-title">…</section>
    <section class="responsible" aria-labelledby="responsible-title">…</section>
    <section id="faq" aria-labelledby="faq-title">…</section>
    <section class="final-cta" aria-labelledby="final-title">…</section>
  </main>
  <footer class="site-footer">…</footer>
</div>
```

Use the approved body copy from these design sections, without paraphrasing it
into broader claims:

- `Positioning`
- `Category contrast`
- `How it works`
- `Why Doormer`
- `Product journey`
- `Subjects`
- `Responsible learning`
- `FAQ`
- `Final CTA`

The hero product scene must be semantic HTML with this order:

```html
<figure class="quest-preview">
  <div class="question-card">YOUR QUESTION</div>
  <ol class="quest-trail">
    <li class="trail-stop trail-stop--done">THE PLAN</li>
    <li class="trail-stop trail-stop--done">STEP 1 · Find what is given</li>
    <li class="trail-stop trail-stop--current">STEP 2 · Apply the rule</li>
    <li class="trail-stop trail-stop--ready">ANSWER READY</li>
  </ol>
  <div class="reward-flight" aria-hidden="true">+ quarks</div>
  <figcaption>A preview of the Doormer learning journey</figcaption>
</figure>
```

Render the contrast as paired rows, not a semantic data table that becomes
unreadable on small screens. Label both columns explicitly:
`Typical answer-first experience` and `Doormer`.

Use native `<details>/<summary>` for every FAQ item and a native `<details>`
menu for small screens. No menu JavaScript is needed.

- [ ] **Step 4: Create the original brand mark**

Create `web/marketing/mark.svg` as a simple 48×48 SVG:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" role="img" aria-labelledby="title">
  <title id="title">Doormer</title>
  <path fill="#6C4DFF" d="M9 5h25a5 5 0 0 1 5 5v33H9V5Z"/>
  <path fill="#150F2E" d="M16 12h15v31H16V12Z"/>
  <circle cx="27" cy="28" r="2" fill="#FFD84D"/>
  <path d="M5 43h38" stroke="#00E5A0" stroke-width="3" stroke-linecap="round"/>
</svg>
```

Use the file as a normal image with `width`, `height` and alt text `Doormer`
in the header. The footer mark is decorative and uses empty alt text.

- [ ] **Step 5: Implement the visual system in one focused stylesheet**

Create `web/marketing/styles.css` with:

- local `@font-face` declarations pointing to the built Flutter assets:
  `/assets/assets/fonts/Fredoka-600.ttf`,
  `/assets/assets/fonts/Fredoka-700.ttf`,
  `/assets/assets/fonts/SpaceGrotesk-400.ttf`,
  `/assets/assets/fonts/SpaceGrotesk-500.ttf`,
  `/assets/assets/fonts/SpaceGrotesk-600.ttf`;
- CSS custom properties for every approved color;
- a `1180px` content maximum and `68ch` reading maximum;
- a 55/45 desktop hero, stacked below `900px`;
- an asymmetrical radial spotlight plus a fine CSS-only constellation texture;
- a visible connected trail, step states and answer-vault treatment;
- paired comparison rows that become single-column cards below `700px`;
- a horizontal journey that becomes a vertical trail below `760px`;
- restrained button radii and at least `44px` tap targets;
- a skip link that becomes visible on focus;
- `:focus-visible` outlines using amber against dark surfaces;
- `scroll-margin-top` on anchored sections;
- no horizontal overflow at `320px`;
- transform/opacity-only ambient motion; and
- a reduced-motion block:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Do not turn every text block into a rounded card. Reserve surfaces for product
objects, comparison rows, the responsible-learning callout and FAQ.

- [ ] **Step 6: Correct the PWA and crawler identity**

Update `web/manifest.json`:

```json
{
  "name": "Doormer — Guided homework help",
  "short_name": "Doormer",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#08060F",
  "theme_color": "#150F2E",
  "description": "Guided homework help that turns a photo into a plan, explained steps and an answer you unlock.",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

Create `web/robots.txt`:

```text
User-agent: *
Allow: /
```

Do not add a sitemap line until the production origin is known.

- [ ] **Step 7: Run focused tests and format checks**

Run:

```bash
node --test tool/marketing_site_test.mjs
git diff --check -- web/index.html web/marketing web/manifest.json web/robots.txt tool/marketing_site_test.mjs
```

Expected: all marketing tests PASS; diff check produces no output.

- [ ] **Step 8: Commit the public landing page**

```bash
git add web/index.html web/marketing/styles.css web/marketing/mark.svg web/manifest.json web/robots.txt tool/marketing_site_test.mjs
git commit -m "feat(marketing): add Doormer quest landing page" \
  -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Add About, Privacy and Terms

**Files:**
- Create: `web/about/index.html`
- Create: `web/privacy/index.html`
- Create: `web/terms/index.html`
- Modify: `web/marketing/styles.css`
- Modify: `tool/marketing_site_test.mjs`

**Interfaces:**
- Consumes: shared header, footer, typography, button and legal-page classes
- Produces: concrete directory pages Nginx serves before the Flutter fallback
- Produces: accurate policy links from every public page

- [ ] **Step 1: Add failing public-page and link tests**

Append:

```js
const publicDocuments = [
  'index.html',
  'about/index.html',
  'privacy/index.html',
  'terms/index.html',
];

test('every public document has shared navigation and identity', () => {
  for (const document of publicDocuments) {
    const html = read(document);
    assert.match(html, /<html[^>]+lang="en"/, document);
    assert.match(html, /<meta[^>]+name="viewport"/, document);
    assert.match(html, /href="\/marketing\/styles\.css"/, document);
    assert.match(html, /href="\/about\/"/, document);
    assert.match(html, /href="\/privacy\/"/, document);
    assert.match(html, /href="\/terms\/"/, document);
    assert.match(html, /href="\/auth\/signup"/, document);
    assert.match(html, /<main[\s>]/, document);
    assert.match(html, /<footer[\s>]/, document);
  }
});

test('policy pages contain the approved substantive disclosures', () => {
  assertContainsAll(read('about/index.html'), [
    'Understand the path from question to answer',
    'A study aid, not an academic authority',
    'Why the answer waits',
  ], 'about page');

  assertContainsAll(read('privacy/index.html'), [
    'Account information',
    'Question photos and solutions',
    'Google sign-in',
    'Advertising and cookies',
    'Children and younger users',
    'Your choices',
    'Google Ads Settings',
  ], 'privacy page');

  assertContainsAll(read('terms/index.html'), [
    'Academic integrity',
    'Your question photos',
    'Generated answers',
    'Advertising',
    'Acceptable use',
    'Service availability',
  ], 'terms page');
});

test('public documents contain no unfinished copy or fake contact channel', () => {
  for (const document of publicDocuments) {
    const html = read(document);
    assert.doesNotMatch(html, /\b(?:TBD|TODO|lorem ipsum|example\.com)\b/i, document);
    assert.doesNotMatch(html, /mailto:/i, `${document}: no unverified mailbox`);
  }
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
node --test tool/marketing_site_test.mjs
```

Expected: existing tests PASS; public-document tests FAIL because the
directories do not exist.

- [ ] **Step 3: Build the About page**

Create `web/about/index.html` with:

- a unique title and description;
- the shared compact header and footer;
- one `h1`: `Understand the path from question to answer`;
- sections titled `Why Doormer exists`, `Why the answer waits`,
  `A study aid, not an academic authority`, and `What Doormer is built for`;
- the product truth from the approved design; and
- a CTA to `/auth/signup`.

Use this core mission copy:

> Doormer helps students move from a photographed school question to a method
> they can follow. It begins with the original printed question, lays out a
> plan, explains one step at a time, and keeps the final answer at the end of
> the trail.

State plainly that generated explanations can be wrong and should be checked
for important work.

- [ ] **Step 4: Build the Privacy page**

Create `web/privacy/index.html` with effective date `10 October 2026` and these
sections:

1. `Information Doormer handles`
   - account email and authentication identifiers;
   - question photos and generated solutions;
   - saved-question and reward activity;
   - device, request and diagnostic information.
2. `How the information is used`
   - provide and secure the service, solve questions, save progress, diagnose
     failures, prevent abuse and meet legal obligations.
3. `Google sign-in`
   - explain that Google may provide sign-in identifiers under Google's own
     privacy policy.
4. `Advertising and cookies`
   - disclose that Google and its partners may use cookies or device
     information to serve and measure ads;
   - link `https://policies.google.com/technologies/ads`;
   - link `https://adssettings.google.com/` with visible text
     `Google Ads Settings`;
   - say consent controls are shown where required;
   - do not promise personalised ads or a specific cookie set.
5. `Children and younger users`
   - state that ad requests are configured for age-appropriate treatment;
   - do not claim COPPA certification or set a legal minimum age not present in
     current registration logic.
6. `Sharing and service providers`
   - authentication, cloud hosting, AI processing, storage, diagnostics and
     advertising providers only as needed to operate the service.
7. `Retention and security`
   - say information is retained only as needed for service, safety and legal
     obligations; avoid an invented duration.
8. `Your choices`
   - account, browser cookie, Google ad and school-policy choices;
   - do not promise an unimplemented one-click deletion flow.
9. `Changes to this notice`
   - update the effective date when material changes are published.

Do not add a contact section until the product owner supplies a monitored
channel.

- [ ] **Step 5: Build the Terms page**

Create `web/terms/index.html` with effective date `10 October 2026` and:

- `Using Doormer`
- `Academic integrity`
- `Your account`
- `Your question photos`
- `Generated answers`
- `Quarks and collectible cards`
- `Advertising`
- `Acceptable use`
- `Service availability`
- `Intellectual property`
- `Changes to these terms`

Required limitations:

> Doormer is a study aid. It does not guarantee that a generated explanation,
> diagram or answer is complete or correct.

> Follow the rules set by your school, institution, teacher and assessment.
> Do not use Doormer where outside assistance is prohibited.

State that quarks and cards are in-product items, have no cash value, and may
change with the service. Do not add jurisdiction, arbitration, age,
subscription or refund terms that the current product does not establish.

- [ ] **Step 6: Add focused policy-page styles**

Extend `web/marketing/styles.css` with:

- `.legal-shell`, `.legal-hero`, `.legal-content`, `.legal-nav`;
- a `68ch` reading column;
- strong heading spacing;
- accessible external-link treatment;
- lists with visible markers;
- the same responsive header and footer behavior; and
- print rules that remove navigation and keep text black on white.

- [ ] **Step 7: Run focused tests**

Run:

```bash
node --test tool/marketing_site_test.mjs
git diff --check -- web/about web/privacy web/terms web/marketing/styles.css tool/marketing_site_test.mjs
```

Expected: all marketing tests PASS; diff check produces no output.

- [ ] **Step 8: Commit the supporting pages**

```bash
git add web/about web/privacy web/terms web/marketing/styles.css tool/marketing_site_test.mjs
git commit -m "feat(marketing): add public trust pages" \
  -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Verify Source, Build Output and Browser Behavior

**Files:**
- Modify: `tool/marketing_site_test.mjs`
- Modify: `README.md`
- Modify only if a check reveals a directly related defect: files from Tasks 1–3

**Interfaces:**
- Consumes: source `web/` tree and built `build/web/` tree
- Produces: one repeatable source/build contract command documented for future work

- [ ] **Step 1: Add a failing local-link test**

Append:

```js
function localHrefTargets(html) {
  return [...html.matchAll(/href="([^"]+)"/g)]
    .map((match) => match[1])
    .filter((href) => href.startsWith('/') && !href.startsWith('//'))
    .map((href) => href.split(/[?#]/, 1)[0]);
}

test('all public static links resolve or hand off to a known app route', () => {
  const appPrefixes = ['/auth', '/saved', '/questions', '/collection', '/profile'];

  for (const document of publicDocuments) {
    for (const href of localHrefTargets(read(document))) {
      if (href === '/' || appPrefixes.some((prefix) => href.startsWith(prefix))) {
        continue;
      }

      const relative = href.replace(/^\//, '');
      const candidates = [
        resolve(siteRoot, relative),
        resolve(siteRoot, relative, 'index.html'),
      ];
      assert.ok(
        candidates.some((candidate) => {
          try {
            readFileSync(candidate);
            return true;
          } catch {
            return false;
          }
        }),
        `${document}: unresolved local link ${href}`,
      );
    }
  }
});
```

- [ ] **Step 2: Run the source contract**

Run:

```bash
node --test tool/marketing_site_test.mjs
```

Expected: FAIL for any unresolved asset or page link. Fix only the reported
links, then rerun until PASS.

- [ ] **Step 3: Run Flutter validation**

Run:

```bash
flutter analyze
flutter test
flutter build web
```

Expected: all commands exit 0. The build must copy `marketing/`, `about/`,
`privacy/`, `terms/` and `robots.txt` into `build/web/`.

- [ ] **Step 4: Run the same contract against the built site**

Run:

```bash
MARKETING_ROOT=build/web node --test tool/marketing_site_test.mjs
```

Expected: all tests PASS against deployable output.

- [ ] **Step 5: Document the public-site contract**

Update `README.md` with:

```markdown
## Public website

`/` is a crawlable HTML landing page. `/about/`, `/privacy/` and `/terms/`
are static public pages. All other paths fall through to the Flutter web app;
its existing auth and question routes are unchanged.

Verify the marketing source and production-shaped output with:

```bash
node --test tool/marketing_site_test.mjs
flutter build web
MARKETING_ROOT=build/web node --test tool/marketing_site_test.mjs
```
```

Also retain the existing Flutter setup instructions.

- [ ] **Step 6: Start a production-shaped local server**

Run:

```bash
python3 -m http.server 62299 --directory build/web
```

This server is sufficient for static public-page inspection. It does not
implement Nginx's SPA fallback, so test direct Flutter routes with
`flutter run` or the final container.

- [ ] **Step 7: Inspect responsive and accessible behavior in a browser**

Using browser tools, inspect:

- `/` at 320×568, 390×844, 768×1024 and 1440×900;
- `/about/`, `/privacy/` and `/terms/`;
- keyboard focus order, skip link, mobile `<details>` menu and every FAQ;
- reduced-motion emulation;
- every CTA and footer link;
- console errors and failed requests; and
- the Network panel to confirm `/` does not request `flutter_bootstrap.js`,
  `main.dart.js` or CanvasKit.

Take screenshots of the 390×844 and 1440×900 landing page for comparison. Keep
screenshots in `.playwright-mcp/`, which is not committed.

- [ ] **Step 8: Verify app-route bootstrapping**

Start Flutter with the repository's browser-testing command:

```bash
flutter run -d web-server --web-hostname localhost --web-port 62300 \
  --dart-define=API_BASE_URL=http://localhost:8888 \
  --dart-define=ENABLE_SEMANTICS=true
```

Open `/auth/login`, `/questions/photo` and an unknown path. Verify:

- no marketing-page flash;
- the login route renders;
- a signed-out protected route redirects to `/auth/login`;
- an unknown route shows the existing not-found screen; and
- no new console errors.

Stop both local servers by their specific process IDs.

- [ ] **Step 9: Run the final focused checks**

Run:

```bash
node --test tool/marketing_site_test.mjs
MARKETING_ROOT=build/web node --test tool/marketing_site_test.mjs
flutter analyze
flutter test
git diff --check
```

Expected: all commands exit 0 and `git diff --check` produces no output.

- [ ] **Step 10: Commit verification documentation and any direct fixes**

```bash
git add README.md tool/marketing_site_test.mjs web nginx.conf
git commit -m "test(marketing): verify public site delivery" \
  -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

If the browser and build checks required no file changes beyond README and the
test, commit only those files. Do not create an empty commit.
