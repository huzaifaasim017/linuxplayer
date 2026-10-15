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
    property bool draggingSeek: false
    property real seekPreview: 0
    property real rememberedVolume: 70
    property string toastMessage: ""
    readonly property color ink: "#f5f7fb"
    readonly property color mutedInk: "#a7afbf"
    readonly property color accent: "#87aaff"
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
        controlsShown = true
        if (hasMedia && !player.paused) hideTimer.restart()
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
            if (window.hasMedia && !player.paused && !seekSlider.pressed
                    && !trackPopup.opened && !speedPopup.opened && !helpPopup.opened)
                window.controlsShown = false
        }
    }

    Timer {
        id: toastTimer
        interval: 1700
        onTriggered: toastMessage = ""
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
            radius: 20
            color: "#f0182030"
            border.color: "#587092"
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
                    text: "Start over"
                    Layout.fillWidth: true
                    onClicked: {
                        player.seek(0)
                        player.paused = false
                        resumePopup.close()
                    }
                }
                Button {
                    text: "Resume"
                    Layout.fillWidth: true
                    onClicked: {
                        player.seek(resumePopup.resumeSeconds)
                        player.paused = false
                        resumePopup.close()
                    }
                }
            }
        }
    }

    Popup {
        id: helpPopup
        x: Math.max(16, window.width - width - 24)
        y: 68
        width: 270
        padding: 18
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 16; color: "#ee171c29"; border.color: "#506179" }
        contentItem: Column {
            spacing: 8
            Text { text: "Keyboard shortcuts"; color: window.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
            Text { text: "Ctrl+O   Open video"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "Space / K   Play or pause"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "← / →   Skip 5 seconds"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "J / L   Skip 10 seconds"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "↑ / ↓   Change volume"; color: window.mutedInk; font.pixelSize: 13 }
            Text { text: "M   Mute  ·  F   Fullscreen"; color: window.mutedInk; font.pixelSize: 13 }
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
    Shortcut { sequence: "M"; onActivated: {
            if (player.volume > 0) {
                window.rememberedVolume = player.volume
                player.volume = 0
            } else player.volume = Math.max(1, window.rememberedVolume)
            window.revealControls()
        }
    }

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
    }

    // Interaction remains above the video texture; controls are layered above this area.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPositionChanged: window.revealControls()
        onClicked: {
            if (window.hasMedia) {
                player.togglePause()
                window.revealControls()
            }
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
            anchors.centerIn: parent
            width: Math.min(parent.width - 60, 520)
            height: 330
            radius: 28
            color: "#111722"
            border.color: "#263249"
            border.width: 1
            gradient: Gradient {
                GradientStop { position: 0; color: "#172037" }
                GradientStop { position: 1; color: "#10141e" }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 56
                spacing: 16

                Rectangle {
                    width: 76; height: 76; radius: 23
                    color: "#233c6e"
                    border.color: "#5576ad"
                    anchors.horizontalCenter: parent.horizontalCenter
                    Image { source: "icons/play.svg"; anchors.centerIn: parent; width: 32; height: 32 }
                }
                Text {
                    text: "Your screen, your cinema."
                    color: window.ink
                    font.pixelSize: window.compact ? 22 : 26
                    font.weight: Font.DemiBold
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Open a video or drop one anywhere in this window."
                    color: window.mutedInk
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Button {
                    text: "Open video"
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 10; bottomPadding: 10; leftPadding: 23; rightPadding: 23
                    font.pixelSize: 14; font.weight: Font.DemiBold
                    onClicked: videoDialog.open()
                    background: Rectangle {
                        radius: 12
                        color: parent.down ? "#aac3ff" : parent.hovered ? "#9fbaff" : "#87aaff"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#0c152a"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Text {
                    text: "MP4 · MKV · WebM · and more"
                    color: "#74849e"
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // Subtle, custom overlays retain the native window frame for desktop integration.
    Rectangle {
        id: topScrim
        visible: window.hasMedia
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        height: 122
        opacity: window.controlsShown ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#c0000000" }
            GradientStop { position: 1; color: "#00000000" }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    RowLayout {
        id: topBar
        visible: window.hasMedia
        opacity: window.controlsShown ? 1 : 0
        enabled: opacity > 0.1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: window.compact ? 17 : 28
        height: 54
        spacing: 12
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            width: 30; height: 30; radius: 9
            color: "#86aaff"
            Image { anchors.centerIn: parent; source: "icons/play-dark.svg"; width: 16; height: 16 }
        }
        Text {
            text: player.mediaTitle.length ? player.mediaTitle : "Untitled video"
            color: window.ink
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideMiddle
            Layout.fillWidth: true
        }
        IconButton {
            iconName: "help"
            Accessible.name: "Keyboard shortcuts"
            ToolTip.visible: hovered
            ToolTip.text: "Keyboard shortcuts"
            onClicked: { helpPopup.open(); window.revealControls() }
        }
        IconButton {
            iconName: "open"
            Accessible.name: "Open another video"
            ToolTip.visible: hovered
            ToolTip.text: "Open video (Ctrl+O)"
            onClicked: videoDialog.open()
        }
    }

    Rectangle {
        id: bottomScrim
        visible: window.hasMedia
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 224
        opacity: window.controlsShown ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0; color: "#00000000" }
            GradientStop { position: 1; color: "#d9000000" }
        }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    ColumnLayout {
        id: controls
        visible: window.hasMedia
        opacity: window.controlsShown ? 1 : 0
        enabled: opacity > 0.1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: window.compact ? 15 : 28
        anchors.rightMargin: window.compact ? 15 : 28
        anchors.bottomMargin: window.compact ? 12 : 19
        spacing: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Slider {
            id: seekSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 27
            from: 0
            to: Math.max(1, player.duration)
            value: window.draggingSeek ? window.seekPreview : player.position
            enabled: player.duration > 0
            onPressedChanged: {
                window.draggingSeek = pressed
                if (!pressed) {
                    player.seek(value)
                    window.revealControls()
                }
            }
            onMoved: window.seekPreview = value
            background: Rectangle {
                x: seekSlider.leftPadding
                y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                width: seekSlider.availableWidth
                height: 5
                radius: 3
                color: "#64ffffff"
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
                width: seekSlider.pressed || seekSlider.hovered ? 15 : 11
                height: width
                radius: width / 2
                color: "#f6f8ff"
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: window.compact ? 4 : 8

            IconButton {
                iconName: player.paused ? "play" : "pause"
                iconSize: 23
                Accessible.name: player.paused ? "Play" : "Pause"
                ToolTip.visible: hovered
                ToolTip.text: player.paused ? "Play (Space)" : "Pause (Space)"
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
            Text {
                text: window.timeText(window.draggingSeek ? window.seekPreview : player.position)
                      + "  /  " + window.timeText(player.duration)
                color: window.ink
                font.pixelSize: 13
                font.family: "monospace"
                Layout.leftMargin: window.compact ? 2 : 10
            }
            Item { Layout.fillWidth: true }
            IconButton {
                iconName: player.volume <= 0 ? "mute" : "volume"
                Accessible.name: player.volume <= 0 ? "Unmute" : "Mute"
                ToolTip.visible: hovered
                ToolTip.text: player.volume <= 0 ? "Unmute (M)" : "Mute (M)"
                onClicked: {
                    if (player.volume > 0) {
                        window.rememberedVolume = player.volume
                        player.volume = 0
                    } else player.volume = Math.max(1, window.rememberedVolume)
                    window.revealControls()
                }
            }
            Slider {
                id: volumeSlider
                visible: !window.compact
                Layout.preferredWidth: 83
                Layout.preferredHeight: 32
                from: 0; to: 100
                value: player.volume
                Accessible.name: "Volume"
                onMoved: player.volume = value
                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: "#68ffffff"
                    Rectangle { width: parent.width * volumeSlider.visualPosition; height: parent.height; radius: 2; color: window.ink }
                }
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    width: 11; height: 11; radius: 6; color: window.ink
                }
            }
            IconButton {
                iconName: "captions"
                Accessible.name: "Audio and subtitles"
                ToolTip.visible: hovered
                ToolTip.text: "Audio and subtitles"
                onClicked: { speedPopup.close(); trackPopup.open(); window.revealControls() }
            }
            IconButton {
                iconName: "speed"
                Accessible.name: "Playback speed"
                ToolTip.visible: hovered
                ToolTip.text: "Playback speed"
                onClicked: { trackPopup.close(); speedPopup.open(); window.revealControls() }
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

    Popup {
        id: trackPopup
        x: Math.max(16, window.width - width - 24)
        y: Math.max(16, window.height - height - 84)
        width: 278
        height: Math.min(385, trackColumn.implicitHeight + 28)
        padding: 14
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.revealControls()
        onClosed: window.revealControls()
        background: Rectangle { radius: 18; color: "#ee171c29"; border.color: "#506179"; border.width: 1 }
        contentItem: Flickable {
            contentWidth: width
            contentHeight: trackColumn.implicitHeight
            clip: true
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
                        background: Rectangle { radius: 8; color: parent.hovered ? "#294266" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Text { text: "SUBTITLES"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 8; topPadding: 13; bottomPadding: 5 }
                Button {
                    width: trackColumn.width; height: 36
                    text: (player.subtitleTrackId <= 0 ? "✓  " : "     ") + "Off"
                    onClicked: { player.subtitleTrackId = 0; trackPopup.close() }
                    background: Rectangle { radius: 8; color: parent.hovered ? "#294266" : "transparent" }
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
                        background: Rectangle { radius: 8; color: parent.hovered ? "#294266" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    }
                }
                Button {
                    width: trackColumn.width; height: 38
                    text: "+  Load subtitle file…"
                    onClicked: { trackPopup.close(); subtitleDialog.open() }
                    background: Rectangle { radius: 8; color: parent.hovered ? "#294266" : "transparent" }
                    contentItem: Text { text: parent.text; color: window.accent; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Popup {
        id: speedPopup
        x: Math.max(16, window.width - width - 76)
        y: Math.max(16, window.height - height - 84)
        width: 155
        height: 252
        padding: 11
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 18; color: "#ee171c29"; border.color: "#506179"; border.width: 1 }
        Column {
            spacing: 2
            Text { text: "SPEED"; color: window.mutedInk; font.pixelSize: 11; font.letterSpacing: 1.5; leftPadding: 9; bottomPadding: 5 }
            Repeater {
                model: [0.5, 0.75, 1, 1.25, 1.5, 2]
                delegate: Button {
                    required property real modelData
                    width: speedPopup.width - 22; height: 31
                    text: modelData === 1 ? "Normal" : modelData + "×"
                    onClicked: { player.speed = modelData; speedPopup.close(); window.revealControls() }
                    background: Rectangle { radius: 8; color: parent.hovered ? "#294266" : "transparent" }
                    contentItem: Text { text: parent.text; color: player.speed === modelData ? window.accent : window.ink; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; leftPadding: 9 }
                }
            }
        }
    }

    Rectangle {
        id: toast
        visible: window.toastMessage.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.hasMedia ? 110 : 24
        width: toastText.implicitWidth + 34
        height: 39
        radius: 12
        color: "#e81b2332"
        border.color: "#475874"
        z: 11
        Text { id: toastText; anchors.centerIn: parent; text: window.toastMessage; color: window.ink; font.pixelSize: 13 }
    }
}
