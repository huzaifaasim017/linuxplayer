# Build LinuxPlayer from source

The installer detects `amd64` or `arm64`, downloads one package for that architecture, verifies its checksum, and uses `apt` to check the libraries on your system. Release packages are built on Ubuntu 24.04 and install-tested on Ubuntu 24.04 and 26.04 for both architectures. Other Ubuntu and Debian-based versions may work when they provide compatible dependencies; they are not covered by the release tests. Contributors and users on other systems can build from source when their distribution supplies Qt 6.4 or newer and libmpv development packages.

On Ubuntu or Debian, install the build tools:

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config qt6-base-dev qt6-declarative-dev libmpv-dev libgl1-mesa-dev libqt6svg6 xdg-utils \
  qml6-module-qtqml qml6-module-qtqml-workerscript qml6-module-qtquick \
  qml6-module-qtquick-window qml6-module-qtquick-controls qml6-module-qtquick-templates \
  qml6-module-qtquick-dialogs qml6-module-qtquick-layouts
```

On Ubuntu 26.04, add the SVG image plugin for the interface icons:

```bash
sudo apt install qt6-svg-plugins
```

Build and run:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
./build/linuxplayer
```

Pass a local video path as the first argument if desired:

```bash
./build/linuxplayer /path/to/video.mp4
```

To make a local Debian package:

```bash
cd build
cpack -G DEB
sudo apt install ./linuxplayer_*.deb
```

Packages built on one distribution may require libraries unavailable on another. The [release workflow](../.github/workflows/release.yml) builds on Ubuntu 24.04 for `amd64` and `arm64`, then verifies installation on Ubuntu 26.04 as well. The package names identify CPU architecture, not an Ubuntu version. Playback formats and hardware acceleration depend on the distribution's mpv/FFmpeg packages and graphics drivers.
