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
    property bool showGameInProgressPopup: false

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
                        color: modelData.isLocal ? Qt.rgba(0.34, 0.65, 1, 0.1) : 
                               (modelData.hasLeft ? Qt.rgba(1, 0.8, 0.3, 0.1) : "transparent") // Yellow tint for left players

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
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
                                text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.hasLeft ? " (Left)" : "")
                                color: modelData.hasLeft ? Theme.textMuted : (modelData.isLocal ? Theme.accentBlue : Theme.textPrimary)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: modelData.isLocal
                                font.italic: modelData.hasLeft
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

                            // Time - show actual race duration or "Left"
                            Text {
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                                text: {
                                    if (modelData.hasLeft) return "Left";
                                    var duration = modelData.duration !== undefined ? modelData.duration : 0;
                                    return duration + "s";
                                }
                                color: modelData.hasLeft ? Theme.textMuted : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                                font.italic: modelData.hasLeft
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
                            resultsPage.showInvitePopup = false;
                            NetworkManager.acceptPlayAgain();
                            resultsPage.returnToLobbyClicked();
                        }
                    }

                    NavBtn {
                        labelText: "Decline"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                        onClicked: {
                            resultsPage.showInvitePopup = false;
                            NetworkManager.declinePlayAgain();
                            resultsPage.exitClicked();
                        }
                    }
                }
            }
        }
    }

    // Game In Progress Popup (Late Join Attempt)
    Rectangle {
        id: gameInProgressPopupOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: showGameInProgressPopup
        z: 110

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: 240
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 24
                width: parent.width - 40

                // Icon and title
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40
                        
                        Image {
                            id: clockIcon
                            anchors.fill: parent
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            sourceSize: Qt.size(40, 40)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: clockIcon
                            source: clockIcon
                            color: Theme.accentRed 
                        }
                        // Fallback circle if icon missing (play again popup used refresh)
                        Rectangle {
                           anchors.fill: parent 
                           radius: 20
                           color: "transparent"
                           border.color: Theme.accentRed
                           border.width: 2
                           visible: clockIcon.status !== Image.Ready
                           
                           Text {
                               anchors.centerIn: parent
                               text: "!"
                               color: Theme.accentRed
                               font.bold: true
                               font.pixelSize: 24
                           }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Race Already Started"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: "The host has already started the race. You cannot join this session."
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                NavBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    labelText: "OK"
                    variant: "primary"
                    onClicked: {
                        resultsPage.showGameInProgressPopup = false;
                        resultsPage.showInvitePopup = false;
                        NetworkManager.declinePlayAgain(); // Leave room
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
            resultsPage.showInvitePopup = true;
        }

        function onGameInProgress() {
            console.log("[RaceResultsPage] Game in progress - late join prevented");
            resultsPage.showInvitePopup = false; // Hide invite popup if open
            resultsPage.showGameInProgressPopup = true;
        }
    }

    Keys.onPressed: function (event) {
        // ESC to exit (or decline when popup shown)
        if (event.key === Qt.Key_Escape) {
            if (resultsPage.showInvitePopup) {
                // Decline invite
                resultsPage.showInvitePopup = false;
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
