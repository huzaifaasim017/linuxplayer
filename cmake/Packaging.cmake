# Included by the top-level CMakeLists.txt after project() and install() rules.
# The package contains the same install tree as `cmake --install`.
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "linuxplayer")
set(CPACK_PACKAGE_VENDOR "LinuxPlayer contributors")
set(CPACK_PACKAGE_CONTACT "Huzaifa Asim <mohammadhuzaifa117@gmail.com>")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Modern desktop video player")
set(CPACK_DEBIAN_PACKAGE_SECTION "video")
set(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
# dpkg-shlibdeps finds linked libraries, but QML imports are loaded at runtime.
# Ubuntu 24.04 ships the SVG image plugin in libqt6svg6; 26.04 splits it out.
if(LINUXPLAYER_UBUNTU_VERSION STREQUAL "24.04")
    set(LINUXPLAYER_SVG_DEPENDENCY "libqt6svg6")
elseif(LINUXPLAYER_UBUNTU_VERSION STREQUAL "26.04")
    set(LINUXPLAYER_SVG_DEPENDENCY "qt6-svg-plugins")
else()
    set(LINUXPLAYER_SVG_DEPENDENCY "qt6-svg-plugins | libqt6svg6")
endif()
set(CPACK_DEBIAN_PACKAGE_DEPENDS
    "libmpv2, qml6-module-qtquick, qml6-module-qtquick-window, qml6-module-qtquick-controls, qml6-module-qtquick-dialogs, qml6-module-qtquick-layouts, qml6-module-qtqml-workerscript, ${LINUXPLAYER_SVG_DEPENDENCY}")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")
include(CPack)
