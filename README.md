# LinuxPlayer

A clean, modern player for videos on your Ubuntu desktop.

## Install

For **Ubuntu 24.04 LTS or 26.04 LTS (amd64)**, run:

```bash
curl -fsSLo /tmp/linuxplayer-install.sh https://github.com/huzaifaasim017/linuxplayer/releases/latest/download/install.sh && bash /tmp/linuxplayer-install.sh
```

The [installer script](scripts/install.sh) downloads the package for your Ubuntu version, checks its SHA-256 checksum, and installs it with `apt`. Open **LinuxPlayer** from the app menu or run `linuxplayer`. To remove it, run `sudo apt remove linuxplayer`.

Prefer a manual install? Download the `.deb` for your Ubuntu version from the [latest release](https://github.com/huzaifaasim017/linuxplayer/releases/latest), then run `sudo apt install ./filename.deb` in the download folder.

## Use

![LinuxPlayer playing a video](docs/screenshots/playback-wayland.png)

Open a video with **Open video**, drag a file into the window, or open a video with LinuxPlayer from your file manager. The player has seeking, speed, audio and subtitle tracks, resume, fullscreen, and a hideable control dock. Press **H** to hide or show controls; press **Space** to play or pause. A finished video plays again from the start when you press Play.

## For developers

[Build from source](docs/BUILDING.md) · [Contribute](CONTRIBUTING.md) · [Architecture](docs/ARCHITECTURE.md) · [Interface guide](docs/INTERFACE.md)

LinuxPlayer is open source under [GPL-3.0-or-later](LICENSE). Its playback engine is the system's libmpv; [third-party license details](docs/LICENSING.md).
