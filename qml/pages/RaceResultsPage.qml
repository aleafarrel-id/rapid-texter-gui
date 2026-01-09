/**
 * @file RaceResultsPage.qml
 * @brief Race results page showing final rankings.
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

FocusScope {
    id: resultsPage
    focus: true

    property var rankings: []  // Array of {id, name, wpm, position, isLocal}
    property int localWpm: 0
    property real localAccuracy: 0
    property int localErrors: 0
    property int localPosition: 0

    signal playAgainClicked
    signal exitClicked
    signal returnToLobbyClicked

    // Play again invitation state (for guests)
    property bool showInvitePopup: false

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 500)
        height: contentCol.implicitHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            // Trophy icon
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16
                width: 48
                height: 48

                Image {
                    id: trophyIcon
                    anchors.fill: parent
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/trophy.svg"
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: trophyIcon
                    source: trophyIcon
                    color: localPosition === 1 ? Theme.accentGreen : Theme.textSecondary
                }
            }

            // Header
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                text: "RACE COMPLETE"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Your position
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                text: localPosition > 0 ? "You finished #" + localPosition : "Race finished"
                color: localPosition === 1 ? Theme.accentGreen : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                horizontalAlignment: Text.AlignHCenter
            }

            // Your stats
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                height: 80
                color: Theme.bgSecondary
                border.color: Theme.accentBlue
                border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 40

                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localWpm.toString()
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "WPM"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localAccuracy.toFixed(1) + "%"
                            color: Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Accuracy"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localErrors.toString()
                            color: localErrors > 0 ? Theme.accentRed : Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Errors"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }
                }
            }

            // Rankings list
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(rankings.length * 44 + 40, 140)
                Layout.bottomMargin: 16
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                // Header
                Rectangle {
                    id: rankHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Theme.radiusM
                        color: Theme.bgSecondary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "FINAL RANKINGS"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }

                ListView {
                    anchors.top: rankHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true

                    model: rankings

                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: modelData.isLocal ? Qt.rgba(0.34, 0.65, 1, 0.1) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Position medal
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: {
                                    switch (modelData.position) {
                                    case 1:
                                        return "#FFD700";  // Gold
                                    case 2:
                                        return "#C0C0C0";  // Silver
                                    case 3:
                                        return "#CD7F32";  // Bronze
                                    default:
                                        return Theme.bgTertiary;
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.position.toString()
                                    color: modelData.position <= 3 ? "#000" : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            // Name
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name + (modelData.isLocal ? " (You)" : "")
                                color: modelData.isLocal ? Theme.accentBlue : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: modelData.isLocal
                            }

                            // WPM
                            Row {
                                spacing: 4

                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12
                                    height: 12

                                    Image {
                                        id: trendIcon
                                        anchors.fill: parent
                                        source: "qrc:/qt/qml/rapid_texter/assets/icons/trend-up.svg"
                                        sourceSize: Qt.size(12, 12)
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: trendIcon
                                        source: trendIcon
                                        color: Theme.accentGreen
                                    }
                                }

                                Text {
                                    text: modelData.wpm + " WPM"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                }
                            }

                            // Accuracy
                            Row {
                                spacing: 4

                                Text {
                                    text: (modelData.accuracy !== undefined ? Math.round(modelData.accuracy) : 100) + "%"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < rankings.length - 1
                        }
                    }
                }
            }

            // Action buttons
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 32
                spacing: Theme.spacingM

                // Host: Play Again button
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    labelText: "Play Again"
                    variant: "primary"
                    visible: NetworkManager.isAuthority
                    onClicked: {
                        NetworkManager.sendPlayAgainInvite();
                        resultsPage.returnToLobbyClicked();
                    }
                }

                // Exit button (always visible)
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                    labelText: "Exit"
                    onClicked: {
                        NetworkManager.leaveRoom();
                        resultsPage.exitClicked();
                    }
                }
            }
        }
    }

    // Play Again Invitation Popup (Guest only)
    Rectangle {
        id: invitePopup
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: showInvitePopup && !NetworkManager.isAuthority
        z: 100

        // Block clicks on background
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Absorb clicks
        }

        Rectangle {
            anchors.centerIn: parent
            width: 340
            height: 200
            color: Theme.bgSecondary
            border.color: Theme.accentBlue
            border.width: 2
            radius: 12

            Column {
                anchors.centerIn: parent
                spacing: 20

                // Icon and title
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "🎮"
                        font.pixelSize: 36
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Play Again?"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 22
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Host wants to start another race!"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    NavBtn {
                        labelText: "Accept"
                        variant: "primary"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                        onClicked: {
                            showInvitePopup = false;
                            NetworkManager.acceptPlayAgain();
                            resultsPage.returnToLobbyClicked();
                        }
                    }

                    NavBtn {
                        labelText: "Decline"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                        onClicked: {
                            showInvitePopup = false;
                            NetworkManager.declinePlayAgain();
                            resultsPage.exitClicked();
                        }
                    }
                }
            }
        }
    }

    // Network connections for play again
    Connections {
        target: NetworkManager

        function onPlayAgainInviteReceived() {
            console.log("[RaceResultsPage] Received play again invite");
            showInvitePopup = true;
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape && !showInvitePopup) {
            NetworkManager.leaveRoom();
            resultsPage.exitClicked();
            event.accepted = true;
        }
    }
}
