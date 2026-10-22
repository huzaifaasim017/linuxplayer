import { readFile, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'dist');
const html = await readFile(path.join(root, 'index.html'), 'utf8');
const download = await readFile(path.join(root, 'download.html'), 'utf8');
const script = await readFile(path.join(root, 'script.js'), 'utf8');
if ([html, download].some(page => page.includes('Download for Linux'))) throw new Error('Primary download buttons must say Download');
if (!html.includes('playback-v1-coast.png') || !script.includes('options-v1-coast.png')) throw new Error('Current screenshots are not linked from the site');
if (html.includes('Start screen') || script.includes('empty-v1-coast.png')) throw new Error('Removed gallery tab is still present');
if (![html, download].every(page => page.includes('motion.js') && page.includes('footer-line'))) throw new Error('Shared motion or compact footer missing');
if (!html.includes('showcase.css') || !html.includes('class="hero-shot"') || !html.includes('data-scroll-scene')) throw new Error('Product showcase is missing');
if (!(html.indexOf('class="hero-copy"') < html.indexOf('class="hero-shot"') && html.indexOf('class="hero-shot"') < html.indexOf('class="hero-actions"'))) throw new Error('Hero must show title, product image, then actions');
if (!html.includes('class="focus-gallery"') || !html.includes('class="focus-shot focus-shot-controls"') || !html.includes('class="focus-brand"')) throw new Error('Showcase image mosaic or app mark missing');
if (html.includes('class="hero-mark"') || html.includes('class="download-mark"')) throw new Error('App mark belongs with the feature mosaic');
for (const text of ['LinuxPlayer', 'id="download"', 'id="features"', 'id="preview"', 'id="open-source"', 'application/ld+json', 'releases/latest/download/install.sh']) {
  if (!html.includes(text)) throw new Error(`Missing required site content: ${text}`);
}
for (const asset of ['linuxplayer_amd64.deb', 'linuxplayer_arm64.deb']) {
  if (!download.includes(`/releases/latest/download/${asset}`)) throw new Error(`Missing latest direct download: ${asset}`);
}
for (const file of ['styles.css', 'showcase.css', 'motion.js', 'script.js', 'download.js', 'robots.txt', 'LICENSE', 'assets/linuxplayer-bird.png', 'assets/external-link.svg', 'assets/ratio-source.webp', 'assets/screenshots/playback-v1-coast.png', 'assets/screenshots/options-v1-coast.png', 'assets/screenshots/hidden-v1-coast.png', 'assets/screenshots/mini-player-v1-coast.png']) {
  if (!(await stat(path.join(root, file))).isFile()) throw new Error(`Missing asset: ${file}`);
}
console.log('Site content and required assets verified.');
