(() => {
  const menuButton = document.querySelector('.menu-toggle');
  const menu = document.querySelector('.nav-links');
  const closeMenu = () => {
    menu.classList.remove('open');
    menuButton.setAttribute('aria-expanded', 'false');
    menuButton.setAttribute('aria-label', 'Open menu');
  };
  menuButton.addEventListener('click', () => {
    const open = menu.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  });
  menu.querySelectorAll('a').forEach(link => link.addEventListener('click', closeMenu));
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') closeMenu();
  });

  const copyButton = document.querySelector('#copy-command');
  copyButton.addEventListener('click', async () => {
    const command = document.querySelector('#install-command').textContent;
    try {
      await navigator.clipboard.writeText(command);
      copyButton.textContent = 'Copied';
      copyButton.setAttribute('aria-label', 'Install commands copied');
    } catch {
      copyButton.textContent = 'Select command to copy';
    }
    window.setTimeout(() => {
      copyButton.textContent = 'Copy command';
      copyButton.setAttribute('aria-label', 'Copy install commands');
    }, 2300);
  });

  document.querySelector('#year').textContent = new Date().getFullYear();
})();
