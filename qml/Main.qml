// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import LinuxPlayer 1.0
import "components"

ApplicationWindow {
    id: window
    width: 1100
    height: 680
    minimumWidth: 640
    minimumHeight: 420
    visible: true
    title: player.mediaTitle.length ? player.mediaTitle + " · LinuxPlayer" : "LinuxPlayer"
    color: "#090b10"

    readonly property bool hasMedia: player.sourceUrl.toString().length > 0
    property bool controlsShown: true
    property bool toolsHidden: false
    property bool showRevealHint: true
    property bool draggingSeek: false
    property real seekPreview: 0
    property real rememberedVolume: 70
    property bool showRemaining: false
    property bool busyVisible: false
    property string toastMessage: ""
    readonly property bool overlayVisible: hasMedia && controlsShown && !toolsHidden
    readonly property color ink: "#f7f9ff"
    readonly property color mutedInk: "#aeb8cb"
    readonly property color accent: "#91b7ff"
    readonly property bool compact: width < 780

    function timeText(seconds) {
        if (!isFinite(seconds) || seconds < 0) seconds = 0
        const rounded = Math.floor(seconds)
        const hours = Math.floor(rounded / 3600)
        const minutes = Math.floor((rounded % 3600) / 60)
        const secs = rounded % 60
        const padded = n => n < 10 ? "0" + n : "" + n
        return hours > 0 ? hours + ":" + padded(minutes) + ":" + padded(secs)
                         : minutes + ":" + padded(secs)
    }

    function revealControls() {
        if (toolsHidden) return
        controlsShown = true
        if (hasMedia && !player.paused && !player.ended) hideTimer.restart()
    }

    function toggleTools() {
        toolsHidden = !toolsHidden
        controlsShown = !toolsHidden
        if (toolsHidden) {
            hideTimer.stop()
            showRevealHint = true
            hideRevealTimer.restart()
            trackPopup.close()
            speedPopup.close()
            settingsPopup.close()
            helpPopup.close()
            showToast("Controls hidden · move pointer or press H")
        } else revealControls()
    }

    function toggleMute() {
        if (player.volume > 0) {
            rememberedVolume = player.volume
            player.volume = 0
        } else player.volume = Math.max(1, rememberedVolume)
        revealControls()
    }

    function changeSpeed(amount) {
        player.speed = Math.max(0.25, Math.min(3, Math.round((player.speed + amount) * 100) / 100))
        showToast("Speed " + player.speed.toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "×")
        revealControls()
    }

    function showToast(message) {
        toastMessage = message
        toastTimer.restart()
    }

    function toggleFullscreen() {
        if (visibility === Window.FullScreen) showNormal()
        else showFullScreen()
        revealControls()
    }

    function adjustVolume(amount) {
        player.volume = Math.max(0, Math.min(100, player.volume + amount))
        showToast("Volume " + Math.round(player.volume) + "%")
        revealControls()
    }

    function jump(amount) {
        if (!hasMedia || player.duration <= 0) return
        player.seek(Math.max(0, Math.min(player.duration, player.position + amount)))
        showToast((amount > 0 ? "+" : "") + amount + " seconds")
        revealControls()
    }

    Timer {
        id: hideTimer
        interval: 2700
        onTriggered: {
            if (window.hasMedia && !player.paused && !player.ended && !seekSlider.pressed
                    && !dockHover.hovered && !headerHover.hovered
                    && !trackPopup.opened && !speedPopup.opened
                    && !settingsPopup.opened && !helpPopup.opened) {
                window.controlsShown = false
                window.showRevealHint = false
            }
        }
    }

    Timer {
        id: toastTimer
        interval: 1700
        onTriggered: toastMessage = ""
    }

    Timer {
        id: hideRevealTimer
        interval: 2200
        onTriggered: window.showRevealHint = false
    }

    Timer {
        id: busyDelay
        interval: 280
        running: player.loading || player.buffering
        onRunningChanged: { if (!running) window.busyVisible = false }
        onTriggered: window.busyVisible = true
    }

    Timer {
        id: singleClickTimer
        interval: 230
        onTriggered: {
            if (window.hasMedia) {
                player.togglePause()
                window.revealControls()
            }
        }
    }

    FileDialog {
        id: videoDialog
        title: "Open a video"
        nameFilters: ["Video files (*.mp4 *.mkv *.webm *.mov *.avi *.m4v *.mpg *.mpeg *.flv *.wmv *.ogv *.ts)", "All files (*)"]
        onAccepted: {
            player.openFile(selectedFile)
            window.revealControls()
        }
    }

    FileDialog {
        id: subtitleDialog
        title: "Load a subtitle file"
        nameFilters: ["Subtitle files (*.srt *.ass *.ssa *.vtt *.sub)", "All files (*)"]
        onAccepted: player.loadSubtitle(selectedFile)
    }

    FileDialog {
        id: screenshotDialog
        title: "Save video frame"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        nameFilters: ["PNG image (*.png)"]
        onAccepted: {
            player.saveScreenshot(selectedFile)
            window.showToast("Screenshot saved")
        }
    }

    Popup {
        id: resumePopup
        property real resumeSeconds: 0
        x: Math.max(16, (window.width - width) / 2)
        y: Math.max(16, (window.height - height) / 2)
        width: Math.min(360, window.width - 32)
        padding: 24
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            radius: 24
            color: "#f0151c2b"
            border.color: "#6888b1"
        }
        contentItem: ColumnLayout {
            spacing: 15
            Text {
                text: "Continue watching?"
                color: window.ink
                font.pixelSize: 21
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Text {
                text: "Resume from " + window.timeText(resumePopup.resumeSeconds) + " or start from the beginning."
                color: window.mutedInk
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                Button {
                    id: startOverButton
                    text: "Start over"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        player.seek(0)
                        player.paused = false
                        resumePopup.close()
                    }
                    background: Rectangle { radius: 12; color: startOverButton.hovered ? "#35435b" : "#263348" }
                    contentItem: Text { text: startOverButton.text; color: window.ink; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    id: resumeButton
                    text: "Resume"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    onClicked: {
                        player.seek(resumePopup.resumeSeconds)
                        player.paused = false
                        resumePopup.close()
                    }
                    background: Rectangle { radius: 12; color: resumeButton.hovered ? "#9ebeff" : "#8eb4ff" }
                    contentItem: Text { text: resumeButton.text; color: "#101c31"; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Popup {
        id: helpPopup
        x: Math.max(16, window.width - width - 24)
        y: 68
        width: 292
        padding: 18
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 20; color: "#ef111824"; border.color: "#5bffffff" }
        contentItem: Column {
            spacing: 8
            Text { text: "Keyboard shortcuts"; color: window.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
            Text { text: "Ctrl+O   Open video"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "Space / K   Play or pause"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "← / →   Skip 5 seconds"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "J / L   Skip 10 seconds"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "↑ / ↓   Change volume"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "M   Mute  ·  F   Fullscreen"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "H   Show or hide controls"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "S   Save frame  ·  R   Loop video"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "[ / ]   Change speed"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "Esc   Leave fullscreen"; color: window.mutedInk; font.pixelSize: 13 }
        }
    }

    Shortcut { sequences: [StandardKey.Open]; onActivated: videoDialog.open() }
    Shortcut { sequence: "Space"; enabled: window.hasMedia; onActivated: { player.togglePause(); window.revealControls() } }
    Shortcut { sequence: "K"; enabled: window.hasMedia; onActivated: { player.togglePause(); window.revealControls() } }
    Shortcut { sequence: "Left"; onActivated: window.jump(-5) }
    Shortcut { sequence: "Right"; onActivated: window.jump(5) }
    Shortcut { sequence: "J"; onActivated: window.jump(-10) }
    Shortcut { sequence: "L"; onActivated: window.jump(10) }
    Shortcut { sequence: "Up"; onActivated: window.adjustVolume(5) }
    Shortcut { sequence: "Down"; onActivated: window.adjustVolume(-5) }
    Shortcut { sequence: "F"; onActivated: window.toggleFullscreen() }
    Shortcut { sequence: "Escape"; enabled: window.visibility === Window.FullScreen; onActivated: window.showNormal() }
    Shortcut { sequence: "M"; onActivated: window.toggleMute() }
    Shortcut { sequence: "H"; enabled: window.hasMedia; onActivated: window.toggleTools() }
    Shortcut { sequence: "S"; enabled: window.hasMedia; onActivated: screenshotDialog.open() }
    Shortcut { sequence: "R"; enabled: window.hasMedia; onActivated: { player.looping = !player.looping; window.showToast(player.looping ? "Loop on" : "Loop off") } }
    Shortcut { sequence: "["; enabled: window.hasMedia; onActivated: window.changeSpeed(-0.25) }
    Shortcut { sequence: "]"; enabled: window.hasMedia; onActivated: window.changeSpeed(0.25) }
    Shortcut { sequence: "Home"; enabled: window.hasMedia; onActivated: player.seek(0) }
    Shortcut { sequence: "End"; enabled: window.hasMedia && player.duration > 0; onActivated: player.seek(Math.max(0, player.duration - 1)) }

    MpvItem {
        id: player
        objectName: "player"
        anchors.fill: parent
        onErrorOccurred: message => window.showToast(message)
        onResumeSuggested: seconds => {
            resumePopup.resumeSeconds = seconds
            resumePopup.open()
            window.revealControls()
        }
        onPausedChanged: window.revealControls()
        onEndedChanged: {
            if (player.ended) {
                hideTimer.stop()
                window.revealControls()
            }
        }
    }

    // Interaction remains above the video texture; controls are layered above this area.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPositionChanged: {
            if (window.toolsHidden) {
                window.showRevealHint = true
                hideRevealTimer.restart()
            } else window.revealControls()
        }
        onClicked: singleClickTimer.restart()
        onDoubleClicked: {
            singleClickTimer.stop()
            window.toggleFullscreen()
        }
    }

    DropArea {
        id: fileDrop
        anchors.fill: parent
        onEntered: drag => {
            if (!drag.hasUrls) drag.accepted = false
            else window.revealControls()
        }
        onDropped: drop => {
            if (drop.hasUrls && drop.urls.length > 0) {
                player.openFile(drop.urls[0])
                drop.acceptProposedAction()
                window.revealControls()
            }
        }
    }

    Rectangle {
        id: busyOverlay
        anchors.centerIn: parent
        width: 64
        height: 64
        radius: 20
        color: "#db111824"
        border.color: "#57ffffff"
        visible: window.hasMedia && !player.ended && window.busyVisible
        Accessible.name: "Loading video"
        Image {
            anchors.centerIn: parent
            width: 30
            height: 30
            source: "icons/loading.svg"
            sourceSize.width: Math.ceil(30 * Screen.devicePixelRatio)
            sourceSize.height: Math.ceil(30 * Screen.devicePixelRatio)
            smooth: true
            RotationAnimator on rotation {
                from: 0
                to: 360
                duration: 950
                loops: Animation.Infinite
                running: busyOverlay.visible
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: fileDrop.containsDrag
        color: "#b5090d15"
        border.color: window.accent
        border.width: 3
        z: 10
        Column {
            anchors.centerIn: parent
            spacing: 12
            Image { source: "icons/open.svg"; width: 52; height: 52; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: "Drop a video to play"; color: window.ink; font.pixelSize: 24; font.weight: Font.DemiBold }
        }
    }

    Item {
        id: emptyState
        anchors.fill: parent
        visible: !window.hasMedia

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: "#101722" }
                GradientStop { position: 1; color: "#070a10" }
            }
        }
        Rectangle {
            width: Math.min(parent.width * 0.5, 520)
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            color: "#19335c"
            opacity: 0.23
        }
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 440)
            spacing: 0
            Rectangle {
                Layout.preferredWidth: 66
                Layout.preferredHeight: 66
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 24
                radius: 22
                color: "#759bef"
                border.color: "#a4c0ff"
                Image {
                    anchors.centerIn: parent
                    source: "icons/play.svg"
                    sourceSize.width: Math.ceil(27 * Screen.devicePixelRatio)
                    sourceSize.height: Math.ceil(27 * Screen.devicePixelRatio)
                    width: 27; height: 27
                }
            }
            Text {
                text: "LinuxPlayer"
                color: window.ink
                font.pixelSize: 29
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.bottomMargin: 28
            }
            Button {
                id: openVideoButton
                text: "Open video"
                hoverEnabled: true
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter
                onClicked: videoDialog.open()
                background: Rectangle {
                    radius: 14
                    color: openVideoButton.down ? "#acc8ff" : openVideoButton.hovered ? "#9ebeff" : "#8eb4ff"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                contentItem: Text {
                    text: openVideoButton.text
                    color: "#101c31"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Text {
                text: "or drop a file here"
                color: window.mutedInk
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 14
            }
        }
    }

    // The video stays edge to edge. Floating panels are the only playback chrome.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 156
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#b900050c" }
            GradientStop { position: 1; color: "#0000050c" }
        }
        Behavior on opacity { NumberAnimation { duration: 210 } }
    }

    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.leftMargin: window.compact ? 16 : 28
        anchors.rightMargin: window.compact ? 16 : 28
        height: 54
        radius: 18
        color: "#b30d1320"
        border.color: "#3bffffff"
        border.width: 1
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        enabled: window.overlayVisible
        Behavior on opacity { NumberAnimation { duration: 210 } }
        HoverHandler {
            id: headerHover
            onHoveredChanged: {
                if (hovered) window.revealControls()
                else if (window.hasMedia && !player.paused) hideTimer.restart()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 10
            spacing: 10
            Text {
                text: player.mediaTitle.length ? player.mediaTitle : "Untitled video"
                color: window.ink
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            IconButton {
                iconName: "open"
                Accessible.name: "Open another video"
                ToolTip.visible: hovered
                ToolTip.text: "Open video (Ctrl+O)"
                onClicked: videoDialog.open()
            }
            IconButton {
                iconName: "eye-off"
                Accessible.name: "Hide controls"
                ToolTip.visible: hovered
                ToolTip.text: "Hide all controls (H)"
                onClicked: window.toggleTools()
            }
        }
    }

    Button {
        id: revealButton
        visible: window.hasMedia && !window.overlayVisible && window.showRevealHint
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 22
        width: 156
        height: 44
        hoverEnabled: true
        text: "Show controls"
        Accessible.name: "Show controls"
        onClicked: window.toolsHidden ? window.toggleTools() : window.revealControls()
        background: Rectangle {
            radius: 16
            color: revealButton.hovered ? "#d5334564" : "#ba121b2b"
            border.color: "#66a6c5ff"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        contentItem: RowLayout {
            spacing: 8
            Image {
                source: "icons/eye.svg"
                sourceSize.width: Math.ceil(18 * Screen.devicePixelRatio)
                sourceSize.height: Math.ceil(18 * Screen.devicePixelRatio)
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                fillMode: Image.PreserveAspectFit
            }
            Text {
                text: revealButton.text
                color: window.ink
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 220
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#0000050c" }
            GradientStop { position: 1; color: "#ca00050c" }
        }
        Behavior on opacity { NumberAnimation { duration: 210 } }
    }

    Rectangle {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: window.compact ? 15 : 28
        anchors.rightMargin: window.compact ? 15 : 28
        anchors.bottomMargin: window.compact ? 16 : 24
        height: 116
        radius: 24
        color: "#df111824"
        border.color: "#55ffffff"
        border.width: 1
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        enabled: window.overlayVisible
        Behavior on opacity { NumberAnimation { duration: 210 } }
        HoverHandler {
            id: dockHover
            onHoveredChanged: {
                if (hovered) window.revealControls()
                else if (window.hasMedia && !player.paused) hideTimer.restart()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: window.compact ? 13 : 18
            anchors.rightMargin: window.compact ? 13 : 18
            anchors.topMargin: 11
            anchors.bottomMargin: 10
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 11
                Text {
                    text: window.timeText(window.draggingSeek ? window.seekPreview : player.position)
                    color: window.ink
                    font.pixelSize: 12
                    font.family: "monospace"
                    Layout.preferredWidth: 52
                    horizontalAlignment: Text.AlignRight
                }
                Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    from: 0
                    to: Math.max(1, player.duration)
                    value: window.draggingSeek ? window.seekPreview : player.position
                    enabled: player.duration > 0
                    hoverEnabled: true
                    onPressedChanged: {
                        if (pressed) {
                            window.seekPreview = value
                            window.draggingSeek = true
                        } else if (window.draggingSeek) {
                            const destination = window.seekPreview
                            window.draggingSeek = false
                            player.seek(destination)
                            window.revealControls()
                        }
                    }
                    onMoved: {
                        window.seekPreview = value
                        window.revealControls()
                    }
                    background: Rectangle {
                        x: seekSlider.leftPadding
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        width: seekSlider.availableWidth
                        height: seekSlider.hovered || seekSlider.pressed ? 6 : 4
                        radius: height / 2
                        color: "#65ffffff"
                        Behavior on height { NumberAnimation { duration: 140 } }
                        Rectangle {
                            width: parent.width * seekSlider.visualPosition
                            height: parent.height
                            radius: parent.radius
                            color: window.accent
                        }
                    }
                    handle: Rectangle {
                        x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        width: seekSlider.hovered || seekSlider.pressed ? 15 : 11
                        height: width
                        radius: width / 2
                        color: "#f8fbff"
                        border.color: "#89b5ff"
                        border.width: 1
                        Behavior on width { NumberAnimation { duration: 140 } }
                    }
                    ToolTip.visible: hovered || pressed
                    ToolTip.text: window.timeText(value)
                }
                Button {
                    id: durationButton
                    text: window.showRemaining
                          ? "−" + window.timeText(Math.max(0, player.duration - player.position))
                          : window.timeText(player.duration)
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 28
                    hoverEnabled: true
                    Accessible.name: "Toggle remaining time"
                    ToolTip.visible: hovered
                    ToolTip.text: "Click to toggle remaining time"
                    onClicked: window.showRemaining = !window.showRemaining
                    background: Item {}
                    contentItem: Text {
                        text: durationButton.text
                        color: window.mutedInk
                        font.pixelSize: 12
                        font.family: "monospace"
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: window.compact ? 2 : 7
                IconButton {
                    iconName: player.paused || player.ended ? "play" : "pause"
                    iconSize: 22
                    prominent: true
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Accessible.name: player.paused || player.ended ? "Play" : "Pause"
                    ToolTip.visible: hovered
                    ToolTip.text: player.ended ? "Replay (Space)" : player.paused ? "Play (Space)" : "Pause (Space)"
                    onClicked: { player.togglePause(); window.revealControls() }
                }
                IconButton {
                    iconName: "rewind"
                    Accessible.name: "Back 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Back 10 seconds (J)"
                    onClicked: window.jump(-10)
                }
                IconButton {
                    iconName: "forward"
                    Accessible.name: "Forward 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Forward 10 seconds (L)"
                    onClicked: window.jump(10)
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    iconName: player.volume <= 0 ? "mute" : "volume"
                    Accessible.name: player.volume <= 0 ? "Unmute" : "Mute"
                    ToolTip.visible: hovered
                    ToolTip.text: player.volume <= 0 ? "Unmute (M)" : "Mute (M)"
                    onClicked: window.toggleMute()
                }
                Slider {
                    id: volumeSlider
                    visible: window.width > 900
                    Layout.preferredWidth: 94
                    Layout.preferredHeight: 32
                    from: 0
                    to: 100
                    value: player.volume
                    hoverEnabled: true
                    Accessible.name: "Volume"
                    onMoved: { player.volume = value; window.revealControls() }
                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: "#65ffffff"
                        Rectangle { width: parent.width * volumeSlider.visualPosition; height: parent.height; radius: 2; color: window.ink }
                    }
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: 12; height: 12; radius: 6; color: window.ink
                    }
                }
                Button {
                    id: speedButton
                    text: player.speed === 1 ? "1×" : player.speed.toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "×"
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 42
                    hoverEnabled: true
                    Accessible.name: "Playback speed"
                    ToolTip.visible: hovered
                    ToolTip.text: "Playback speed"
                    onClicked: { trackPopup.close(); settingsPopup.close(); speedPopup.open(); window.revealControls() }
                    background: Rectangle { radius: 12; color: speedButton.hovered ? "#28ffffff" : "transparent" }
                    contentItem: Text {
                        text: speedButton.text
                        color: window.ink
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                IconButton {
                    iconName: "captions"
                    selected: player.subtitleTrackId > 0
                    Accessible.name: "Audio and subtitles"
                    ToolTip.visible: hovered
                    ToolTip.text: "Audio and subtitles"
                    onClicked: { speedPopup.close(); settingsPopup.close(); trackPopup.open(); window.revealControls() }
                }
                IconButton {
                    iconName: "settings"
                    Accessible.name: "More playback options"
                    ToolTip.visible: hovered
                    ToolTip.text: "More options"
                    onClicked: { speedPopup.close(); trackPopup.close(); settingsPopup.open(); window.revealControls() }
                }
                IconButton {
                    iconName: window.visibility === Window.FullScreen ? "minimize" : "fullscreen"
                    Accessible.name: window.visibility === Window.FullScreen ? "Leave fullscreen" : "Fullscreen"
                    ToolTip.visible: hovered
                    ToolTip.text: "Fullscreen (F)"
                    onClicked: window.toggleFullscreen()
                }
            }
        }
    }

    Popup {
        id: trackPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, controls.y - height - 12)
        width: 278
        height: Math.min(385, Math.max(160, controls.y - headerBar.y - headerBar.height - 24), Math.max(160, trackColumn.implicitHeight + 28))
        padding: 14
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.revealControls()
        onClosed: window.revealControls()
        background: Rectangle { radius: 20; color: "#ef111824"; border.color: "#5bffffff"; border.width: 1 }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: trackColumn.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            Column {
                id: trackColumn
                width: parent.width
                spacing: 3
                Text { text: "AUDIO"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 8; bottomPadding: 5 }
                Repeater {
                    model: player.audioTracks
                    delegate: Button {
                        required property var modelData
                        required property int index
                        width: trackColumn.width; height: 36
                        text: (modelData.id === player.audioTrackId ? "✓  " : "     ") + (modelData.title || modelData.language || "Track " + (index + 1))
                        onClicked: { player.audioTrackId = modelData.id; trackPopup.close() }
                        background: Rectangle { radius: 10; color: parent.hovered ? "#334f76" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Text { text: "SUBTITLES"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 8; topPadding: 13; bottomPadding: 5 }
                Button {
                    width: trackColumn.width; height: 36
                    text: (player.subtitleTrackId <= 0 ? "✓  " : "     ") + "Off"
                    onClicked: { player.subtitleTrackId = 0; trackPopup.close() }
                    background: Rectangle { radius: 10; color: parent.hovered ? "#334f76" : "transparent" }
                    contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
                Repeater {
                    model: player.subtitleTracks
                    delegate: Button {
                        required property var modelData
                        required property int index
                        width: trackColumn.width; height: 36
                        text: (modelData.id === player.subtitleTrackId ? "✓  " : "     ") + (modelData.title || modelData.language || "Track " + (index + 1))
                        onClicked: { player.subtitleTrackId = modelData.id; trackPopup.close() }
                        background: Rectangle { radius: 10; color: parent.hovered ? "#334f76" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Button {
                    width: trackColumn.width; height: 38
                    text: "+  Load subtitle file…"
                    onClicked: { trackPopup.close(); subtitleDialog.open() }
                    background: Rectangle { radius: 10; color: parent.hovered ? "#334f76" : "transparent" }
                    contentItem: Text { text: parent.text; color: window.accent; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Popup {
        id: speedPopup
        x: Math.max(16, window.width - width - 76)
        y: Math.max(16, controls.y - height - 12)
        width: 155
        height: Math.min(375, Math.max(160, controls.y - headerBar.y - headerBar.height - 24))
        padding: 11
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.revealControls()
        onClosed: window.revealControls()
        background: Rectangle { radius: 20; color: "#ef111824"; border.color: "#5bffffff"; border.width: 1 }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: speedColumn.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            Column {
                id: speedColumn
                width: parent.width
                spacing: 2
                Text { text: "SPEED"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 9; bottomPadding: 5 }
                Repeater {
                    model: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3]
                    delegate: Button {
                        required property real modelData
                        width: speedColumn.width; height: 31
                        text: modelData === 1 ? "Normal" : modelData + "×"
                        onClicked: { player.speed = modelData; speedPopup.close(); window.revealControls() }
                        background: Rectangle { radius: 10; color: parent.hovered ? "#334f76" : "transparent" }
                        contentItem: Text { text: parent.text; color: player.speed === modelData ? window.accent : window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; leftPadding: 9 }
                    }
                }
            }
        }
    }

    Popup {
        id: settingsPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, controls.y - height - 12)
        width: 272
        height: Math.min(292, Math.max(160, controls.y - headerBar.y - headerBar.height - 24))
        padding: 13
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.revealControls()
        onClosed: window.revealControls()
        background: Rectangle { radius: 20; color: "#ef111824"; border.color: "#5bffffff"; border.width: 1 }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            Column {
                id: settingsColumn
                width: parent.width
                spacing: 4
                Text { text: "PLAYBACK OPTIONS"; color: window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.5; leftPadding: 9; bottomPadding: 5 }
                Button {
                    id: loopOption
                    width: settingsPopup.width - 26; height: 42
                    text: "Loop video"
                    hoverEnabled: true
                    onClicked: { player.looping = !player.looping; window.showToast(player.looping ? "Loop on" : "Loop off") }
                    background: Rectangle { radius: 11; color: loopOption.hovered ? "#334f76" : player.looping ? "#2d4364" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: "icons/repeat.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: loopOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: player.looping ? "ON" : "OFF"; color: player.looping ? window.accent : window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }
                Button {
                    id: fillOption
                    width: settingsPopup.width - 26; height: 42
                    text: "Fill video canvas"
                    hoverEnabled: true
                    onClicked: { player.videoFill = !player.videoFill; window.showToast(player.videoFill ? "Fill screen" : "Fit video") }
                    background: Rectangle { radius: 11; color: fillOption.hovered ? "#334f76" : player.videoFill ? "#2d4364" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: player.videoFill ? "icons/fill.svg" : "icons/fit.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: fillOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: player.videoFill ? "FILL" : "FIT"; color: player.videoFill ? window.accent : window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }
                Rectangle { width: settingsPopup.width - 28; height: 1; color: "#30ffffff" }
                Button {
                    id: screenshotOption
                    width: settingsPopup.width - 26; height: 40
                    text: "Save video frame…"
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); screenshotDialog.open() }
                    background: Rectangle { radius: 11; color: screenshotOption.hovered ? "#334f76" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: "icons/camera.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: screenshotOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                    }
                }
                Button {
                    id: subtitleOption
                    width: settingsPopup.width - 26; height: 40
                    text: "Load subtitle file…"
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); subtitleDialog.open() }
                    background: Rectangle { radius: 11; color: subtitleOption.hovered ? "#334f76" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: "icons/captions.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: subtitleOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                    }
                }
                Button {
                    id: shortcutsOption
                    width: settingsPopup.width - 26; height: 40
                    text: "Keyboard shortcuts"
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); helpPopup.open() }
                    background: Rectangle { radius: 11; color: shortcutsOption.hovered ? "#334f76" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: "icons/help.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: shortcutsOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    Rectangle {
        id: toast
        visible: window.toastMessage.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.overlayVisible ? 154 : 24
        width: toastText.implicitWidth + 34
        height: 39
        radius: 13
        color: "#ed192438"
        border.color: "#6686b5"
        z: 11
        Text { id: toastText; anchors.centerIn: parent; text: window.toastMessage; color: window.ink; font.pixelSize: 13 }
    }
}
