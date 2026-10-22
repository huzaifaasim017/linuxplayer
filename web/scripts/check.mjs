import { readFile, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'dist');
const html = await readFile(path.join(root, 'index.html'), 'utf8');
const download = await readFile(path.join(root, 'download.html'), 'utf8');
for (const text of ['LinuxPlayer', 'id="download"', 'id="features"', 'id="preview"', 'id="open-source"', 'application/ld+json', 'releases/latest/download/install.sh']) {
  if (!html.includes(text)) throw new Error(`Missing required site content: ${text}`);
}
for (const asset of ['linuxplayer_amd64.deb', 'linuxplayer_arm64.deb']) {
  if (!download.includes(`/releases/latest/download/${asset}`)) throw new Error(`Missing latest direct download: ${asset}`);
}
for (const file of ['styles.css', 'script.js', 'download.js', 'robots.txt', 'LICENSE', 'assets/linuxplayer-bird.png', 'assets/ratio-source.webp', 'assets/screenshots/playback-wayland.png', 'assets/screenshots/options-wayland.png', 'assets/screenshots/hidden-wayland.png', 'assets/screenshots/mini-player-wayland.png']) {
  if (!(await stat(path.join(root, file))).isFile()) throw new Error(`Missing asset: ${file}`);
}
console.log('Site content and required assets verified.');
