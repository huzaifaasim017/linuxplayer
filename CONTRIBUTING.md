# Contributing to LinuxPlayer

Thanks for helping make LinuxPlayer better. We welcome bug reports, usability feedback, documentation, translations, design improvements, and code.

## Before starting

Search existing issues and pull requests for related work. For a large feature or architectural change, open an issue with the user problem, proposed behavior, and scope so maintainers and contributors can agree on a small first slice. Smaller fixes can go straight to a pull request.

The [first-release brief](PRODUCT.md) describes current scope. Keep additions focused on local playback and the watching experience.

## Build and test

Follow the [build instructions](README.md#build-on-ubuntu-or-debian). For a code change:

For a quick QML startup check, run `ctest --test-dir build --output-on-failure`. To capture the empty state for visual review, run `QT_QPA_PLATFORM=offscreen ./build/linuxplayer --capture-ui /tmp/linuxplayer-ui.png`.

1. Reproduce the issue before editing, if possible.
2. Keep playback engine calls in the C++ playback layer; expose UI state and actions to QML through its public interface.
3. Run a fresh CMake build and any available tests.
4. Manually try the changed behavior with a local file, including keyboard navigation if the UI changed.
5. Include the commands you ran and their results in the pull request.

If a problem occurs only under Wayland, X11, GNOME, KDE, or a particular GPU, say so. A short reproducible sample is more useful than a large film file.

## Pull requests

- Keep one change per pull request and explain **what changed**, **why**, and **how it was checked**.
- Update user or contributor documentation when behavior or setup changes.
- Use clear names and make focus, contrast, and target sizes part of UI review.
- Do not add vendored codec binaries, copyrighted media, secrets, or generated build output.
- Keep the app's own code and artwork compatible with GPL-3.0-or-later. Mention new third-party assets or dependencies and their licenses.

By submitting a contribution, you agree to license it under the project's GPL-3.0-or-later license. You retain your copyright. Contributors should add an SPDX header to new code files where appropriate: `SPDX-License-Identifier: GPL-3.0-or-later`.

## Conduct

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Be patient with first-time contributors and focus feedback on the work.
