(() => {
  document.querySelectorAll('a[target="_blank"]').forEach(link => {
    if (!link.hasAttribute('aria-label')) {
      link.setAttribute('aria-label', `${link.textContent.trim()} (opens in new tab)`);
    }
  });

  if (!('IntersectionObserver' in window) || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const targets = document.querySelectorAll([
    'main .hero-copy', 'main .hero-shot', 'main .section-head',
    'main .feature-shot', 'main .feature-list article',
    'main .pip-copy', 'main .workspace-figure', 'main .ratio-demo',
    'main .gallery', 'main .download-grid > *', 'main .source-grid > *',
    'main .faq-grid > *', 'main .package-card', 'main .download-help-grid > *'
  ].join(', '));

  targets.forEach(target => {
    target.classList.add('reveal');
    // The first viewport should be readable even before the observer's first paint.
    if (target.getBoundingClientRect().top < window.innerHeight * 0.94) {
      target.classList.add('is-visible');
    }
    if (target.matches('.feature-list article')) {
      const index = [...target.parentElement.children].indexOf(target);
      target.style.setProperty('--reveal-delay', `${Math.min(index, 5) * 55}ms`);
    }
  });

  document.documentElement.classList.add('motion-ready');
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    });
  }, { threshold: 0.08, rootMargin: '0px 0px -6% 0px' });
  targets.forEach(target => observer.observe(target));
})();
