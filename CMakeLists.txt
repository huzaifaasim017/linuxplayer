cmake_minimum_required(VERSION 3.22)
project(LinuxPlayer VERSION 0.2.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

include(GNUInstallDirs)
find_package(Qt6 6.4 REQUIRED COMPONENTS Quick QuickControls2)
find_path(MPV_INCLUDE_DIR NAMES mpv/client.h REQUIRED)
find_library(MPV_LIBRARY NAMES mpv REQUIRED)
add_library(MPV::mpv UNKNOWN IMPORTED)
set_target_properties(MPV::mpv PROPERTIES
    IMPORTED_LOCATION "${MPV_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${MPV_INCLUDE_DIR}")

file(GLOB QML_ICONS CONFIGURE_DEPENDS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/qml/icons/*.svg")
set(QML_RESOURCES qml/Main.qml qml/components/IconButton.qml ${QML_ICONS})

qt_add_executable(linuxplayer
    src/main.cpp
    src/MpvItem.cpp
    src/MpvItem.h
)
qt_add_resources(linuxplayer "qml_resources"
    PREFIX "/"
    FILES ${QML_RESOURCES}
)

target_link_libraries(linuxplayer PRIVATE Qt6::Quick Qt6::QuickControls2 MPV::mpv)
target_compile_options(linuxplayer PRIVATE -Wall -Wextra -Wpedantic)

include(CTest)
if(BUILD_TESTING)
    add_test(NAME qml_startup COMMAND linuxplayer --smoke-test)
    set_tests_properties(qml_startup PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()

install(TARGETS linuxplayer RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES assets/io.github.teamkrope.LinuxPlayer.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES assets/io.github.teamkrope.LinuxPlayer.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
install(FILES assets/io.github.teamkrope.LinuxPlayer.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
install(FILES LICENSE DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/linuxplayer RENAME copyright)
install(FILES README.md DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/linuxplayer)

include(cmake/Packaging.cmake)
