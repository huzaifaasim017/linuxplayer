# LinuxPlayer

A clean, modern video player for Linux.

[Website](https://teamkrope.github.io/linuxplayer/) · [Contact](mailto:contact@teamkrope.com)

## Download

[**Download for Linux (.deb, 64-bit x86)**](https://github.com/teamkrope/linuxplayer/releases/latest/download/linuxplayer_amd64.deb)

Open the downloaded file with your package installer, or run `sudo apt install ./linuxplayer_amd64.deb` from its folder. The package is built on an older supported Ubuntu baseline and install-tested on newer Ubuntu. Your package manager checks dependencies on your system.

For ARM64, or to let the installer choose the matching package and verify its checksum, run:

```bash
curl -fsSLo /tmp/linuxplayer-install.sh \
  https://github.com/teamkrope/linuxplayer/releases/latest/download/install.sh
bash /tmp/linuxplayer-install.sh
```

The [installer](scripts/install.sh) detects `amd64` or `arm64`, verifies the package checksum, and installs it with `apt`. Open **LinuxPlayer** from the app menu or run `linuxplayer`. To remove it, run `sudo apt remove linuxplayer`.

See [compatibility and source builds](docs/BUILDING.md) if your system's packages differ.

## Use

![LinuxPlayer playing a video](docs/screenshots/playback-wayland.png)

Open a video with **Open video**, drag a file into the window, or open it from your file manager. The player has seeking, speed, audio and subtitle tracks, resume, fullscreen, and a compact mini-player. Press **Space** to play or pause, **H** to lock or unlock controls, **I** for the mini-player, and **F1** for all shortcuts. Controls disappear as playback starts. Lock mode keeps the video clear until you move the pointer to reveal the unlock button or press **H**. Number keys jump through the video. A finished video plays again from the start when you press Play.

In **More options**, choose **Canvas ratio** to preview a video in common social formats or a custom width:height ratio. **Fit/Fill** controls whether the video is letterboxed or cropped inside that canvas. This is a playback preview; it does not change or export the file. **Use system accent** applies your desktop's selected color to player highlights. Choose **Make default video player** if you want LinuxPlayer to open supported video files from your file manager. That action disappears while LinuxPlayer is the default and returns if you change the default later.

## For developers

[Build from source](docs/BUILDING.md) · [Contribute](CONTRIBUTING.md) · [Architecture](docs/ARCHITECTURE.md) · [Interface guide](docs/INTERFACE.md) · [Support](SUPPORT.md)

LinuxPlayer is open source under [GPL-3.0-or-later](LICENSE). Its playback engine is the system's libmpv; [third-party license details](docs/LICENSING.md).
