// Shared behaviour for every page of the public website. Everything here is an
// enhancement: each page reads and works without it.
(() => {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const header = document.querySelector('[data-site-header]');
  if (header) {
    const updateHeader = () => header.classList.toggle('is-scrolled', window.scrollY > 8);
    updateHeader();
    window.addEventListener('scroll', updateHeader, { passive: true });
  }

  const menu = document.querySelector('[data-nav-menu]');
  if (menu) {
    menu.addEventListener('click', (event) => {
      if (event.target.closest('a')) menu.open = false;
    });
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && menu.open) {
        menu.open = false;
        menu.querySelector('summary').focus();
      }
    });
  }

  // Only elements that start below the fold fade in, so nothing on screen
  // ever blinks out and back while the page loads.
  if (!reduceMotion && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const element = entry.target;
        element.classList.add('is-visible');
        // Once in place, hand the element's transform back to its own styles
        // (hover lifts, tilts).
        element.addEventListener('transitionend', () => {
          element.classList.remove('reveal-pending', 'is-visible');
        }, { once: true });
        observer.unobserve(element);
      }
    }, { rootMargin: '0px 0px -8% 0px' });
    document.querySelectorAll('[data-reveal]').forEach((element) => {
      if (element.getBoundingClientRect().top < window.innerHeight * 0.92) return;
      element.classList.add('reveal-pending');
      observer.observe(element);
    });
  }

  if (!reduceMotion && window.matchMedia('(pointer: fine)').matches) {
    document.querySelectorAll('[data-tilt]').forEach((card) => {
      card.addEventListener('pointermove', (event) => {
        const box = card.getBoundingClientRect();
        const x = (event.clientX - box.left) / box.width;
        const y = (event.clientY - box.top) / box.height;
        card.style.setProperty('--tilt-x', `${((0.5 - y) * 14).toFixed(2)}deg`);
        card.style.setProperty('--tilt-y', `${((x - 0.5) * 18).toFixed(2)}deg`);
        card.style.setProperty('--glare-x', `${(x * 100).toFixed(1)}%`);
        card.style.setProperty('--glare-y', `${(y * 100).toFixed(1)}%`);
      });
      card.addEventListener('pointerleave', () => {
        for (const name of ['--tilt-x', '--tilt-y', '--glare-x', '--glare-y']) {
          card.style.removeProperty(name);
        }
      });
    });
  }
})();
