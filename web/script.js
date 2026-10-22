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

  const shots = {
    playback: { file: 'playback-v1-coast.png', title: 'Playback', alt: 'LinuxPlayer playback interface with lock control' },
    options: { file: 'options-v1-coast.png', title: 'Controls', alt: 'LinuxPlayer playback options popup' },
    hidden: { file: 'hidden-v1-coast.png', title: 'Video only', alt: 'LinuxPlayer video canvas with controls locked and hidden' },
    mini: { file: 'mini-player-v1-coast.png', title: 'Mini-player', alt: 'LinuxPlayer compact mini-player shown over an illustrative workspace' }
  };
  const tabs = [...document.querySelectorAll('.gallery-tabs [role="tab"]')];
  const galleryImage = document.querySelector('#gallery-image');
  const galleryPanel = document.querySelector('#gallery-panel');
  function showShot(key, focus = false) {
    const shot = shots[key];
    if (!shot) return;
    tabs.forEach(tab => {
      const active = tab.dataset.shot === key;
      tab.classList.toggle('active', active);
      tab.setAttribute('aria-selected', String(active));
      tab.tabIndex = active ? 0 : -1;
      if (active && focus) tab.focus();
    });
    galleryPanel.setAttribute('aria-labelledby', `tab-${key}`);
    galleryImage.src = `assets/screenshots/${shot.file}`;
    galleryImage.alt = shot.alt;
    document.querySelector('#gallery-image-wrap').classList.toggle('is-mini', key === 'mini');
    document.querySelector('#gallery-title').textContent = shot.title;
    document.querySelector('#gallery-source').href = `https://github.com/teamkrope/linuxplayer/blob/main/docs/screenshots/${shot.file}`;
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => showShot(tab.dataset.shot));
    tab.addEventListener('keydown', event => {
      if (!['ArrowRight', 'ArrowLeft', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      const next = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1 : (index + (event.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length;
      showShot(tabs[next].dataset.shot, true);
    });
  });

  // Keep one intrinsic 16:9 source. Only the surrounding canvas and object-fit change.
  const stage = document.querySelector('.ratio-stage');
  const canvas = document.querySelector('#demo-canvas');
  const demoImage = document.querySelector('#demo-image');
  const readout = document.querySelector('#ratio-readout');
  const ratios = [...document.querySelectorAll('.ratio-controls button')];
  const fits = [...document.querySelectorAll('.fit-controls button')];
  let selectedRatio = ratios[0];
  let selectedFit = fits[0];
  function sizeCanvas() {
    const [w, h] = selectedRatio.dataset.ratio.split('/').map(Number);
    const ratio = w / h;
    const maxWidth = Math.max(1, stage.clientWidth - 24);
    const maxHeight = Math.max(1, stage.clientHeight - 24);
    const width = Math.min(maxWidth, maxHeight * ratio);
    canvas.style.width = `${width}px`;
    canvas.style.height = `${width / ratio}px`;
  }
  function updateDemo() {
    ratios.forEach(button => {
      const active = button === selectedRatio;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    fits.forEach(button => {
      const active = button === selectedFit;
      button.classList.toggle('active', active);
      button.setAttribute('aria-pressed', String(active));
    });
    demoImage.style.objectFit = selectedFit.dataset.fit;
    readout.textContent = `${selectedRatio.textContent} · ${selectedFit.textContent}`;
    sizeCanvas();
  }
  ratios.forEach(button => button.addEventListener('click', () => {
    selectedRatio = button;
    updateDemo();
  }));
  fits.forEach(button => button.addEventListener('click', () => {
    selectedFit = button;
    updateDemo();
  }));
  new ResizeObserver(sizeCanvas).observe(stage);
  updateDemo();

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
