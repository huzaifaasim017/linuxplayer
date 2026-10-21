#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot detect this Linux distribution." >&2
    exit 1
fi
. /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "LinuxPlayer packages currently support Ubuntu 24.04 and 26.04. See the GitHub README for source builds." >&2
    exit 1
fi

case "${VERSION_ID:-}" in
    24.04|26.04) ;;
    *) echo "No tested package for Ubuntu ${VERSION_ID:-unknown}. See the GitHub README for source builds." >&2; exit 1 ;;
esac

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
    echo "LinuxPlayer packages currently support amd64 computers." >&2
    exit 1
fi

for tool in curl sha256sum apt; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required command not found: $tool" >&2
        exit 1
    fi
done

asset="linuxplayer_ubuntu${VERSION_ID}_amd64.deb"
release_url="https://github.com/huzaifaasim017/linuxplayer/releases/latest/download"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

curl -fL --retry 3 "$release_url/$asset" -o "$download_dir/$asset"
curl -fL --retry 3 "$release_url/$asset.sha256" -o "$download_dir/$asset.sha256"
(cd "$download_dir" && sha256sum -c "$asset.sha256")

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    apt install "$download_dir/$asset"
else
    sudo apt install "$download_dir/$asset"
fi
