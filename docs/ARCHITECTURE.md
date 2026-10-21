# Architecture

LinuxPlayer is deliberately small. Its interface, playback integration, and packaging have separate responsibilities so contributors can change one without understanding every part of the player.

```text
local file / file manager / command line
                 │
                 ▼
       Qt Quick interface (qml/)
                 │ public properties and actions
                 ▼
        MpvItem (src/MpvItem.*)
        ├─ libmpv events and playback commands
        └─ libmpv render API → Qt Quick OpenGL framebuffer
                 │
                 ▼
      system mpv / FFmpeg / GPU drivers
```

## Modules

| Path | Responsibility |
| --- | --- |
| `src/main.cpp` | Start Qt, expose playback and window operations to QML, open a command-line file. |
| `src/MpvItem.h` and `.cpp` | Own the libmpv handle and render context; expose playback state and commands to QML. |
| `src/DesktopIntegration.h` and `.cpp` | Set and verify user-requested video MIME defaults through `xdg-mime`. |
| `src/WindowOperations.h` | Ask the window system to move or resize the compact player from a pointer press. |
| `qml/Main.qml` | Window layout, file actions, control overlay, settings menus, shortcuts, and focus behavior. |
| `qml/components/` | Reusable interface components. |
| `qml/icons/` | Interface icon assets. |
| `assets/` | Installed launcher, application icon, and AppStream metadata. |
| `cmake/Packaging.cmake` | CPack settings for Debian packages. |

The UI must treat `MpvItem` as its playback boundary. When adding a new libmpv feature, expose a concise property or method in C++ first, then bind the QML interface to that API. Keep file-system and playback errors visible to the UI rather than silently swallowing them. Avoid embedding codec behavior or direct mpv calls in QML.

The playback adapter also owns file looping, fit/fill (`panscan`), and screenshot commands. `Main.qml` only changes its properties or calls its methods. The [interface guide](INTERFACE.md) describes overlay states, shortcuts, and icon rendering for UI contributors.

`MpvItem` observes libmpv's `eof-reached` property because `keep-open=yes` pauses on the final frame instead of unloading the file. Its `ended` state lets the primary Play action seek to zero and resume. The adapter also exposes opening and cache buffering states; QML delays the spinner to keep short file opens visually quiet.

Resume positions are stored in the user's Qt settings under a hash of the local file path. `MpvItem` writes periodically, removes a position after playback reaches the end, and emits `resumeSuggested` for the QML prompt. No media filenames are stored in the settings keys.

## Rendering and desktop integration

`MpvItem` is a `QQuickFramebufferObject`. It uses libmpv's render API to draw into Qt Quick's OpenGL framebuffer, allowing QML controls to sit over video in the same scene. This requires a working OpenGL path under both Wayland and X11. Test those sessions separately when changing rendering, fullscreen, scaling, or overlay behavior.

Mini-player mode resizes the existing `ApplicationWindow` and keeps the same `MpvItem`. `Main.qml` stores the normal geometry and window flags, then restores them on exit. `WindowOperations` calls Qt's native move and resize requests, which work with Wayland's compositor-managed positioning. The compositor can ignore the always-on-top hint.

**Known technical constraint:** Qt documents `QQuickFramebufferObject` as a legacy, OpenGL-only class. `main.cpp` therefore forces Qt Quick to use OpenGL. This is a deliberate MVP tradeoff for a small render adapter, not a promise of Vulkan or software-renderer support. Future rendering work should evaluate a Qt 6 scene graph/QRhi path while preserving the `MpvItem` public playback API. See [Qt's class documentation](https://doc.qt.io/qt-6/qquickframebufferobject.html).

The desktop entry uses the same application ID as the icon and AppStream metadata: `io.github.teamkrope.LinuxPlayer`. Keep these names aligned when renaming the app. It declares video MIME types so file managers can offer **Open With**. The `DesktopIntegration` service changes per-user defaults only after an explicit click; it verifies the installed desktop entry and each `xdg-mime` association asynchronously so the UI stays responsive.

Canvas presets are QML data because they only change the size of the centered `MpvItem` parent. The playback adapter's existing fit/fill control handles source framing within that parent. Presets do not alter media bytes or capture/export settings.

## Extending the MVP

Prefer small, observable changes. Examples:

- New playback control: add an `MpvItem` method/property, then a QML control and shortcut.
- New visual style: keep rendering and engine code untouched; test contrast over dark and bright frames.
- New distribution format: consume the same CMake install tree where possible so desktop metadata stays consistent.

Before splitting this into more libraries or processes, identify a concrete problem the split solves. A compact boundary around libmpv is enough for the MVP; adding layers without a use case would make first contributions harder.
