#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v ffmpeg >/dev/null || { echo 'ffmpeg is required' >&2; exit 1; }
command -v linuxplayer >/dev/null || { echo 'Install the current LinuxPlayer build first' >&2; exit 1; }
test -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" || { echo 'A graphical desktop session is required' >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
video="$work/Coastal Evening.mp4"
ffmpeg -hide_banner -loglevel error -y -loop 1 \
  -i "$root/web/assets/ratio-source.webp" \
  -vf 'scale=1100:680:force_original_aspect_ratio=increase,crop=1100:680' \
  -t 12 -c:v libx264 -pix_fmt yuv420p -r 24 "$video"

mkdir -p "$root/docs/screenshots" "$root/web/assets/screenshots"
linuxplayer --capture-ui "$root/docs/screenshots/playback-v1-coast.png" "$video"
linuxplayer --capture-options "$root/docs/screenshots/options-v1-coast.png" "$video"
linuxplayer --capture-hidden "$root/docs/screenshots/hidden-v1-coast.png" "$video"
linuxplayer --capture-mini "$root/docs/screenshots/mini-player-v1-coast.png" "$video"
linuxplayer --capture-ui "$root/docs/screenshots/empty-v1-coast.png"
for view in playback options hidden mini-player; do
  cp "$root/docs/screenshots/$view-v1-coast.png" "$root/web/assets/screenshots/"
done
echo 'Captured the current desktop interface for the repository and website.'
