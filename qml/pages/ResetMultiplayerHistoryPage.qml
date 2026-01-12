/**
 * @file ResetMultiplayerHistoryPage.qml
 * @brief Confirmation dialog for clearing multiplayer game history.
 * @author RapidTexter Team
 * @date 2026
 *
 * Displays a warning confirmation before permanently deleting
 * all multiplayer game history entries. Action cannot be undone.
 *
 * @section shortcuts Keyboard Shortcuts
 * - Key_Return/Key_Enter: Confirm clear
 * - Key_Escape: Cancel
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Multiplayer History reset confirmation page component.
 * @inherits Rectangle
 */
Rectangle {
    id: resetMpHistoryPage
    color: Theme.bgPrimary
    focus: true

    /** @signal cancelClicked @brief Emitted when user cancels. */
    signal cancelClicked

    /** @signal cleared @brief Emitted when history is successfully cleared. */
    signal cleared

    // State machine for loading animation
    property string pageState: "confirm" // "confirm", "processing", "success"

    // Timer for processing delay (500ms like TUI)
    Timer {
        id: rpProcessingTimer
        interval: 500
        repeat: false
        onTriggered: {
            resetMpHistoryPage.pageState = "success";
            rpSuccessTimer.start();
        }
    }

    // Timer for success display (1 second like TUI)
    Timer {
        id: rpSuccessTimer
        interval: 1000
        repeat: false
        onTriggered: {
            resetMpHistoryPage.cleared();
        }
    }

    function startProcessing() {
        pageState = "processing";
        MultiplayerHistoryManager.clearHistory();
        rpProcessingTimer.start();
    }

    Keys.onPressed: function (event) {
        // Disable keyboard input during processing/success
        if (pageState !== "confirm") {
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            startProcessing();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            cancelClicked();
            event.accepted = true;
            break;
        }
    }

    // Confirmation UI
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: rhCol.implicitHeight
        visible: resetMpHistoryPage.pageState === "confirm"
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        ColumnLayout {
            id: rhCol
            anchors.fill: parent
            spacing: 0

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CLEAR MULTIPLAYER HISTORY"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: rhConfirmCol.implicitHeight + 60
                color: Theme.dangerBg
                border.width: 1
                border.color: Theme.accentRed

                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.accentRed
                }

                Column {
                    id: rhConfirmCol
                    anchors.centerIn: parent
                    spacing: Theme.spacingL

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Are you sure?"
                        color: Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "This will permanently delete all your multiplayer match history."
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeL
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingS
                        Item {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: warningIcon
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                                anchors.fill: parent
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: warningIcon
                                source: warningIcon
                                color: Theme.accentYellow
                            }
                        }
                        Text {
                            text: "This action cannot be undone"
                            color: Theme.accentYellow
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }
                }
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingM
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Cancel (ESC)"
                    onClicked: resetMpHistoryPage.cancelClicked()
                }
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                    labelText: "Confirm (ENTER)"
                    variant: "danger"
                    onClicked: resetMpHistoryPage.startProcessing()
                }
            }
        }
    }

    // Processing Overlay
    Item {
        anchors.centerIn: parent
        visible: resetMpHistoryPage.pageState === "processing"
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingXL

            // Spinning loader
            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: rpLoaderIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }
                ColorOverlay {
                    id: rpLoaderOverlay
                    anchors.fill: rpLoaderIcon
                    source: rpLoaderIcon
                    color: Theme.accentYellow

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: resetMpHistoryPage.pageState === "processing"
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clearing history..."
                color: Theme.accentYellow
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                font.bold: true
            }
        }
    }

    // Success Overlay
    Item {
        anchors.centerIn: parent
        visible: resetMpHistoryPage.pageState === "success"
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingXL

            // Checkmark icon with glow
            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                // Glow effect
                Rectangle {
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    radius: 32
                    color: Theme.accentGreen
                    opacity: 0.2

                    SequentialAnimation on scale {
                        running: resetMpHistoryPage.pageState === "success"
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 1.2
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 500
                            easing.type: Easing.InQuad
                        }
                    }
                }

                Image {
                    id: rpSuccessIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: rpSuccessIcon
                    source: rpSuccessIcon
                    color: Theme.accentGreen
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "History cleared successfully!"
                color: Theme.accentGreen
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                font.bold: true
            }
        }
    }
}
