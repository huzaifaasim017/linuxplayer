#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_icon="$root/assets/linuxplayer-bird-source.png"
app_icon="$root/assets/io.github.teamkrope.LinuxPlayer.png"

command -v ffmpeg >/dev/null || { echo 'ffmpeg is required to regenerate the icon' >&2; exit 1; }
test -f "$source_icon"

# Compose the original artwork on an opaque white rounded square. The transparent
# corners let the launcher shape sit cleanly against both dark and light themes.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i 'color=c=white:s=1024x1024:d=1' \
  -i "$source_icon" \
  -filter_complex "[0:v]format=rgba,geq=r='255':g='255':b='255':a='if(gt(between(X,164,859)+between(Y,164,859),0),255,if(lte(pow(164-min(X,1023-X),2)+pow(164-min(Y,1023-Y),2),26896),255,0))'[bg];[1:v]scale=860:860:force_original_aspect_ratio=decrease[logo];[bg][logo]overlay=(W-w)/2:(H-h)/2:format=auto,format=rgba[out]" \
  -map '[out]' -frames:v 1 "$app_icon"

echo 'Updated the app icon. Sync it to the website repository when the design changes.'
