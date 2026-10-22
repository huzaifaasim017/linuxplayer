import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.join(root, 'dist');
const requestedUrl = process.env.SITE_URL?.trim();
let siteUrl = null;

if (requestedUrl) {
  const parsed = new URL(requestedUrl);
  if (parsed.protocol !== 'https:' || parsed.search || parsed.hash) {
    throw new Error('SITE_URL must be a public HTTPS URL without query or fragment.');
  }
  siteUrl = parsed.href.endsWith('/') ? parsed.href : `${parsed.href}/`;
}

await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
await cp(path.join(root, 'assets'), path.join(output, 'assets'), { recursive: true });
await cp(path.join(root, 'styles.css'), path.join(output, 'styles.css'));
await cp(path.join(root, 'showcase.css'), path.join(output, 'showcase.css'));
await cp(path.join(root, 'script.js'), path.join(output, 'script.js'));
await cp(path.join(root, 'motion.js'), path.join(output, 'motion.js'));
await cp(path.join(root, 'download.js'), path.join(output, 'download.js'));
await cp(path.join(root, 'LICENSE'), path.join(output, 'LICENSE'));

for (const page of ['index.html', 'download.html']) {
  let html = await readFile(path.join(root, page), 'utf8');
  if (siteUrl) {
    const pageUrl = page === 'index.html' ? siteUrl : new URL(page, siteUrl).href;
    const imageUrl = new URL('assets/screenshots/playback-v1-coast.png', siteUrl).href;
    html = html.replace('<!-- SEO_URLS -->', [
      `<link rel="canonical" href="${pageUrl}">`,
      `<meta property="og:url" content="${pageUrl}">`,
      `<meta property="og:image" content="${imageUrl}">`,
      `<meta name="twitter:image" content="${imageUrl}">`
    ].join('\n  '));
  } else {
    html = html.replace('<!-- SEO_URLS -->', '');
  }
  await writeFile(path.join(output, page), html);
}

if (siteUrl) {
  const urls = [siteUrl, new URL('download.html', siteUrl).href];
  const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map(url => `  <url><loc>${url.replaceAll('&', '&amp;')}</loc></url>`).join('\n')}\n</urlset>\n`;
  await writeFile(path.join(output, 'sitemap.xml'), xml);
  await writeFile(path.join(output, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${new URL('sitemap.xml', siteUrl).href}\n`);
} else {
  await writeFile(path.join(output, 'robots.txt'), 'User-agent: *\nDisallow: /\n');
}
console.log(`Built ${output}${siteUrl ? ` for ${siteUrl}` : ' for local preview (no public canonical URL)'}`);
