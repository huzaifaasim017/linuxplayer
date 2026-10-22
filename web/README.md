# LinuxPlayer website

A two-page website for [LinuxPlayer](https://github.com/teamkrope/linuxplayer). It uses real application screenshots, the final bird mark shared with the desktop app, and an illustrative frame for the canvas demo. The site is self-contained and has no runtime or build dependencies beyond Node.js.

## Preview locally

```bash
cd web
npm run build
npm run check
npm run serve
```

Open <http://127.0.0.1:4173/>. The download hub is at <http://127.0.0.1:4173/download.html>. A local build deliberately blocks indexing.

## Publish

Set the final HTTPS root URL before building:

```bash
SITE_URL=https://teamkrope.github.io/linuxplayer/ npm run build
```

`dist/` contains the deployable static site, canonical URLs for both pages, Open Graph/Twitter image URLs, `robots.txt`, and a two-page `sitemap.xml`. The [Website workflow](../.github/workflows/pages.yml) builds and deploys this directory on changes to `web/` on `main`. Set GitHub Pages source to **GitHub Actions** in repository settings. For another host or domain, update `SITE_URL` in the workflow first. Do not publish a build created without `SITE_URL`; it deliberately disallows crawling.

The main download uses GitHub's stable latest-release URL for `linuxplayer_amd64.deb`; ARM64 is available as an optional link and through the installer. The release workflow publishes one package per CPU architecture, built on Ubuntu 24.04 and install-tested on Ubuntu 26.04. The installer link uses the latest `install.sh`, which detects architecture and checks the package checksum. Update product copy and screenshots when features change; screenshot source files live in `../docs/screenshots/`.

## Refresh the screenshots

Install the current build, open a graphical desktop session, and run `scripts/capture-screenshots.sh` from the repository root. The script turns the site's generated coastal frame into a short local sample video with FFmpeg, then uses LinuxPlayer's built-in capture commands to write playback, options, locked, and mini-player views to both `docs/screenshots/` and `web/assets/screenshots/`. The start-screen capture stays in `docs/screenshots/` for documentation. Review each capture before publishing. The `*-v1-coast.png` filenames replace the earlier gradient captures and prevent stale browser image caches.

## Content and attribution

All product behavior is based on the LinuxPlayer repository. Screenshot links in the gallery point to their original source files. The PiP desktop arrangement is illustrative; the mini-player inside it is an actual app capture. `assets/ratio-source.webp` is an AI-generated illustration used only to demonstrate Fit and Fill. `assets/linuxplayer-bird.png` is the rounded app icon shared with the desktop application, generated from `../assets/linuxplayer-bird-source.png` by `../scripts/build-icon.sh`. The website uses no analytics, trackers, external font service, or cookie storage. The website is distributed under [GPL-3.0-or-later](LICENSE), matching LinuxPlayer's [application license](https://github.com/teamkrope/linuxplayer/blob/main/LICENSE).
