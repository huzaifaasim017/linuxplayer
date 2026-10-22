# Included by the top-level CMakeLists.txt after project() and install() rules.
# The package contains the same install tree as `cmake --install`.
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "linuxplayer")
set(CPACK_PACKAGE_VENDOR "LinuxPlayer contributors")
set(CPACK_PACKAGE_CONTACT "TeamKrope <contact@teamkrope.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Modern desktop video player")
set(CPACK_DEBIAN_PACKAGE_SECTION "video")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
# Keep runtime dependencies explicit: dpkg-shlibdeps records the exact package
# names from the build runner, while Ubuntu 24.04 and newer releases ship the
# same Qt 6 library ABI under different GUI/OpenGL package names. QML imports
# are also loaded at runtime and are invisible to dpkg-shlibdeps.
set(LINUXPLAYER_SVG_DEPENDENCY "qt6-svg-plugins | libqt6svg6")
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "libc6, libstdc++6, libmpv2, libqt6core6t64, libqt6gui6t64 | libqt6gui6, libqt6opengl6t64 | libqt6opengl6, libqt6qml6, libqt6quick6, xdg-utils, qml6-module-qtqml, qml6-module-qtqml-workerscript, qml6-module-qtquick, qml6-module-qtquick-window, qml6-module-qtquick-controls, qml6-module-qtquick-templates, qml6-module-qtquick-dialogs, qml6-module-qtquick-layouts, ${LINUXPLAYER_SVG_DEPENDENCY}")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS OFF)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
include(CPack)
