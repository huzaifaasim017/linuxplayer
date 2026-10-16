# Release guide

This checklist is for a tagged source release and a Debian package built on a supported Ubuntu or Debian system. Publishing to GitHub is a maintainer decision; a successful local build alone is not a release.

## 1. Set the release scope

- Decide the supported distribution versions, CPU architectures, and known limits based on machines or VMs actually tested.
- Update the version in the top-level CMake project and release notes.
- Check [PRODUCT.md](../PRODUCT.md) against implemented features. Remove claims for behavior not verified.
- Verify that the project's GitHub profile has a working private Code of Conduct contact method.
- Check that the AppStream homepage in `assets/io.github.teamkrope.LinuxPlayer.metainfo.xml` points to the published repository.
- Replace the CPack maintainer contact in `cmake/Packaging.cmake` with a monitored project address before distributing packages.

## 2. Build from a clean checkout

```bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release --parallel
ctest --test-dir build-release --output-on-failure
cd build-release
cpack -G DEB
```

The `qml_startup` test checks that the packaged QML loads in Qt's offscreen mode. Complete the manual video and desktop checks below before publishing.

## 3. Inspect the package

```bash
dpkg-deb -I linuxplayer_*.deb
dpkg-deb -c linuxplayer_*.deb
desktop-file-validate ../assets/io.github.teamkrope.LinuxPlayer.desktop
appstreamcli validate --no-net ../assets/io.github.teamkrope.LinuxPlayer.metainfo.xml
```

Confirm that `Depends` includes needed shared libraries, `/usr/bin/linuxplayer` exists, and the desktop file, icon, AppStream metadata, documentation, and license are installed in the expected locations. The package must not install files into a user's home directory.

## 4. Test an install

On a clean VM or container with a graphical session matching the supported release:

```bash
sudo apt install ./linuxplayer_*.deb
linuxplayer /path/to/test-video.mp4
sudo apt remove linuxplayer
```

Check the launcher, file manager **Open With**, install and uninstall behavior, and command-line path with spaces. Use redistributable sample videos. Test MP4/H.264, MKV, WebM, embedded and external subtitles, multiple audio tracks, seek, speed, volume, and fullscreen. Try Wayland and X11 separately. Note any driver or codec difference observed. The [product brief](../PRODUCT.md) has the full acceptance scope.

## 5. Publish

- Tag the source commit with a version such as `v0.1.0`.
- Attach the `.deb` built for each tested distribution and architecture to the GitHub release. Name assets so users can distinguish them.
- Publish checksums, screenshots, a short demo, supported systems, known limitations, and source/build instructions.
- Install each uploaded asset once more using the published download to catch packaging mistakes.

Later, Flatpak/Flathub can be added as a separate distribution path after `.deb` releases are reliable.

References: [CPack DEB generator](https://cmake.org/cmake/help/latest/cpack_gen/deb.html), [Debian package dependency policy](https://www.debian.org/doc/debian-policy/ch-binary.html#dependencies), [Desktop Entry specification](https://specifications.freedesktop.org/desktop-entry/latest-single/).
