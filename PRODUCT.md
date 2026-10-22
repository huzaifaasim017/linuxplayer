# LinuxPlayer — product direction

## Product

A local video player for Ubuntu and other Debian based desktops. It opens a file quickly and puts the controls people use most within reach, with an interface inspired by modern web video players.

This is a desktop application, not a website or browser extension. Video decoding should use an established playback engine rather than a custom codec stack.

## First release promise

Open a local video and watch it comfortably on Ubuntu. The first release should work well on both Wayland and X11, with mouse and keyboard.

## Current experience

The player includes playback controls, resume, a compact mini-player, delayed loading feedback, and replay after a video ends. Controls fade as soon as playback starts; brief animations acknowledge clicks, skips, seeking, volume, and fullscreen. Users can choose a centered canvas preview ratio for common social layouts or a custom width:height ratio. This preview does not create a new video file. An explicit action sets LinuxPlayer as the default handler for supported video MIME types and disappears while those associations remain selected. The empty state keeps **Open video** primary. The website's bird mark and navy/teal identity carry into the app, with an optional system accent setting.

## First release scope

- Open a file from the app, file manager, command line, or drag and drop.
- Play and pause; seek with a clear timeline; skip backward or forward; change volume and mute.
- Switch playback speed, audio track, and subtitle track; load an external subtitle file.
- Fullscreen and a clean control overlay that fades while watching.
- Compact picture-in-picture player with playback continuity and a restore action.
- Remember the last position of a local file, with a clear resume choice.
- Show useful errors for unsupported files or missing codecs.
- Provide sensible shortcuts, visible in a small help panel.

## Later, after the core is reliable

- Playlist and next episode flow.
- Thumbnail previews and subtitle styling.
- Network streams and online video links.
- Media library, accounts, recommendations, or cloud sync.

## Technical direction

Use Qt Quick/QML for the interface and libmpv for playback. libmpv supplies mature playback, tracks, subtitles, seeking, and format support; QML supports a custom interface. Keep playback integration behind a small adapter so the interface does not call libmpv everywhere. Use the libmpv render API for the video surface rather than attaching a foreign window.

Target Ubuntu 24.04 LTS and a second current Debian based system during the first release. Test on Wayland and X11, plus at least one Intel/AMD machine and one NVIDIA machine if available.

## Design direction

One video canvas, one compact overlay. Large, readable timeline and controls. Strong contrast over dark and bright frames. No permanent sidebar, heavy chrome, or settings wall. Keyboard and touch targets need deliberate sizes. The empty state should make **Open video** the obvious primary action.

## Release route

1. Publish source and tagged builds on GitHub, with one `.deb` per supported CPU architecture, built on an older Ubuntu baseline and tested on newer Ubuntu.
2. Add desktop integration (`.desktop` file, icon, MIME types) and install/uninstall checks.
3. Add Flatpak/Flathub after the first `.deb` works well. Flatpak broadens distribution, while a `.deb` keeps installation straightforward for the initial Debian/Ubuntu audience.
4. Publish screenshots, a short demo, supported systems, and known limits with each release.

## Validation before calling it usable

- Open and seek in MP4/H.264, MKV/H.264, and WebM files.
- Select embedded and external subtitles and multiple audio tracks.
- Open from the file manager and command line.
- Confirm seek, fullscreen, and overlay behavior under Wayland and X11.
- Install, launch, remove, and reinstall the package on a clean supported system.

## Product test

Before building many extras, show a clickable design or early build to several Ubuntu users. Ask them to open a film, seek, enable subtitles, change speed, and enter fullscreen without instructions. Keep the first release small until those tasks feel effortless.
