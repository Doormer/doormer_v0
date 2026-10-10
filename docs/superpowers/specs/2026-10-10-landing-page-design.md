# Doormer public landing page

Date: 2026-10-10
Status: approved by pragmatic default while the product owner was unavailable
Audience: students aged 13–18, with parents and educators as secondary readers
Primary conversion: start a first question in the browser

## Goal

Create a public, crawlable website that:

1. explains why Doormer is a better learning experience than an answer-first
   homework tool;
2. gives a student enough confidence and curiosity to start a question;
3. represents the product honestly, using capabilities that already exist;
4. gives Google AdSense a useful, navigable site to review rather than an auth
   screen or a JavaScript canvas with little indexable content; and
5. preserves the existing Flutter application and its signed-in routes.

AdSense approval remains Google's decision. This design makes the site ready
for review but does not promise approval.

## Product truth

The marketing page may claim only behavior visible in the current product:

- A student can upload or photograph one academic question.
- The solver distinguishes the printed question from handwriting and added
  working before solving it.
- The solution opens with a plan, then moves through one explained step at a
  time.
- A student can open a "Why this works" rationale.
- A solution can include a purpose-made visual when a picture makes the idea
  clearer.
- The answer stays in a locked vault until the student reaches the end of the
  working.
- Revealing an eligible answer earns quarks.
- Quarks support a collectible-card loop.
- Solved questions can be revisited from Saved.
- The solver covers academic questions across subjects. Maths and science lead
  the landing-page examples because they show the visual and step-by-step
  experience most clearly.

The page must not invent ratings, usage counts, testimonials, accuracy rates,
solve times, tutor credentials, school partnerships, or privacy guarantees.

## Competitor review

The design reviewed the current public positioning of:

