# LinuxPlayer

A clean, modern video player for Linux.

## Install

On Ubuntu or another Debian-based Linux system (64-bit), run:

```bash
curl -fsSLo /tmp/linuxplayer-install.sh \
  https://github.com/huzaifaasim017/linuxplayer/releases/latest/download/install.sh
bash /tmp/linuxplayer-install.sh
```

The [installer](scripts/install.sh) checks which release package fits your system, verifies its checksum, and installs it with `apt`. Open **LinuxPlayer** from the app menu or run `linuxplayer`. To remove it, run `sudo apt remove linuxplayer`.

Prefer a manual install? Download a `.deb` from the [latest release](https://github.com/huzaifaasim017/linuxplayer/releases/latest), then run `sudo apt install ./filename.deb` in the download folder. See [compatibility and source builds](docs/BUILDING.md) if your system's packages differ.

## Use

![LinuxPlayer playing a video](docs/screenshots/playback-wayland.png)

Open a video with **Open video**, drag a file into the window, or open it from your file manager. The player has seeking, speed, audio and subtitle tracks, resume, fullscreen, and a compact mini-player. Press **Space** to play or pause, **H** to hide or show controls, **I** for the mini-player, and **F1** for all shortcuts. Number keys jump through the video. A finished video plays again from the start when you press Play.

In **More options**, choose **Canvas ratio** to preview a video in common social formats or a custom width:height ratio. **Fit/Fill** controls whether the video is letterboxed or cropped inside that canvas. This is a playback preview; it does not change or export the file. Choose **Make default video player** there if you want LinuxPlayer to open supported video files from your file manager. This changes your user-level desktop defaults only when you click it.

## For developers

[Build from source](docs/BUILDING.md) · [Contribute](CONTRIBUTING.md) · [Architecture](docs/ARCHITECTURE.md) · [Interface guide](docs/INTERFACE.md) · [Support](SUPPORT.md)

LinuxPlayer is open source under [GPL-3.0-or-later](LICENSE). Its playback engine is the system's libmpv; [third-party license details](docs/LICENSING.md).
