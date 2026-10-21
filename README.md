# LinuxPlayer

A modern, focused video player for Linux desktops. LinuxPlayer plays **local files** with a Qt Quick interface and the system's libmpv playback engine. The first target is Ubuntu and other Debian based systems; GNOME is the primary desktop, while the app uses cross-desktop Qt and freedesktop integration.

> **Preview:** LinuxPlayer is still an early MVP. See [PRODUCT.md](PRODUCT.md) for its current scope.

## Install

The current `.deb` supports **Ubuntu 26.04 (amd64)**. [Download the package from GitHub Releases](https://github.com/huzaifaasim017/linuxplayer/releases/tag/v0.1.0), then install it from your Downloads folder:

```bash
sudo apt install ~/Downloads/linuxplayer_0.1.0_ubuntu26.04_amd64.deb
```

Or download and install it with one terminal command:

```bash
curl -fL https://github.com/huzaifaasim017/linuxplayer/releases/download/v0.1.0/linuxplayer_0.1.0_ubuntu26.04_amd64.deb -o /tmp/linuxplayer.deb && sudo apt install /tmp/linuxplayer.deb
```

`apt` installs the required runtime packages automatically. Open **LinuxPlayer** from your app menu or run `linuxplayer`. Remove it with `sudo apt remove linuxplayer`. Other Ubuntu and Debian versions can [build from source](#build-from-source-on-ubuntu-or-debian) while packages for those systems are being tested.

The `v0.1.0` package is the earlier public preview. The interface changes shown below are in the current source and are not yet in that package.

## Interface preview

![Playback on Wayland with translucent controls](docs/screenshots/playback-wayland.png)

![Playback options on Wayland](docs/screenshots/options-wayland.png)

[Clean viewing mode](docs/screenshots/hidden-wayland.png) · [Empty state](docs/screenshots/empty-state.png) · [Resume prompt](docs/screenshots/resume-wayland.png)

## What the current app does

- Open a local video from the app, command line, or drag and drop.
- Play or pause, replay a finished video, seek, skip, change volume and speed, and use fullscreen.
- Choose audio and subtitle tracks and load an external subtitle file.
- Change playback speed, loop a video, switch between fit and fill, and save the current frame as a PNG.
- Show a compact control dock that fades while watching. Use the eye button or **H** to hide every control; move the pointer or press **H** to bring back the Show controls action.
- See a subtle loading indicator when a video takes time to open or buffer.

Useful keys: **Ctrl+O** opens a file; **Space/K** pauses; **Left/Right** skip 5 seconds; **J/L** skip 10 seconds; **Up/Down** adjust volume; **M** mutes; **F** toggles fullscreen; **Esc** leaves fullscreen; **H** hides or shows controls; **S** saves a frame; **R** loops the video; **[ / ]** change speed. Double-click the video to toggle fullscreen. The app remembers playback position for local files and offers a Resume or Start over choice. A media library is outside this MVP.

## Build from source on Ubuntu or Debian

Install the build tools and development libraries:

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config qt6-base-dev qt6-declarative-dev libmpv-dev libgl1-mesa-dev libqt6svg6
```

Configure and build:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
./build/linuxplayer
```

You can pass a local video path as the first argument:

```bash
./build/linuxplayer /path/to/video.mp4
```

LinuxPlayer uses distro-provided Qt and mpv libraries. Playback formats and hardware acceleration depend on how your distribution builds mpv/FFmpeg and on your graphics drivers.

## Install a source build or make a `.deb`

For a local CMake install:

```bash
sudo cmake --install build --prefix /usr
```

For a Debian package:

```bash
cd build
cpack -G DEB
sudo apt install ./linuxplayer_*.deb
```

Use `sudo apt remove linuxplayer` to uninstall a `.deb`. Prefer the package route if you want clean uninstall tracking. CPack reads the CMake install rules and discovers shared library dependencies with `dpkg-shlibdeps`. The package is built for the machine where you run these commands; do not assume a package built on one Ubuntu release will work on older releases.

## Development

- [Product scope](PRODUCT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Interface behavior](docs/INTERFACE.md)
- [Contributing](CONTRIBUTING.md)
- [Release checks](docs/RELEASING.md)

Bug reports and small improvements are welcome. Include your distribution version, desktop, display session (Wayland or X11), and a way to reproduce playback issues. Avoid uploading copyrighted video; a short freely shareable sample or MediaInfo details is usually enough.

## License

LinuxPlayer's own code and artwork are **GPL-3.0-or-later**; see [LICENSE](LICENSE). It dynamically uses system Qt and libmpv libraries. Those libraries retain their own licenses; see [third-party licensing](docs/LICENSING.md).
