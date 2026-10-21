# Build LinuxPlayer from source

The packaged release supports Ubuntu 24.04 LTS and 26.04 LTS on amd64. Contributors and users on other systems can build from source when their distribution supplies Qt 6.4 or newer and libmpv development packages.

On Ubuntu or Debian, install the build tools:

```bash
sudo apt update
sudo apt install build-essential cmake pkg-config qt6-base-dev qt6-declarative-dev libmpv-dev libgl1-mesa-dev libqt6svg6
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

Packages built on one distribution may require libraries unavailable on another. The [release workflow](../.github/workflows/release.yml) builds separate packages for Ubuntu 24.04 and 26.04. Playback formats and hardware acceleration depend on the distribution's mpv/FFmpeg packages and graphics drivers.
