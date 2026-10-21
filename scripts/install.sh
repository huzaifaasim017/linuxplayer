#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

for tool in curl sha256sum dpkg apt-get; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "LinuxPlayer needs a Debian-based system with $tool installed." >&2
        exit 1
    fi
done

architecture="$(dpkg --print-architecture)"
if [[ "$architecture" != amd64 ]]; then
    echo "There is no LinuxPlayer release package for $architecture yet." >&2
    exit 1
fi

release_url="https://github.com/huzaifaasim017/linuxplayer/releases/latest/download"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

# Try the newest build first. apt's dependency solver decides which package
# works on this system; distribution names and version numbers are not gates.
for build in 26.04 24.04; do
    asset="linuxplayer_ubuntu${build}_${architecture}.deb"
    package="$download_dir/$asset"
    if ! curl -fsSL --retry 3 "$release_url/$asset" -o "$package" ||
       ! curl -fsSL --retry 3 "$release_url/$asset.sha256" -o "$package.sha256"; then
        echo "Could not download the latest LinuxPlayer release." >&2
        exit 1
    fi
    if ! (cd "$download_dir" && sha256sum --check --status "$asset.sha256"); then
        echo "Checksum verification failed for $asset; installation stopped." >&2
        exit 1
    fi

    if apt-get -s --no-remove install "$package" >"$download_dir/apt-check.log" 2>&1; then
        echo "Installing LinuxPlayer..."
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
            apt-get --no-remove install "$package"
        else
            sudo apt-get --no-remove install "$package"
        fi
        exit 0
    fi
done

echo "No current LinuxPlayer package fits this system's available dependencies." >&2
echo "See https://github.com/huzaifaasim017/linuxplayer/blob/main/docs/BUILDING.md for other systems." >&2
exit 1
