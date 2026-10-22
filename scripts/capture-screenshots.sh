#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v ffmpeg >/dev/null || { echo 'ffmpeg is required' >&2; exit 1; }
command -v linuxplayer >/dev/null || { echo 'Install the current LinuxPlayer build first' >&2; exit 1; }
test -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" || { echo 'A graphical desktop session is required' >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
video="$work/linuxplayer-v1-preview.mp4"
ffmpeg -hide_banner -loglevel error -y -f lavfi \
  -i 'gradients=s=1100x680:c0=0x132A4B:c1=0x765472:duration=12:speed=0' \
  -c:v libx264 -pix_fmt yuv420p -r 24 "$video"

mkdir -p "$root/docs/screenshots" "$root/web/assets/screenshots"
linuxplayer --capture-ui "$root/docs/screenshots/playback-v1.png" "$video"
linuxplayer --capture-options "$root/docs/screenshots/options-v1.png" "$video"
linuxplayer --capture-hidden "$root/docs/screenshots/hidden-v1.png" "$video"
linuxplayer --capture-mini "$root/docs/screenshots/mini-player-v1.png" "$video"
linuxplayer --capture-ui "$root/docs/screenshots/empty-v1.png"
cp "$root"/docs/screenshots/*-v1.png "$root/web/assets/screenshots/"
echo 'Captured the current desktop interface for the repository and website.'
