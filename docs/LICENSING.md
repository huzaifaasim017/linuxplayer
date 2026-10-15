# Licensing and distribution

LinuxPlayer's source code, documentation, and original artwork are licensed under **GPL-3.0-or-later**. The full GPL version 3 text is in [LICENSE](../LICENSE). The "or later" grant is stated here and in SPDX identifiers on source files.

The application links dynamically to **system-provided** Qt and libmpv libraries. Their licenses are separate from LinuxPlayer's license:

- Qt's commonly used open source modules are available under LGPL-3.0 or GPL-3.0. Check the licenses of each Qt module used by a release and comply with Qt's open source obligations.
- mpv is GPL-2.0-or-later by default; a special build without GPL-only files can be LGPL-2.1-or-later. Debian/Ubuntu `libmpv` packages and their FFmpeg dependencies may have additional license details. Do not describe an arbitrary system `libmpv` as LGPL-only.

The `.deb` should depend on distribution libraries rather than bundling them. Check the generated package's `Depends` field with `dpkg-deb -f path/to/package.deb Depends`. For release, record the build distribution, package versions, architecture, and licenses of dependencies. Source and matching build instructions must be available with binary releases.

Sources: [mpv copyright](https://github.com/mpv-player/mpv/blob/master/Copyright), [Qt open source obligations](https://www.qt.io/development/open-source-lgpl-obligations), [Debian copyright policy](https://www.debian.org/doc/debian-policy/ch-docs.html#copyright-information).
