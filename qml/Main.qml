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
    minimumWidth: miniMode ? 320 : 640
    minimumHeight: miniMode ? 200 : 420
    visible: true
    title: player.mediaTitle.length ? player.mediaTitle + " · LinuxPlayer" : "LinuxPlayer"
    color: "#0d1721"

    readonly property bool hasMedia: player.sourceUrl.toString().length > 0
    property bool controlsShown: true
    property bool toolsHidden: false
    property bool showRevealHint: false
    property bool draggingSeek: false
    property real seekPreview: 0
    property real rememberedVolume: 70
    property int rememberedSubtitleId: 0
    property bool showRemaining: false
    property bool busyVisible: false
    property string playbackFeedbackIcon: "play"
    property int seekFeedbackSeconds: 5
    property bool seekFeedbackForward: true
    property int volumeFeedbackLevel: 0
    property string timelineFeedbackTime: "0:00"
    property string toastMessage: ""
    property bool miniMode: false
    property real canvasRatio: 0
    property string canvasLabel: "Original"
    property rect restoreGeometry: Qt.rect(0, 0, 1100, 680)
    property int restoreFlags: Qt.Window
    property bool restoreMaximized: false
    property bool restoreFullscreen: false
    readonly property bool overlayVisible: hasMedia && !miniMode && controlsShown && !toolsHidden
    readonly property bool miniOverlayVisible: hasMedia && miniMode && controlsShown && !toolsHidden
    readonly property color ink: "#edf5f5"
    readonly property color mutedInk: "#a6bbc2"
    readonly property color accent: themeAccent.enabled ? themeAccent.color : "#64d5c6"
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
            showRevealHint = false
            hideRevealTimer.stop()
            trackPopup.close()
            speedPopup.close()
            settingsPopup.close()
            helpPopup.close()
            ratioPopup.close()
        } else {
            showRevealHint = false
            revealControls()
        }
    }

    function toggleMiniPlayer() {
        if (!hasMedia) return
        trackPopup.close()
        speedPopup.close()
        settingsPopup.close()
        helpPopup.close()
        ratioPopup.close()
        if (miniMode) {
            miniMode = false
            flags = restoreFlags
            showNormal()
            x = restoreGeometry.x
            y = restoreGeometry.y
            width = restoreGeometry.width
            height = restoreGeometry.height
            if (restoreMaximized) showMaximized()
            if (restoreFullscreen) showFullScreen()
            if (!restoreMaximized && !restoreFullscreen) restoreSizeTimer.restart()
        } else {
            restoreSizeTimer.stop()
            restoreGeometry = Qt.rect(x, y, width, height)
            restoreFlags = flags
            restoreMaximized = visibility === Window.Maximized
            restoreFullscreen = visibility === Window.FullScreen
            if (restoreMaximized || restoreFullscreen) showNormal()
            miniMode = true
            toolsHidden = false
            flags = restoreFlags | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            width = 420
            height = 256
            showNormal()
            raise()
        }
        controlsShown = true
        revealControls()
    }

    function toggleMute() {
        if (player.volume > 0) {
            rememberedVolume = player.volume
            player.volume = 0
        } else player.volume = Math.max(1, rememberedVolume)
        showVolumeFeedback()
        revealControls()
    }

    function showVolumeFeedback() {
        volumeFeedbackLevel = Math.round(player.volume)
        volumeFeedbackAnimation.restart()
    }

    function changeSpeed(amount) {
        player.speed = Math.max(0.25, Math.min(3, Math.round((player.speed + amount) * 100) / 100))
        showToast("Speed " + player.speed.toFixed(2).replace(/0+$/, "").replace(/\.$/, "") + "×")
        revealControls()
    }

    function showToast(message) {
        toastMessage = message
        toastTimer.restart()
        toastAnimation.restart()
    }

    function selectCanvas(label, ratio) {
        canvasLabel = label
        canvasRatio = ratio
        ratioPopup.close()
        showToast(label + " preview")
        revealControls()
    }

    function makeDefaultPlayer() {
        showToast("Updating video defaults…")
        desktopIntegration.setAsDefaultVideoPlayer()
    }

    function togglePlayback() {
        if (!hasMedia) return
        const willPlay = player.paused || player.ended
        player.togglePause()
        playbackFeedbackIcon = willPlay ? "play" : "pause"
        playbackFeedbackAnimation.restart()
        if (willPlay) {
            hideTimer.stop()
            controlsShown = false
            showRevealHint = false
        } else revealControls()
    }

    Connections {
        target: desktopIntegration
        function onDefaultPlayerFinished(success, message) { window.showToast(message) }
    }

    function toggleFullscreen() {
        if (miniMode) toggleMiniPlayer()
        restoreSizeTimer.stop()
        const leavingFullscreen = visibility === Window.FullScreen
        if (leavingFullscreen) showNormal()
        else showFullScreen()
        playbackFeedbackIcon = leavingFullscreen ? "minimize" : "fullscreen"
        playbackFeedbackAnimation.restart()
        revealControls()
    }

    function adjustVolume(amount) {
        player.volume = Math.max(0, Math.min(100, player.volume + amount))
        showVolumeFeedback()
        revealControls()
    }

    function seekTo(position) {
        if (!hasMedia || player.duration <= 0) return
        const destination = Math.max(0, Math.min(player.duration, position))
        player.seek(destination)
        timelineFeedbackTime = timeText(destination)
        timelineFeedbackAnimation.restart()
        revealControls()
    }

    function jump(amount) {
        if (!hasMedia || player.duration <= 0) return
        player.seek(Math.max(0, Math.min(player.duration, player.position + amount)))
        seekFeedbackSeconds = Math.abs(amount)
        seekFeedbackForward = amount > 0
        if (seekFeedbackForward) forwardSeekFeedback.trigger()
        else backSeekFeedback.trigger()
        revealControls()
    }

    function jumpToFraction(fraction) {
        if (!hasMedia || player.duration <= 0) return
        seekTo(player.duration * fraction)
    }

    function toggleCaptions() {
        if (!hasMedia) return
        if (player.subtitleTrackId > 0) {
            rememberedSubtitleId = player.subtitleTrackId
            player.subtitleTrackId = 0
            showToast("Subtitles off")
        } else if (player.subtitleTracks.length > 0) {
            let nextId = player.subtitleTracks[0].id
            for (let i = 0; i < player.subtitleTracks.length; ++i) {
                if (player.subtitleTracks[i].id === rememberedSubtitleId) {
                    nextId = rememberedSubtitleId
                    break
                }
            }
            player.subtitleTrackId = nextId
            showToast("Subtitles on")
        } else showToast("No subtitle track")
        revealControls()
    }

    Timer {
        id: restoreSizeTimer
        interval: 120
        onTriggered: {
            if (!window.miniMode && !window.restoreMaximized && !window.restoreFullscreen
                    && window.visibility !== Window.FullScreen && window.visibility !== Window.Maximized) {
                window.width = window.restoreGeometry.width
                window.height = window.restoreGeometry.height
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 2700
        onTriggered: {
            if (window.hasMedia && !player.paused && !player.ended && !seekSlider.pressed
                    && !dockHover.hovered && !headerHover.hovered && !miniHover.hovered
                    && !trackPopup.opened && !speedPopup.opened
                    && !settingsPopup.opened && !helpPopup.opened && !ratioPopup.opened) {
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
                window.togglePlayback()
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
            color: "#f0152833"
            border.color: "#4a877f"
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
                    background: Rectangle { radius: 12; color: startOverButton.hovered ? "#2b4b57" : "#213b49" }
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
                    background: Rectangle { radius: 12; color: resumeButton.hovered ? Qt.lighter(window.accent, 1.16) : window.accent }
                    contentItem: Text { text: resumeButton.text; color: "#10201b"; font.pixelSize: 13; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Popup {
        id: helpPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, controls.y - height - 12)
        width: 292
        height: Math.min(430, Math.max(160, controls.y - headerBar.y - headerBar.height - 24))
        padding: 18
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 20; color: "#ef152331"; border.color: "#5bffffff" }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: helpColumn.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            Column {
                id: helpColumn
                width: parent.width
                spacing: 8
                Text { text: "Keyboard shortcuts"; color: window.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text { text: "Ctrl+O   Open video"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "Space / K   Play or pause"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "← / →   Skip 5 seconds"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "J / L   Skip 10 seconds"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "↑ / ↓   Change volume"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "M   Mute  ·  F   Fullscreen"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "C   Toggle subtitles"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "H   Show or hide controls"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "I   Mini player"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "0–9   Jump through video"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "S   Save frame  ·  R   Loop video"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "[ / ]   Change speed"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "F1   Keyboard shortcuts"; color: window.mutedInk; font.pixelSize: 13 }
                Text { text: "Esc   Leave fullscreen"; color: window.mutedInk; font.pixelSize: 13 }
            }
        }
    }

    Shortcut { sequences: [StandardKey.Open]; onActivated: videoDialog.open() }
    Shortcut { sequence: "F1"; onActivated: helpPopup.open() }
    Shortcut { sequence: "Space"; enabled: window.hasMedia; onActivated: window.togglePlayback() }
    Shortcut { sequence: "K"; enabled: window.hasMedia; onActivated: window.togglePlayback() }
    Shortcut { sequence: "Left"; onActivated: window.jump(-5) }
    Shortcut { sequence: "Right"; onActivated: window.jump(5) }
    Shortcut { sequence: "J"; onActivated: window.jump(-10) }
    Shortcut { sequence: "L"; onActivated: window.jump(10) }
    Shortcut { sequence: "Up"; onActivated: window.adjustVolume(5) }
    Shortcut { sequence: "Down"; onActivated: window.adjustVolume(-5) }
    Shortcut { sequence: "F"; onActivated: window.toggleFullscreen() }
    Shortcut { sequence: "Escape"; enabled: window.visibility === Window.FullScreen; onActivated: window.toggleFullscreen() }
    Shortcut { sequence: "M"; onActivated: window.toggleMute() }
    Shortcut { sequence: "C"; enabled: window.hasMedia; onActivated: window.toggleCaptions() }
    Shortcut { sequence: "H"; enabled: window.hasMedia; onActivated: window.toggleTools() }
    Shortcut { sequence: "I"; enabled: window.hasMedia; onActivated: window.toggleMiniPlayer() }
    Shortcut { sequence: "Escape"; enabled: window.miniMode; onActivated: window.toggleMiniPlayer() }
    Shortcut { sequence: "S"; enabled: window.hasMedia; onActivated: screenshotDialog.open() }
    Shortcut { sequence: "R"; enabled: window.hasMedia; onActivated: { player.looping = !player.looping; window.showToast(player.looping ? "Loop on" : "Loop off") } }
    Shortcut { sequence: "["; enabled: window.hasMedia; onActivated: window.changeSpeed(-0.25) }
    Shortcut { sequence: "]"; enabled: window.hasMedia; onActivated: window.changeSpeed(0.25) }
    Shortcut { sequence: "Home"; enabled: window.hasMedia; onActivated: window.seekTo(0) }
    Shortcut { sequence: "End"; enabled: window.hasMedia && player.duration > 0; onActivated: window.seekTo(Math.max(0, player.duration - 1)) }
    Shortcut { sequence: "0"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0) }
    Shortcut { sequence: "1"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.1) }
    Shortcut { sequence: "2"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.2) }
    Shortcut { sequence: "3"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.3) }
    Shortcut { sequence: "4"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.4) }
    Shortcut { sequence: "5"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.5) }
    Shortcut { sequence: "6"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.6) }
    Shortcut { sequence: "7"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.7) }
    Shortcut { sequence: "8"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.8) }
    Shortcut { sequence: "9"; enabled: window.hasMedia; onActivated: window.jumpToFraction(0.9) }

    Item {
        id: previewCanvas
        anchors.centerIn: parent
        width: window.canvasRatio <= 0 ? window.width : Math.min(window.width, window.height * window.canvasRatio)
        height: window.canvasRatio <= 0 ? window.height : Math.min(window.height, window.width / window.canvasRatio)
        clip: true
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
        onPausedChanged: {
            if (player.paused && !player.ended) window.revealControls()
        }
        onLoadingChanged: {
            if (!player.loading && window.hasMedia && !player.paused && !player.ended) {
                window.controlsShown = false
                window.showRevealHint = false
            }
        }
        onEndedChanged: {
            if (player.ended) {
                hideTimer.stop()
                window.revealControls()
            }
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
        color: "#db152331"
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

    Item {
        id: playbackFeedback
        anchors.centerIn: parent
        width: 92
        height: 92
        opacity: 0
        scale: 0.72
        visible: opacity > 0
        z: 9
        Rectangle {
            anchors.centerIn: parent
            width: 92; height: 92; radius: 46
            color: "#2364d5c6"
        }
        Rectangle {
            anchors.centerIn: parent
            width: 74; height: 74; radius: 37
            color: "#ed152b36"
            border.color: Qt.rgba(window.accent.r, window.accent.g, window.accent.b, 0.54)
            border.width: 1
        }
        Image {
            anchors.centerIn: parent
            width: 34; height: 34
            source: "icons/" + window.playbackFeedbackIcon + ".svg"
            sourceSize: Qt.size(Math.ceil(34 * Screen.devicePixelRatio), Math.ceil(34 * Screen.devicePixelRatio))
            fillMode: Image.PreserveAspectFit
        }
        SequentialAnimation {
            id: playbackFeedbackAnimation
            PropertyAction { target: playbackFeedback; property: "opacity"; value: 0 }
            PropertyAction { target: playbackFeedback; property: "scale"; value: 0.72 }
            ParallelAnimation {
                NumberAnimation { target: playbackFeedback; property: "opacity"; from: 0; to: 1; duration: 110 }
                NumberAnimation { target: playbackFeedback; property: "scale"; from: 0.72; to: 1.04; duration: 210; easing.type: Easing.OutBack }
            }
            PauseAnimation { duration: 85 }
            ParallelAnimation {
                NumberAnimation { target: playbackFeedback; property: "opacity"; from: 1; to: 0; duration: 230; easing.type: Easing.InQuad }
                NumberAnimation { target: playbackFeedback; property: "scale"; from: 1.04; to: 1.18; duration: 230; easing.type: Easing.OutQuad }
            }
        }
    }

    component SeekFeedback: Item {
        id: feedback
        property bool forward: false
        property int seconds: 5
        function trigger() { motion.restart() }
        width: 100
        height: 100
        opacity: 0
        scale: 0.78
        visible: opacity > 0
        z: 9

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#ca152b36"
            border.color: Qt.rgba(window.accent.r, window.accent.g, window.accent.b, 0.6)
            border.width: 1
        }
        Column {
            anchors.centerIn: parent
            spacing: 1
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 30; height: 30
                source: "icons/" + (feedback.forward ? "forward" : "rewind") + ".svg"
                sourceSize: Qt.size(Math.ceil(30 * Screen.devicePixelRatio), Math.ceil(30 * Screen.devicePixelRatio))
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: feedback.seconds + "s"
                color: window.ink
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }
        }
        SequentialAnimation {
            id: motion
            PropertyAction { target: feedback; property: "opacity"; value: 0 }
            PropertyAction { target: feedback; property: "scale"; value: 0.78 }
            ParallelAnimation {
                NumberAnimation { target: feedback; property: "opacity"; from: 0; to: 1; duration: 100 }
                NumberAnimation { target: feedback; property: "scale"; from: 0.78; to: 1.06; duration: 230; easing.type: Easing.OutBack }
            }
            PauseAnimation { duration: 170 }
            ParallelAnimation {
                NumberAnimation { target: feedback; property: "opacity"; from: 1; to: 0; duration: 220 }
                NumberAnimation { target: feedback; property: "scale"; from: 1.06; to: 1.2; duration: 220 }
            }
        }
    }

    SeekFeedback {
        id: backSeekFeedback
        forward: false
        seconds: window.seekFeedbackSeconds
        x: Math.max(24, window.width * 0.22 - width / 2)
        y: (window.height - height) / 2
    }

    SeekFeedback {
        id: forwardSeekFeedback
        forward: true
        seconds: window.seekFeedbackSeconds
        x: Math.min(window.width - width - 24, window.width * 0.78 - width / 2)
        y: (window.height - height) / 2
    }

    Item {
        id: volumeFeedback
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: window.miniMode ? 18 : 76
        width: 180
        height: 64
        opacity: 0
        scale: 0.9
        visible: opacity > 0
        z: 9
        Rectangle {
            anchors.fill: parent
            radius: 19
            color: "#ed152b36"
            border.color: Qt.rgba(window.accent.r, window.accent.g, window.accent.b, 0.44)
        }
        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 12
            anchors.leftMargin: 17
            spacing: 9
            Image {
                width: 20; height: 20
                source: "icons/" + (window.volumeFeedbackLevel === 0 ? "mute" : "volume") + ".svg"
                sourceSize: Qt.size(Math.ceil(20 * Screen.devicePixelRatio), Math.ceil(20 * Screen.devicePixelRatio))
            }
            Text {
                text: window.volumeFeedbackLevel + "%"
                color: window.ink
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 17
            anchors.bottomMargin: 14
            height: 4
            radius: 2
            color: "#64789198"
            Rectangle {
                width: parent.width * window.volumeFeedbackLevel / 100
                height: parent.height
                radius: parent.radius
                color: window.accent
                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }
        SequentialAnimation {
            id: volumeFeedbackAnimation
            PropertyAction { target: volumeFeedback; property: "opacity"; value: 0 }
            PropertyAction { target: volumeFeedback; property: "scale"; value: 0.9 }
            ParallelAnimation {
                NumberAnimation { target: volumeFeedback; property: "opacity"; from: 0; to: 1; duration: 100 }
                NumberAnimation { target: volumeFeedback; property: "scale"; from: 0.9; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            PauseAnimation { duration: 460 }
            NumberAnimation { target: volumeFeedback; property: "opacity"; from: 1; to: 0; duration: 220 }
        }
    }

    Rectangle {
        id: timelineFeedback
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.miniMode ? 107 : 138
        width: timelineFeedbackLabel.implicitWidth + 36
        height: 38
        radius: 13
        color: "#ed152b36"
        border.color: Qt.rgba(window.accent.r, window.accent.g, window.accent.b, 0.45)
        opacity: 0
        scale: 0.88
        visible: opacity > 0
        z: 9
        Text {
            id: timelineFeedbackLabel
            anchors.centerIn: parent
            text: window.timelineFeedbackTime
            color: window.ink
            font.pixelSize: 14
            font.family: "monospace"
            font.weight: Font.DemiBold
        }
        SequentialAnimation {
            id: timelineFeedbackAnimation
            PropertyAction { target: timelineFeedback; property: "opacity"; value: 0 }
            PropertyAction { target: timelineFeedback; property: "scale"; value: 0.88 }
            ParallelAnimation {
                NumberAnimation { target: timelineFeedback; property: "opacity"; from: 0; to: 1; duration: 100 }
                NumberAnimation { target: timelineFeedback; property: "scale"; from: 0.88; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            PauseAnimation { duration: 360 }
            NumberAnimation { target: timelineFeedback; property: "opacity"; from: 1; to: 0; duration: 200 }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: fileDrop.containsDrag
        color: "#b50d1721"
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
                GradientStop { position: 0; color: "#152331" }
                GradientStop { position: 1; color: "#0d1721" }
            }
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
                color: "#e8f4f3"
                border.color: "#b8d8d7"
                Image {
                    anchors.centerIn: parent
                    source: "../assets/io.github.teamkrope.LinuxPlayer.png"
                    sourceSize.width: Math.ceil(56 * Screen.devicePixelRatio)
                    sourceSize.height: Math.ceil(56 * Screen.devicePixelRatio)
                    width: 56; height: 56
                    fillMode: Image.PreserveAspectFit
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
                    color: openVideoButton.down ? Qt.lighter(window.accent, 1.16) : openVideoButton.hovered ? Qt.lighter(window.accent, 1.08) : window.accent
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                contentItem: Text {
                    text: openVideoButton.text
                    color: "#10201b"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            Button {
                id: emptyDefaultButton
                text: "Make default video player"
                visible: desktopIntegration.defaultStatusReady && !desktopIntegration.defaultVideoPlayer
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                onClicked: window.makeDefaultPlayer()
                background: Rectangle { radius: 10; color: emptyDefaultButton.hovered ? "#1a2b39" : "transparent" }
                contentItem: Text { text: emptyDefaultButton.text; color: window.mutedInk; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
    }

    // The video stays edge to edge. Floating panels are the only playback chrome.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 130
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#b90d1721" }
            GradientStop { position: 1; color: "#000d1721" }
        }
        Behavior on opacity { NumberAnimation { duration: 210 } }
    }

    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.leftMargin: window.compact ? 16 : 22
        anchors.rightMargin: window.compact ? 16 : 22
        height: 46
        color: "transparent"
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
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            spacing: 10
            Text {
                text: player.mediaTitle.length ? player.mediaTitle : "Untitled video"
                color: window.ink
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
            IconButton {
                accentColor: window.accent
                iconName: "open"
                Accessible.name: "Open another video"
                ToolTip.visible: hovered
                ToolTip.text: "Open video (Ctrl+O)"
                onClicked: videoDialog.open()
            }
            IconButton {
                accentColor: window.accent
                iconName: "lock"
                Accessible.name: "Lock controls"
                ToolTip.visible: hovered
                ToolTip.text: "Lock controls (H)"
                onClicked: window.toggleTools()
            }
        }
    }

    IconButton {
        accentColor: window.accent
        id: revealButton
        visible: window.hasMedia && window.toolsHidden && window.showRevealHint && !window.miniMode
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 22
        width: 44
        height: 44
        iconName: "lock-open"
        Accessible.name: "Unlock controls"
        ToolTip.visible: hovered
        ToolTip.text: "Unlock controls (H)"
        onClicked: window.toggleTools()
        background: Rectangle { radius: 14; color: revealButton.hovered ? "#d9284852" : "#d0152833"; border.color: "#55ffffff" }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 180
        visible: window.hasMedia && opacity > 0.01
        opacity: window.overlayVisible ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#000d1721" }
            GradientStop { position: 1; color: "#ca0d1721" }
        }
        Behavior on opacity { NumberAnimation { duration: 210 } }
    }

    Rectangle {
        id: controls
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: window.compact ? 10 : 20
        anchors.rightMargin: window.compact ? 10 : 20
        anchors.bottomMargin: window.compact ? 10 : 16
        height: 100
        radius: 18
        color: "#d0152833"
        border.color: "#38ffffff"
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
            anchors.leftMargin: window.compact ? 10 : 14
            anchors.rightMargin: window.compact ? 10 : 14
            anchors.topMargin: 8
            anchors.bottomMargin: 6
            spacing: 2

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
                            window.seekTo(destination)
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
                        color: "#64819aa3"
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
                        color: "#edf5f5"
                        border.color: window.accent
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
                    accentColor: window.accent
                    iconName: player.paused || player.ended ? "play" : "pause"
                    iconSize: 22
                    prominent: true
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Accessible.name: player.paused || player.ended ? "Play" : "Pause"
                    ToolTip.visible: hovered
                    ToolTip.text: player.ended ? "Replay (Space)" : player.paused ? "Play (Space)" : "Pause (Space)"
                    onClicked: window.togglePlayback()
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "rewind"
                    Accessible.name: "Back 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Back 10 seconds (J)"
                    onClicked: window.jump(-10)
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "forward"
                    Accessible.name: "Forward 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Forward 10 seconds (L)"
                    onClicked: window.jump(10)
                }
                Item { Layout.fillWidth: true }
                IconButton {
                    accentColor: window.accent
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
                    onMoved: { player.volume = value; window.showVolumeFeedback(); window.revealControls() }
                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: "#64819aa3"
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
                    accentColor: window.accent
                    iconName: "captions"
                    selected: player.subtitleTrackId > 0
                    Accessible.name: "Audio and subtitles"
                    ToolTip.visible: hovered
                    ToolTip.text: "Audio and subtitles"
                    onClicked: { speedPopup.close(); settingsPopup.close(); trackPopup.open(); window.revealControls() }
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "settings"
                    Accessible.name: "More playback options"
                    ToolTip.visible: hovered
                    ToolTip.text: "More options"
                    onClicked: { speedPopup.close(); trackPopup.close(); settingsPopup.open(); window.revealControls() }
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "picture-in-picture"
                    Accessible.name: "Mini player"
                    ToolTip.visible: hovered
                    ToolTip.text: "Mini player (I)"
                    onClicked: window.toggleMiniPlayer()
                }
                IconButton {
                    accentColor: window.accent
                    iconName: window.visibility === Window.FullScreen ? "minimize" : "fullscreen"
                    Accessible.name: window.visibility === Window.FullScreen ? "Leave fullscreen" : "Fullscreen"
                    ToolTip.visible: hovered
                    ToolTip.text: "Fullscreen (F)"
                    onClicked: window.toggleFullscreen()
                }
            }
        }
    }

    // Compact picture-in-picture mode keeps the same playback item and timeline.
    Item {
        id: miniControls
        anchors.fill: parent
        visible: window.miniOverlayVisible
        HoverHandler {
            id: miniHover
            onHoveredChanged: if (hovered) window.revealControls()
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 62
            gradient: Gradient {
                GradientStop { position: 0; color: "#d5000000" }
                GradientStop { position: 1; color: "#00000000" }
            }
        }
        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: restoreMiniButton.left
            height: 48
            cursorShape: Qt.OpenHandCursor
            onPressed: windowOperations.startMove(window)
        }
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: restoreMiniButton.left
            anchors.topMargin: 15
            anchors.leftMargin: 16
            text: player.mediaTitle
            color: window.ink
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideMiddle
        }
        IconButton {
            accentColor: window.accent
            id: restoreMiniButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 5
            anchors.rightMargin: 6
            iconName: "restore"
            Accessible.name: "Restore player"
            ToolTip.visible: hovered
            ToolTip.text: "Restore player (I)"
            onClicked: window.toggleMiniPlayer()
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 94
            gradient: Gradient {
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 1; color: "#e8000000" }
            }
        }
        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            anchors.bottomMargin: 8
            spacing: 2
            Slider {
                id: miniSeek
                Layout.fillWidth: true
                Layout.preferredHeight: 20
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
                        window.seekTo(destination)
                    }
                }
                onMoved: { window.seekPreview = value; window.revealControls() }
                background: Rectangle {
                    x: miniSeek.leftPadding
                    y: miniSeek.topPadding + miniSeek.availableHeight / 2 - height / 2
                    width: miniSeek.availableWidth
                    height: miniSeek.hovered || miniSeek.pressed ? 5 : 3
                    radius: height / 2
                    color: "#77ffffff"
                    Rectangle { width: parent.width * miniSeek.visualPosition; height: parent.height; radius: parent.radius; color: window.accent }
                }
                handle: Rectangle {
                    x: miniSeek.leftPadding + miniSeek.visualPosition * (miniSeek.availableWidth - width)
                    y: miniSeek.topPadding + miniSeek.availableHeight / 2 - height / 2
                    width: miniSeek.hovered || miniSeek.pressed ? 12 : 7
                    height: width
                    radius: width / 2
                    color: window.ink
                }
                ToolTip.visible: hovered || pressed
                ToolTip.text: window.timeText(value)
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                IconButton {
                    accentColor: window.accent
                    iconName: player.paused || player.ended ? "play" : "pause"
                    Accessible.name: player.paused || player.ended ? "Play" : "Pause"
                    ToolTip.visible: hovered
                    ToolTip.text: player.ended ? "Replay" : player.paused ? "Play" : "Pause"
                    onClicked: window.togglePlayback()
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "rewind"
                    Accessible.name: "Back 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Back 10 seconds"
                    onClicked: window.jump(-10)
                }
                IconButton {
                    accentColor: window.accent
                    iconName: "forward"
                    Accessible.name: "Forward 10 seconds"
                    ToolTip.visible: hovered
                    ToolTip.text: "Forward 10 seconds"
                    onClicked: window.jump(10)
                }
                Item { Layout.fillWidth: true }
                Text { text: window.timeText(player.position) + " / " + window.timeText(player.duration); color: window.ink; font.pixelSize: 11; font.family: "monospace" }
            }
        }
    }

    Item {
        visible: window.miniMode
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 26
        height: 26
        Image {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 2
            anchors.bottomMargin: 2
            width: 15
            height: 15
            source: "icons/resize.svg"
            sourceSize: Qt.size(Math.ceil(15 * Screen.devicePixelRatio), Math.ceil(15 * Screen.devicePixelRatio))
            opacity: 0.72
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: windowOperations.startResize(window)
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
        background: Rectangle { radius: 20; color: "#ef152331"; border.color: "#5bffffff"; border.width: 1 }
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
                        background: Rectangle { radius: 10; color: parent.hovered ? "#28545a" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Text { text: "SUBTITLES"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 8; topPadding: 13; bottomPadding: 5 }
                Button {
                    width: trackColumn.width; height: 36
                    text: (player.subtitleTrackId <= 0 ? "✓  " : "     ") + "Off"
                    onClicked: { player.subtitleTrackId = 0; trackPopup.close() }
                    background: Rectangle { radius: 10; color: parent.hovered ? "#28545a" : "transparent" }
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
                        background: Rectangle { radius: 10; color: parent.hovered ? "#28545a" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Button {
                    width: trackColumn.width; height: 38
                    text: "+  Load subtitle file…"
                    onClicked: { trackPopup.close(); subtitleDialog.open() }
                    background: Rectangle { radius: 10; color: parent.hovered ? "#28545a" : "transparent" }
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
        background: Rectangle { radius: 20; color: "#ef152331"; border.color: "#5bffffff"; border.width: 1 }
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
                        background: Rectangle { radius: 10; color: parent.hovered ? "#28545a" : "transparent" }
                        contentItem: Text { text: parent.text; color: player.speed === modelData ? window.accent : window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; leftPadding: 9 }
                    }
                }
            }
        }
    }

    Popup {
        id: ratioPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, controls.y - height - 12)
        width: Math.min(332, window.width - 32)
        height: Math.min(435, Math.max(180, controls.y - headerBar.y - headerBar.height - 24))
        padding: 12
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.revealControls()
        background: Rectangle { radius: 20; color: "#ef152331"; border.color: "#5bffffff" }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: ratioColumn.implicitHeight
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            Column {
                id: ratioColumn
                width: parent.width
                spacing: 4
                Text { text: "CANVAS PREVIEW"; color: window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold; font.letterSpacing: 1.4; leftPadding: 9; bottomPadding: 6 }
                Repeater {
                    model: [
                        { label: "Original", ratio: 0, use: "Window size" },
                        { label: "16:9", ratio: 16/9, use: "YouTube · Facebook landscape" },
                        { label: "9:16", ratio: 9/16, use: "Reels · Shorts · Stories" },
                        { label: "1:1", ratio: 1, use: "Instagram · square posts" },
                        { label: "4:5", ratio: 4/5, use: "Instagram · Facebook feed" },
                        { label: "3:4", ratio: 3/4, use: "Portrait posts" },
                        { label: "2:1", ratio: 2, use: "Etsy listing video" },
                        { label: "1:2", ratio: 1/2, use: "Etsy portrait video" },
                        { label: "1.91:1", ratio: 1.91, use: "Wide social post" }
                    ]
                    delegate: Button {
                        required property var modelData
                        width: ratioColumn.width
                        height: 43
                        onClicked: window.selectCanvas(modelData.label, modelData.ratio)
                        background: Rectangle { radius: 11; color: parent.hovered ? "#28545a" : window.canvasLabel === modelData.label ? "#20545b" : "transparent" }
                        contentItem: RowLayout {
                            spacing: 8
                            Text { text: modelData.label; color: window.canvasLabel === modelData.label ? window.accent : window.ink; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 70 }
                            Text { text: modelData.use; color: window.mutedInk; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }
                Rectangle { width: ratioColumn.width - 4; height: 1; color: "#60344955" }
                RowLayout {
                    width: ratioColumn.width
                    spacing: 7
                    Text { text: "Custom"; color: window.ink; font.pixelSize: 13; Layout.preferredWidth: 53 }
                    SpinBox { id: ratioWidth; from: 1; to: 9999; value: 16; editable: true; Layout.preferredWidth: 68; Accessible.name: "Custom ratio width" }
                    Text { text: ":"; color: window.mutedInk }
                    SpinBox { id: ratioHeight; from: 1; to: 9999; value: 9; editable: true; Layout.preferredWidth: 68; Accessible.name: "Custom ratio height" }
                    Button {
                        text: "Apply"
                        onClicked: window.selectCanvas(ratioWidth.value + ":" + ratioHeight.value, ratioWidth.value / ratioHeight.value)
                    }
                }
                Text { text: "Preview only · source file is unchanged"; color: window.mutedInk; font.pixelSize: 11; leftPadding: 9; topPadding: 7 }
            }
        }
    }

    Popup {
        id: settingsPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, controls.y - height - 12)
        width: 272
        height: Math.min(390, settingsColumn.implicitHeight + padding * 2,
                         Math.max(160, controls.y - headerBar.y - headerBar.height - 24))
        padding: 13
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: {
            desktopIntegration.refreshDefaultStatus()
            themeAccent.refresh()
            window.revealControls()
        }
        onClosed: window.revealControls()
        background: Rectangle { radius: 20; color: "#ef152331"; border.color: "#5bffffff"; border.width: 1 }
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
                    background: Rectangle { radius: 11; color: loopOption.hovered ? "#28545a" : player.looping ? "#20545b" : "transparent" }
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
                    background: Rectangle { radius: 11; color: fillOption.hovered ? "#28545a" : player.videoFill ? "#20545b" : "transparent" }
                    contentItem: RowLayout {
                        Image { source: player.videoFill ? "icons/fill.svg" : "icons/fit.svg"; sourceSize: Qt.size(Math.ceil(18 * Screen.devicePixelRatio), Math.ceil(18 * Screen.devicePixelRatio)); Layout.preferredWidth: 18; Layout.preferredHeight: 18; fillMode: Image.PreserveAspectFit }
                        Text { text: fillOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: player.videoFill ? "FILL" : "FIT"; color: player.videoFill ? window.accent : window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }
                Button {
                    id: accentOption
                    width: settingsPopup.width - 26; height: 42
                    text: "Use system accent"
                    hoverEnabled: true
                    Accessible.name: text
                    onClicked: themeAccent.enabled = !themeAccent.enabled
                    background: Rectangle { radius: 11; color: accentOption.hovered ? "#28545a" : themeAccent.enabled ? "#20545b" : "transparent" }
                    contentItem: RowLayout {
                        Rectangle { width: 17; height: 17; radius: 6; color: window.accent; Layout.preferredWidth: 17; Layout.preferredHeight: 17 }
                        Text { text: accentOption.text; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: themeAccent.enabled ? "ON" : "OFF"; color: themeAccent.enabled ? window.accent : window.mutedInk; font.pixelSize: 11; font.weight: Font.DemiBold }
                    }
                }
                Button {
                    id: ratioOption
                    width: settingsPopup.width - 26; height: 42
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); ratioPopup.open() }
                    background: Rectangle { radius: 11; color: ratioOption.hovered ? "#28545a" : "transparent" }
                    contentItem: RowLayout {
                        Text { text: "▣"; color: window.accent; font.pixelSize: 19; Layout.preferredWidth: 18 }
                        Text { text: "Canvas ratio"; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: window.canvasLabel; color: window.mutedInk; font.pixelSize: 11 }
                    }
                }
                Rectangle { width: settingsPopup.width - 28; height: 1; color: "#60344955" }
                Button {
                    id: defaultOption
                    width: settingsPopup.width - 26; height: 40
                    visible: desktopIntegration.defaultStatusReady && !desktopIntegration.defaultVideoPlayer
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); window.makeDefaultPlayer() }
                    background: Rectangle { radius: 11; color: defaultOption.hovered ? "#28545a" : "transparent" }
                    contentItem: RowLayout {
                        Text { text: "◉"; color: window.accent; font.pixelSize: 17; Layout.preferredWidth: 18 }
                        Text { text: "Make default video player"; color: window.ink; font.pixelSize: 13; Layout.fillWidth: true }
                    }
                }
                Button {
                    id: screenshotOption
                    width: settingsPopup.width - 26; height: 40
                    text: "Save video frame…"
                    hoverEnabled: true
                    onClicked: { settingsPopup.close(); screenshotDialog.open() }
                    background: Rectangle { radius: 11; color: screenshotOption.hovered ? "#28545a" : "transparent" }
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
                    background: Rectangle { radius: 11; color: subtitleOption.hovered ? "#28545a" : "transparent" }
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
                    background: Rectangle { radius: 11; color: shortcutsOption.hovered ? "#28545a" : "transparent" }
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
        opacity: 0
        scale: 0.92
        visible: opacity > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.miniMode ? 104 : window.overlayVisible ? 128 : 24
        width: toastText.implicitWidth + 34
        height: 39
        radius: 13
        color: "#ed152d39"
        border.color: "#4a877f"
        z: 11
        Text { id: toastText; anchors.centerIn: parent; text: window.toastMessage; color: window.ink; font.pixelSize: 13 }
        SequentialAnimation {
            id: toastAnimation
            PropertyAction { target: toast; property: "opacity"; value: 0 }
            PropertyAction { target: toast; property: "scale"; value: 0.92 }
            ParallelAnimation {
                NumberAnimation { target: toast; property: "opacity"; from: 0; to: 1; duration: 100 }
                NumberAnimation { target: toast; property: "scale"; from: 0.92; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            PauseAnimation { duration: 1160 }
            NumberAnimation { target: toast; property: "opacity"; from: 1; to: 0; duration: 220 }
        }
    }
}
