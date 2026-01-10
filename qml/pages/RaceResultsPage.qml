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

    // Dynamic host state - updates when authority changes
    property bool isHost: NetworkManager.isAuthority

    // Refresh isHost on component creation
    Component.onCompleted: {
        resultsPage.isHost = NetworkManager.isAuthority;
    }

    Connections {
        target: NetworkManager
        function onAuthorityChanged() {
            resultsPage.isHost = NetworkManager.isAuthority;
        }
        function onPlayersChanged() {
            // Also refresh when players change (someone leaves)
            resultsPage.isHost = NetworkManager.isAuthority;
        }
    }

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
                            spacing: 8

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
                                elide: Text.ElideRight
                            }

                            // WPM
                            Text {
                                Layout.preferredWidth: 65
                                text: modelData.wpm + " WPM"
                                color: Theme.accentBlue
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                                font.bold: true
                            }

                            // Accuracy
                            Text {
                                Layout.preferredWidth: 50
                                text: (modelData.accuracy !== undefined ? modelData.accuracy.toFixed(1) : "100.0") + "%"
                                color: Theme.accentGreen
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                            }

                            // Errors
                            Text {
                                Layout.preferredWidth: 40
                                text: (modelData.errors !== undefined ? modelData.errors : 0) + " err"
                                color: (modelData.errors !== undefined && modelData.errors > 0) ? Theme.accentRed : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                            }

                            // Time - always show time format for consistency
                            Text {
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                                text: {
                                    var time = modelData.time !== undefined ? modelData.time : 0;
                                    if (time === 0) {
                                        return "0.0s";  // First place finishes at 0 relative time
                                    } else {
                                        return "+" + time.toFixed(1) + "s";
                                    }
                                }
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
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
                    visible: resultsPage.isHost
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
        visible: showInvitePopup && !resultsPage.isHost
        z: 100

        // Block clicks on background
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Absorb clicks
        }

        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: 260
            color: Theme.bgSecondary
            border.color: Theme.borderSecondary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 24

                // Icon and title
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48

                        Image {
                            id: refreshIcon
                            anchors.fill: parent
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: refreshIcon
                            source: refreshIcon
                            color: Theme.accentBlue
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Play Again?"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Host wants to start another race!"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

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
        // ESC to exit (or decline when popup shown)
        if (event.key === Qt.Key_Escape) {
            if (showInvitePopup) {
                // Decline invite
                showInvitePopup = false;
                NetworkManager.declinePlayAgain();
            }
            NetworkManager.leaveRoom();
            resultsPage.exitClicked();
            event.accepted = true;
            return;
        }

        // P for Play Again (host) or Accept (guest with popup)
        if (event.key === Qt.Key_P) {
            if (showInvitePopup && !resultsPage.isHost) {
                // Guest accepts invite
                showInvitePopup = false;
                NetworkManager.acceptPlayAgain();
                resultsPage.returnToLobbyClicked();
            } else if (resultsPage.isHost) {
                // Host starts play again
                NetworkManager.sendPlayAgainInvite();
                resultsPage.returnToLobbyClicked();
            }
            event.accepted = true;
        }
    }
}
