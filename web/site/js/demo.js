// The landing page's solution demo. Turns the stacked solution, which reads
// top to bottom without this script, into a stepper that behaves like
// Doormer's solution reader: the plan, one step at a time, then the vault.
(() => {
  const root = document.querySelector('[data-demo]');
  if (!root) return;

  const stages = ['plan', 'step-1', 'step-2', 'step-3', 'vault'];
  const vaultIndex = stages.length - 1;
  const stepCount = 3;
  const startingQuarks = 40;
  const earnedQuarks = 6;
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const byStage = (attribute) => new Map(
    [...root.querySelectorAll(`[${attribute}]`)].map((element) => [element.getAttribute(attribute), element]),
  );
  const panels = byStage('data-demo-panel');
  const nodes = byStage('data-demo-node');
  const reader = root.querySelector('.reader');
  const trail = root.querySelector('.trail');
  const controls = root.querySelector('[data-demo-controls]');
  const back = root.querySelector('[data-demo-back]');
  const next = root.querySelector('[data-demo-next]');
  const tryLink = root.querySelector('[data-demo-try]');
  const status = root.querySelector('[data-demo-status]');
  const quarks = root.querySelector('[data-demo-quarks]');
  const quarkPill = quarks.closest('.quark-pill');
  const vault = root.querySelector('[data-demo-vault]');
  const vaultStatus = root.querySelector('[data-demo-vault-status]');
  const reveal = root.querySelector('[data-demo-reveal]');
  const answer = root.querySelector('[data-demo-answer]');
  const readsToggle = root.querySelector('[data-demo-reads]');
  const paper = root.querySelector('[data-demo-paper]');

  let current = 0;
  let furthest = 0;
  let cracked = false;

  const titleOf = (stage) => panels.get(stage).querySelector('.reader__title').textContent.trim();

  function describe(stage) {
    if (stage === 'plan') return 'The plan';
    if (stage === 'vault') return 'The vault. The answer is ready to open.';
    return `Step ${stages.indexOf(stage)} of ${stepCount}: ${titleOf(stage)}`;
  }

  function render() {
    const stage = stages[current];
    const vaultReached = furthest === vaultIndex;

    panels.forEach((panel, name) => {
      panel.hidden = name !== stage;
    });

    stages.forEach((name, index) => {
      const node = nodes.get(name);
      node.disabled = index > furthest;
      node.classList.toggle('is-current', index === current);
      node.classList.toggle('is-done', index === vaultIndex ? cracked : index < furthest);
      if (index === current) {
        node.setAttribute('aria-current', 'step');
      } else {
        node.removeAttribute('aria-current');
      }
    });

    const vaultNode = nodes.get('vault');
    vaultNode.classList.toggle('is-ready', furthest >= stepCount && !cracked);
    vaultNode.setAttribute('aria-label', cracked ? 'The answer' : vaultReached ? 'The answer, ready to open' : 'The answer, locked');
    trail.style.setProperty('--trail-progress', String(furthest / vaultIndex));

    back.disabled = current === 0;
    next.hidden = stage === 'vault' && cracked;
    next.classList.toggle('is-crack', stage === 'vault');
    next.textContent = stage === 'plan' ? 'Start solving' : stage === 'vault' ? 'Crack it open' : 'Next step';
    tryLink.hidden = !cracked;

    vault.classList.toggle('is-locked', !vaultReached && !cracked);
    vault.classList.toggle('is-ready', stage === 'vault' && !cracked);
    vaultStatus.hidden = cracked;
    vaultStatus.textContent = stage === 'vault' ? 'Tap to crack it open' : `Answer unlocks after step ${stepCount}`;
  }

  function keepReaderInView() {
    const top = reader.getBoundingClientRect().top;
    if (top < 0 || top > window.innerHeight * 0.6) {
      reader.scrollIntoView({ behavior: reduceMotion ? 'auto' : 'smooth', block: 'start' });
    }
  }

  function goTo(index) {
    current = Math.max(0, Math.min(index, vaultIndex));
    furthest = Math.max(furthest, current);
    render();
    status.textContent = describe(stages[current]);
    keepReaderInView();
  }

  function countUpQuarks() {
    quarkPill.classList.remove('is-bumped');
    void quarkPill.offsetWidth;
    quarkPill.classList.add('is-bumped');
    if (reduceMotion) {
      quarks.textContent = String(startingQuarks + earnedQuarks);
      return;
    }
    const startedAt = performance.now();
    const tick = (now) => {
      const progress = Math.min((now - startedAt) / 900, 1);
      quarks.textContent = String(Math.round(startingQuarks + earnedQuarks * progress));
      if (progress < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }

  function crackVault() {
    if (cracked) return;
    cracked = true;
    const openVault = () => {
      vault.classList.remove('is-cracking');
      vault.classList.add('is-cracked');
      reveal.open = true;
      render();
      countUpQuarks();
      status.textContent = `Cracked it! The answer is 160 square metres. You solved it in ${stepCount} steps and earned ${earnedQuarks} quarks.`;
      answer.focus({ preventScroll: true });
    };
    if (reduceMotion) {
      openVault();
      return;
    }
    vault.classList.add('is-cracking');
    window.setTimeout(openVault, 520);
  }

  next.addEventListener('click', () => {
    if (stages[current] === 'vault') {
      crackVault();
    } else {
      goTo(current + 1);
    }
  });
  back.addEventListener('click', () => goTo(current - 1));
  nodes.forEach((node, name) => node.addEventListener('click', () => goTo(stages.indexOf(name))));
  vault.addEventListener('click', () => {
    if (stages[current] === 'vault') crackVault();
  });

  if (readsToggle && paper) {
    readsToggle.hidden = false;
    readsToggle.addEventListener('click', () => {
      const reading = readsToggle.getAttribute('aria-pressed') !== 'true';
      readsToggle.setAttribute('aria-pressed', String(reading));
      paper.classList.toggle('is-reading', reading);
    });
  }

  root.classList.add('is-enhanced');
  controls.hidden = false;
  render();
})();
