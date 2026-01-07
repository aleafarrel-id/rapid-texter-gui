/**
 * @file HistoryDetailOverlay.qml
 * @brief Modal overlay displaying detailed game record information.
 * @author RapidTexter Team
 * @date 2026
 *
 * Premium overlay component that shows comprehensive game statistics
 * when a history record is clicked. Design inspired by MonkeyType
 * while maintaining consistency with RapidTexter's design system.
 *
 * @section shortcuts Keyboard Shortcuts
 * - Key_Escape: Close overlay
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * @brief Modal overlay for displaying detailed history record.
 * @inherits Rectangle
 */
Rectangle {
    id: overlay
    anchors.fill: parent
    color: Qt.rgba(0.05, 0.067, 0.09, 0.85)
    visible: false
    opacity: 0
    z: 10000

    /** @property recordData @brief The history record object to display. */
    property var recordData: null

    /** @property passed @brief Whether the target WPM was achieved. */
    property bool passed: recordData ? recordData.wpm >= recordData.targetWPM : false

    /** @property showOverlay @brief Controls the overlay visibility with animation */
    property bool showOverlay: false

    /** @signal close @brief Emitted when overlay should be closed. */
    signal close

    /** @function formatTime @brief Formats seconds into human readable time (e.g., "15.3s" or "1m 30.5s") */
    function formatTime(seconds) {
        if (seconds === undefined || seconds === null || seconds === 0)
            return "-";
        // Show 1 decimal place for better precision
        if (seconds < 60) {
            return seconds.toFixed(1) + "s";
        } else {
            var mins = Math.floor(seconds / 60);
            var remainingSecs = seconds % 60;
            return mins + "m " + remainingSecs.toFixed(1) + "s";
        }
    }

    // State machine for smooth open/close animations
    states: [
        State {
            name: "hidden"
            when: !showOverlay
            PropertyChanges {
                target: overlay
                opacity: 0
            }
            PropertyChanges {
                target: contentCard
                scale: 0.95
                opacity: 0
            }
        },
        State {
            name: "visible"
            when: showOverlay
            PropertyChanges {
                target: overlay
                visible: true
                opacity: 1
            }
            PropertyChanges {
                target: contentCard
                scale: 1
                opacity: 1
            }
        }
    ]

    transitions: [
        // Opening animation
        Transition {
            from: "hidden"
            to: "visible"
            SequentialAnimation {
                PropertyAction {
                    target: overlay
                    property: "visible"
                    value: true
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: contentCard
                        properties: "scale,opacity"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        },
        // Closing animation
        Transition {
            from: "visible"
            to: "hidden"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: contentCard
                        properties: "scale,opacity"
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                }
                PropertyAction {
                    target: overlay
                    property: "visible"
                    value: false
                }
            }
        }
    ]

    // Sync showOverlay with external binding on open only
    onShowOverlayChanged: {
        // When parent sets showOverlay to true, ensure we're ready
        // When parent sets it to false, the state machine handles the animation
    }

    // Focus handling for keyboard
    focus: showOverlay
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            close();
            event.accepted = true;
        }
    }

    // Background click to close
    MouseArea {
        anchors.fill: parent
        onClicked: overlay.close()
    }

    // Content card
    Rectangle {
        id: contentCard
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 580)
        height: contentColumn.implicitHeight + Theme.paddingXXL * 2
        color: Theme.bgSecondary
        border.width: 1
        border.color: Theme.borderPrimary
        radius: 8
        opacity: 0
        scale: 0.95

        // Prevent clicks from closing overlay
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Absorb click
        }

        // Left accent bar
        Rectangle {
            width: 4
            height: parent.height
            color: overlay.passed ? Theme.accentGreen : Theme.accentRed
            radius: 8
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.paddingXXL
            anchors.leftMargin: Theme.paddingXXL + 8
            spacing: Theme.spacingXL

            // Header with title and close button
            RowLayout {
                Layout.fillWidth: true

                Row {
                    spacing: Theme.spacingS
                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: headerIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(20, 20)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: headerIcon
                            source: headerIcon
                            color: Theme.accentBlue
                        }
                    }
                    Text {
                        text: "GAME DETAILS"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Close button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 4
                    color: closeBtn.containsMouse ? Theme.bgTertiary : "transparent"

                    Item {
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                        Image {
                            id: closeIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(16, 16)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: closeIcon
                            source: closeIcon
                            color: closeBtn.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: closeBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: overlay.close()
                    }
                }
            }

            // WPM Display (hero section)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: overlay.passed ? Theme.successBg : Theme.dangerBg
                border.width: 1
                border.color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                radius: 6

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: overlay.recordData ? Math.round(overlay.recordData.wpm) : "0"
                        color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: 48
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "WORDS PER MINUTE"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        font.letterSpacing: 1
                    }
                }
            }

            // Stats row
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Repeater {
                    model: [
                        {
                            label: "ACCURACY",
                            value: overlay.recordData ? overlay.recordData.accuracy.toFixed(1) + "%" : "0%",
                            color: Theme.textPrimary
                        },
                        {
                            label: "TARGET",
                            value: overlay.recordData ? overlay.recordData.targetWPM + " WPM" : "0 WPM",
                            color: Theme.accentBlue
                        },
                        {
                            label: "ERRORS",
                            value: overlay.recordData ? overlay.recordData.errors.toString() : "0",
                            color: Theme.accentRed
                        },
                        {
                            label: "TIME",
                            value: overlay.recordData ? formatTime(overlay.recordData.timeElapsed) : "-",
                            color: Theme.accentYellow
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.borderPrimary
                        radius: 6

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeS
                                font.letterSpacing: 1
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: modelData.color
                                font.family: Theme.fontFamily
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // Session info section
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: sessionInfoCol.implicitHeight + Theme.paddingL * 2
                color: Theme.bgPrimary
                border.width: 1
                border.color: Theme.borderPrimary
                radius: 6

                Column {
                    id: sessionInfoCol
                    anchors.fill: parent
                    anchors.margins: Theme.paddingL
                    spacing: Theme.spacingSM

                    Text {
                        text: "SESSION INFO"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        font.letterSpacing: 1
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        rowSpacing: Theme.spacingS
                        columnSpacing: Theme.spacingL

                        // Difficulty
                        Text {
                            text: "Difficulty"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.difficulty : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Language
                        Text {
                            text: "Language"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.language : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Mode
                        Text {
                            text: "Mode"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.mode : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Date/Time
                        Text {
                            text: "Date/Time"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.timestamp : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Time Played
                        Text {
                            text: "Time Played"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? formatTime(overlay.recordData.timeElapsed) : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Pass/Fail status banner
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: overlay.passed ? Theme.successBg : Theme.dangerBg
                border.width: 1
                border.color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                radius: 6

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    Item {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        Image {
                            id: statusIcon
                            source: overlay.passed ? "qrc:/qt/qml/rapid_texter/assets/icons/check.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(18, 18)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: statusIcon
                            source: statusIcon
                            color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        }
                    }
                    Text {
                        text: overlay.passed ? "TARGET ACHIEVED" : "TARGET NOT MET"
                        color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Close hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press ESC or click outside to close"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
            }
        }
    }
}