- [Photomath](https://photomath.com/): calm reassurance, app screenshots,
  step-by-step learning, subject coverage, app-store proof and a download CTA.
- [Gauth](https://www.gauthmath.com/): an upload-first hero, broad subject
  coverage, speed, tutors, large user-count claims and repeated trial CTAs.
- [Brainly](https://brainly.com/): fast AI plus human/expert trust, a broad
  subject taxonomy and community proof.
- [Question.AI](https://www.questionai.com/): snap-and-solve immediacy,
  multi-platform installation and a familiar blue/green AI-tool visual system.

The category repeats the same promise: upload a question and receive a quick
step-by-step answer. It also repeats the same visual language: white pages,
blue or green gradients, rounded feature cards and a large upload box.

Doormer should not compete on unsupported scale or speed. Its defensible
difference is the shape of the learning journey:

- it protects the original question from handwritten working;
- it makes the method a visible path rather than a text dump;
- it keeps the final answer behind the working; and
- it turns progress into an earned, collectible outcome.

## Chosen direction: the quest journey

The public site extends the application's existing quest language instead of
borrowing the category's generic AI-tool style.

### Positioning

**Primary headline**

> Don't just get the answer. Unlock it.

**Supporting copy**

> Turn a photo of a school question into a guided quest: a clear plan,
> bite-size steps, helpful visuals, and an answer that waits until the method
> makes sense.

**Primary CTA**

> Solve your first question

This is a normal link to `/auth/signup`.

**Secondary CTA**

> See how it works

This is a same-page link to `#how-it-works`.

**Confidence line**

> No install needed. Learn in your browser.

### Brand character

Doormer is energetic, focused and slightly mysterious. It should feel like
opening a well-designed game quest, not using a casino mechanic and not
entering a children's cartoon.

The student is the active character. Doormer is a guide, not a machine that
does the work for them. Copy therefore uses verbs such as **spot**, **plan**,
**work through**, **check**, **unlock** and **collect**. It avoids **cheat**,
**ace everything**, **guaranteed**, **instant** and **perfect**.

## Information architecture

### Global header

- Doormer wordmark linked to `/`
- `How it works` linked to `#how-it-works`
- `Why Doormer` linked to `#why-doormer`
- `Subjects` linked to `#subjects`
- `FAQ` linked to `#faq`
- `Log in` linked to `/auth/login`
- compact primary CTA linked to `/auth/signup`

The header becomes solid after the first screen but does not obscure anchor
targets. On small screens, the four section links sit in an accessible menu;
Log in and the primary CTA remain direct links.

### 1. Hero

Desktop uses a 55/45 split. The left side contains the eyebrow, headline,
supporting copy, two CTAs and the confidence line. The right side shows a
semantic HTML/CSS product scene:

1. a small photo card labelled `YOUR QUESTION`;
2. a trail marker labelled `THE PLAN`;
3. two compact step cards, with the current step in pink;
4. a chained answer vault in amber; and
5. a mint `+ quarks` reward moving toward a small collection card.

This is a simplified demonstration, not a fake screenshot. A caption states
`A preview of the Doormer learning journey`.

On a phone, copy comes first and the quest scene follows. The primary CTA stays
visible without requiring horizontal scrolling or a fixed bottom overlay.

### 2. Category contrast

Heading:

> Most tools rush to the answer. Doormer builds the path.

Four short contrasts establish the product difference without naming or
misrepresenting competitors:

| Typical answer-first experience | Doormer |
|---|---|
| Reads everything in the photo as one input | Separates the printed question from handwritten working |
| Presents a long result all at once | Starts with a plan and reveals one step at a time |
| Places the final answer beside the method | Keeps the answer locked until the working is complete |
| Ends when the answer appears | Saves the solution and turns progress into quarks and cards |

The qualifier **typical** is required. The page does not claim that every
competitor behaves this way.

### 3. How it works

Three numbered stages use real product language:

1. **Snap the whole question**  
   Include the printed text and any diagram. Doormer checks what belongs to
   the question before it starts reasoning.

2. **Follow the trail**  
   See the plan, take one step at a time, and open "Why this works" when the
   rule or idea needs more explanation.

3. **Unlock and check**  
   Reach the answer vault, reveal the answer, then use the final check to make
   sure the result fits the original question.

Each stage includes a small, semantic mock panel. The sequence uses CSS rather
than a video so it remains readable, lightweight and accessible.

### 4. Why Doormer

This section provides original, useful detail rather than a grid of vague
marketing adjectives.

#### It reads the question, not the scribbles

Students often photograph worksheets that already contain calculations,
crossed-out attempts or annotations. Doormer first identifies the printed
question and its attached values. If an essential detail cannot be read
reliably, it asks for a clearer photo instead of pretending.

#### The method has a shape

A visible plan and progress trail show where the student is, what is complete
and what remains. Each screen focuses on one idea. Optional rationale explains
why the step applies.

#### Visuals appear for a reason

When a diagram, graph or transformed figure clarifies a step, Doormer can place
that visual beside the explanation. The page does not claim that every
question receives a diagram.

#### Progress becomes something to keep

Eligible answer reveals earn quarks. Quarks connect solving to collectible
cards, while Saved keeps the academic result available for review.

### 5. Product journey

A full-width `From question to collection` scene connects the learning loop:

`Photo` → `Plan` → `Steps` → `Answer vault` → `Quarks` → `Cards` → `Saved`

Every item has a one-line explanation. This section is especially important
for parents and reviewers who need to understand that the reward follows the
learning action rather than replacing it.

### 6. Subjects

Heading:

> Built for the questions that need working.

Lead examples:

- Maths: algebra, geometry, calculus and statistics
- Science: physics, chemistry and biology
- Questions with diagrams, tables, graphs or written passages

The copy says that coverage depends on whether the complete question is
readable. It does not publish an exhaustive subject guarantee.

### 7. Responsible learning

This section is short but prominent:

- Doormer is a study aid, not a substitute for a teacher or assessment rules.
- Students should follow their school or institution's academic-integrity
  policy.
- A clear photo of the complete original question produces the best result.
- Important answers should be checked against course materials or a teacher.

### 8. FAQ

The initial questions are:

1. **Does Doormer only do maths?**  
   No. It is designed for academic questions across subjects, with maths and
   science used most often in examples because their working and diagrams show
   the guided experience clearly.

2. **Will it use the working already written on my page?**  
   Doormer attempts to separate the printed question from handwritten working,
   annotations and crossed-out attempts before solving.

3. **Why is the answer locked?**  
   The answer is the destination, not the first screen. Following the method
   first makes the result easier to understand and check.

4. **What makes a good photo?**  
   Use bright light, hold the page flat, and include every line, label and
   diagram needed by the question.

5. **Can I revisit a solution?**  
   Signed-in students can return to solved questions from Saved.

6. **Is every answer guaranteed to be correct?**  
   No solver should make that promise. Doormer verifies its reasoning where
   practical, but students should check important work against their course
   materials or teacher.

### 9. Final CTA

Headline:

> Ready to work it out?

Supporting copy:

> Bring one question. Leave with the path, not just the result.

CTA:

> Solve your first question

### Footer

- one-sentence product description
- `How it works`, `Why Doormer`, `Subjects`, `FAQ`
- `Log in`, `Create account`
- `About`, `Privacy`, `Terms`
- current copyright year

A contact link must not be published until a real, monitored contact channel
is supplied. The site must not invent a mailbox to look complete. About,
Privacy and Terms are included because they can be accurate from the product
and repository evidence available now.

## Supporting pages

### About

Explains:

- Doormer's mission: help students understand the path from question to answer;
- the learning-first product choices: plan, progressive steps, rationale,
  answer vault and review;
- the difference between a study aid and an academic-authority source; and
- the subjects and image types the product is designed to handle.

It links to the product, Privacy and Terms.

### Privacy

The privacy page must match the deployed services. At minimum it covers:

- account information used for authentication;
- question photos, generated solutions and saved-question history;
- technical logs and service diagnostics;
- Google sign-in, when used;
- AdSense and third-party cookies or device identifiers;
- age-related ad treatment already configured in the app;
- purposes, retention, sharing, security limits and user choices;
- consent requirements for regions where they apply; and
- links to Google's advertising privacy controls and policy pages.

The page must not state a retention period, deletion workflow or legal basis
that the product does not actually implement. Legal review remains a launch
requirement, not a copywriting exercise.

### Terms

The terms page covers acceptable use, academic integrity, account
responsibility, user-provided photos, generated-answer limitations, service
availability, ads, intellectual property and changes to the service. It avoids
unsupported jurisdiction-specific promises.

## Technical architecture

### Crawlable marketing surface

The public page is semantic HTML and CSS in `web/`, not a Flutter route.
Google, screen readers and users without application JavaScript can read the
complete marketing content.

`web/index.html` performs two jobs:

- at `/`, it renders the public landing page and does not download the Flutter
  application bundle; and
- at application paths such as `/auth`, `/saved`, `/questions/...`,
  `/collection` and `/profile`, it hides the marketing document immediately
  and loads `flutter_bootstrap.js`.

The bootstrap decision runs in the document head to avoid flashing the
landing page before the app. It uses the pathname only; query strings and
fragments do not change whether a route is marketing or application content.

About, Privacy and Terms are standalone HTML documents in matching `web/`
directories. Nginx tries `$uri` and `$uri/` before falling back to
`/index.html`, so those static pages resolve before Flutter routing.

The existing Flutter route names and authentication behavior remain
unchanged. `redirectFor('/')` remains valid inside the application even though
the public root does not bootstrap Flutter.

### Assets

- `web/marketing/styles.css`: all public-site styling
- `web/marketing/site.js`: menu, disclosure controls and nonessential visual
  state only
- `web/marketing/mark.svg`: simple Doormer brand mark
- `web/about/index.html`
- `web/privacy/index.html`
- `web/terms/index.html`

No marketing interaction depends on JavaScript. FAQ uses native
`<details>/<summary>`. Anchor navigation and CTAs are normal links.

The quest scene uses HTML, CSS and small inline SVG marks created for Doormer.
It does not copy competitor artwork or use stock student photography.

### Metadata

The root document includes:

- a specific title and meta description;
- Open Graph and Twitter card metadata;
- theme color;
- a canonical URL only when the production domain is known;
- crawl directives;
- `SoftwareApplication` JSON-LD using claims present on the page; and
- a useful no-script experience.

The implementation must not guess the production canonical domain. Omitting a
canonical tag is safer than publishing a false one.

## Visual system

The page reuses the product's established palette and typography:

- night `#08060F`
- ink `#150F2E`
- violet `#6C4DFF` for structure and primary actions
- pink `#FFABF3` for the current step and mathematics
- mint `#00E5A0` for completed and earned states
- amber `#FFD84D` for the answer ready to unlock
- cream `#FFF4FF` for primary display text
- Fredoka for display copy
- Space Grotesk for body copy and controls

Fonts use the existing local files, avoiding a new third-party request.

The visual composition uses:

- a deep, asymmetrical spotlight behind the hero quest;
- a fine constellation/grid texture rather than a generic gradient wash;
- one strong display headline per section;
- editorial text blocks mixed with product-shaped scenes;
- varied section rhythm rather than a repeated grid of rounded cards; and
- visible trail lines that connect the page's story from question to answer.

Buttons are high-contrast and use restrained radii. Cards are reserved for
product objects, comparisons and FAQ disclosures; ordinary copy does not sit
inside decorative containers.

## Responsive behavior

- Works from 320 px through wide desktop screens.
- Main content maxes out near 1180 px; reading text stays near 68 characters.
- The hero changes from split to stacked before either column becomes cramped.
- The comparison becomes paired rows on small screens rather than a squeezed
  table.
- The journey diagram becomes a vertical trail on small screens.
- Tap targets are at least 44 by 44 logical pixels.
- No horizontal scrolling at 320 px.
- Anchor targets account for the sticky header.

## Accessibility and motion

- One `h1`; headings descend without skipped levels.
- Landmarks use `header`, `nav`, `main`, `section` and `footer`.
- Every decorative object is hidden from assistive technology.
- The quest scene has a concise text alternative and visible caption.
- Focus indicators remain visible against every background.
- Color never carries status alone; labels and icons repeat its meaning.
- Menu and FAQ controls are keyboard-operable.
- Body text and controls meet WCAG AA contrast.
- Animations use transform and opacity only.
- `prefers-reduced-motion: reduce` disables ambient movement, transitions and
  smooth scrolling without hiding content.

## AdSense-readiness constraints

The implementation follows Google's public policy guidance:

- useful original content, not a doorway page with one CTA;
- clear navigation and reachable policy pages;
- no deceptive buttons or claims;
- no copied reviews, fabricated trust proof or disguised ads;
- no ad unit above or inside the hero;
- no AdSense script on the public page until an approved account and placement
  exist; and
- a privacy disclosure that matches Google advertising use before ads are
  enabled.

The landing page's purpose is to sell and explain Doormer. It must remain
valuable if no ad ever appears on it.

References:

- [AdSense program policies](https://support.google.com/adsense/answer/48182)
- [Google Publisher Policies](https://support.google.com/adsense/answer/9335564)
- [Make your site ready for AdSense](https://support.google.com/adsense/answer/9724)

## Error handling and resilience

- If JavaScript is disabled at `/`, all marketing content, anchors, CTAs and
  legal-page links still work.
- If JavaScript is disabled on a Flutter application path, a short application
  loading panel links back to `/` and explains that the app requires
  JavaScript.
- If a local font fails, the system fallback keeps all content readable.
- Missing optional decorative assets do not collapse layout or remove text.
- A missing Flutter bundle affects app routes only; it does not blank the
  public site.

## Verification

### Automated

- `flutter analyze`
- `flutter test`
- `flutter build web`
- HTML validation for all public documents
- a link check over local links in the built output
- tests for the pathname-to-bootstrap decision
- assertions that the built output contains the landing-page headline and all
  supporting pages

### Browser

Check at least:

- 320×568
- 390×844
- 768×1024
- 1440×900

Verify:

- no overflow or clipped content;
- menu and FAQ keyboard behavior;
- visible focus states;
- reduced-motion behavior;
- all anchors and CTAs;
- direct loads of `/`, `/about/`, `/privacy/`, `/terms/`, `/auth/login`,
  `/questions/photo` and an unknown path;
- signed-in and signed-out Flutter redirects;
- no landing-page flash on application routes; and
- the landing page does not request the Flutter application bundle.

Run Lighthouse on the production-shaped build. Accessibility and SEO should
score at least 95. Performance is investigated if it is below 90; the score is
not gamed by removing necessary product content.

## Non-goals

- A blog, article CMS or invented long-form content created only to increase
  page count
- Pricing
- Testimonials or ratings
- A support form without a real monitored destination
- Landing-page ad placements
- Rebuilding authentication or signed-in product screens
- Changing the solver, quark economy or card system
- Promising AdSense approval

## Success criteria

The design succeeds when:

1. a new visitor can explain Doormer's difference after the hero and contrast
   section;
2. the first CTA reaches sign-up and the existing product still loads on every
   direct Flutter route;
3. the root page and policy pages are readable without Flutter or JavaScript;
4. every marketing claim maps to current product behavior;
5. the page is visually recognisable as the same product as the solution
   reader and card collection; and
6. the built site satisfies the responsive, accessibility, link, routing and
   Lighthouse checks above.
