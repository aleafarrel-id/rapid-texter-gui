/**
 * @file LobbyPage.qml
 * @brief Waiting room / lobby for multiplayer game.
 * Shows player list, game settings, language selector, and start button for host.
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

FocusScope {
    id: lobbyPage
    focus: true

    property bool isHost: NetworkManager.isAuthority
    property var players: NetworkManager.players
    property string gameText: NetworkManager.gameText
    property string gameLanguage: NetworkManager.gameLanguage
    property string selectedInterface: NetworkManager.selectedInterface

    signal startGameClicked
    signal leaveClicked
    signal textChanged(string text)

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    // Kick confirmation dialog state
    property string pendingKickUuid: ""
    property string pendingKickName: ""

    // Kick confirmation dialog
    Rectangle {
        id: kickConfirmDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: pendingKickUuid !== ""
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: {
                pendingKickUuid = "";
                pendingKickName = "";
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 300
            height: 150
            radius: 12
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            MouseArea {
                anchors.fill: parent
                // Prevent clicks from closing dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    Layout.fillWidth: true
                    text: "Kick Player"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "Remove " + pendingKickName + " from room?"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Theme.bgTertiary
                        border.color: Theme.borderPrimary

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pendingKickUuid = "";
                                pendingKickName = "";
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Theme.accentRed

                        Text {
                            anchors.centerIn: parent
                            text: "Kick"
                            color: "white"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkManager.kickPlayer(pendingKickUuid);
                                pendingKickUuid = "";
                                pendingKickName = "";
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 550)
        height: contentCol.implicitHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            // Header with role badge
            Column {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "WAITING ROOM"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                }

                // Role badge row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Rectangle {
                        width: roleBadgeText.width + 16
                        height: 24
                        radius: 4
                        color: isHost ? Qt.rgba(0.24, 0.72, 0.31, 0.2) : Qt.rgba(0.34, 0.65, 1, 0.2)
                        border.color: isHost ? Theme.accentGreen : Theme.accentBlue
                        border.width: 1

                        Text {
                            id: roleBadgeText
                            anchors.centerIn: parent
                            text: isHost ? "★ HOST" : "GUEST"
                            color: isHost ? Theme.accentGreen : Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: isHost ? "You control the game" : "Host controls the game"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }
                }
            }

            // Server IP list (for host)
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.preferredHeight: Math.min(NetworkManager.availableInterfaces.length * 40 + 36, 130)
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1
                visible: isHost

                // Header
                Rectangle {
                    id: ipHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 32
                    color: Theme.bgSecondary

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: globeIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: globeIcon
                                source: globeIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "YOUR IP (Share with friends)"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }
                    }
                }

                // IP list
                ListView {
                    anchors.top: ipHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true

                    model: NetworkManager.availableInterfaces

                    delegate: Rectangle {
                        id: interfaceDelegate
                        width: parent ? parent.width : 0
                        height: 42

                        // Highlight selected interface or hover
                        property bool isSelected: selectedInterface === modelData.ip || (selectedInterface === "" && index === 0)
                        color: isSelected ? Qt.rgba(0.34, 0.65, 1, 0.15) : interfaceMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Selection indicator (radio button style)
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: interfaceDelegate.isSelected ? Theme.accentBlue : Theme.borderSecondary
                                border.width: 2

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Theme.accentBlue
                                    visible: interfaceDelegate.isSelected
                                }
                            }

                            // Type badge (Ethernet/WiFi)
                            Rectangle {
                                width: 70
                                height: 22
                                color: modelData.type === "Ethernet" ? Qt.rgba(0.15, 0.85, 0.5, 0.12) : modelData.type === "WiFi" ? Qt.rgba(0.34, 0.65, 1, 0.12) : Qt.rgba(0.5, 0.5, 0.5, 0.12)
                                border.color: modelData.type === "Ethernet" ? Theme.accentGreen : modelData.type === "WiFi" ? Theme.accentBlue : Theme.textMuted
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.type
                                    color: modelData.type === "Ethernet" ? Theme.accentGreen : modelData.type === "WiFi" ? Theme.accentBlue : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            // IP address
                            Text {
                                Layout.fillWidth: true
                                text: modelData.ip
                                color: interfaceDelegate.isSelected ? Theme.accentBlue : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: interfaceDelegate.isSelected
                            }

                            // Active badge for selected
                            Rectangle {
                                width: 60
                                height: 20
                                color: Theme.accentBlue
                                visible: interfaceDelegate.isSelected

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: Theme.bgPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // Click handler
                        MouseArea {
                            id: interfaceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkManager.setSelectedInterface(modelData.ip);
                            }
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < NetworkManager.availableInterfaces.length - 1
                        }
                    }
                }
            }

            // Players list
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(players.length * 44 + 44, 220)
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                // Header
                Rectangle {
                    id: playersHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            Image {
                                id: usersIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: usersIcon
                                source: usersIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "PLAYERS (" + players.length + "/8)"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }
                    }
                }

                // Player list
                ListView {
                    anchors.top: playersHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true

                    model: players

                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: modelData.isLocal ? Qt.rgba(0.34, 0.65, 1, 0.1) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Item {
                                width: 16
                                height: 16
                                Image {
                                    id: userIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/user.svg"
                                    sourceSize: Qt.size(16, 16)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: userIcon
                                    source: userIcon
                                    color: modelData.isLocal ? Theme.accentBlue : Theme.textSecondary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.isHost ? " - Host" : "")
                                color: modelData.isLocal ? Theme.accentBlue : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: modelData.isLocal
                            }

                            // Ready indicator
                            Item {
                                width: 14
                                height: 14
                                Image {
                                    id: checkIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                                    sourceSize: Qt.size(14, 14)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: checkIcon
                                    source: checkIcon
                                    color: Theme.accentGreen
                                }
                            }

                            // Kick button (host only, not for self)
                            Item {
                                width: 14
                                height: 14
                                visible: isHost && !modelData.isLocal

                                Image {
                                    id: kickIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                                    sourceSize: Qt.size(14, 14)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: kickIcon
                                    source: kickIcon
                                    color: Theme.accentRed
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        pendingKickUuid = modelData.id;
                                        pendingKickName = modelData.name;
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < players.length - 1
                        }
                    }
                }
            }

            // Language selector (host only)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: 50
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1
                visible: isHost

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "LANGUAGE:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }

                    Row {
                        spacing: 8

                        Repeater {
                            model: [
                                {
                                    code: "id",
                                    label: "ID"
                                },
                                {
                                    code: "en",
                                    label: "EN"
                                },
                                {
                                    code: "prog",
                                    label: "PROG"
                                }
                            ]

                            Rectangle {
                                width: 50
                                height: 28
                                color: gameLanguage === modelData.code ? Theme.accentBlue : "transparent"
                                border.color: gameLanguage === modelData.code ? Theme.accentBlue : Theme.borderSecondary
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: gameLanguage === modelData.code ? Theme.bgPrimary : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkManager.setGameLanguage(modelData.code)
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Current: " + gameLanguage.toUpperCase()
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }
                }
            }

            // Language indicator (non-host)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: 36
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1
                visible: !isHost

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "Language:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }

                    Text {
                        text: gameLanguage.toUpperCase()
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }
            }

            // Text preview (host can change)
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: textPreviewCol.height + 24
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1

                Column {
                    id: textPreviewCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Row {
                        spacing: 8

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            Image {
                                id: terminalIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/terminal.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: terminalIcon
                                source: terminalIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "Race Text"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        text: gameText.length > 0 ? (gameText.substring(0, 80) + (gameText.length > 80 ? "..." : "")) : "No text set yet..."
                        color: gameText.length > 0 ? Theme.textPrimary : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        wrapMode: Text.WordWrap
                    }

                    NavBtn {
                        visible: isHost
                        labelText: "Refresh Text"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                        onClicked: NetworkManager.refreshGameText()
                    }
                }
            }

            // Action buttons
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 24
                spacing: Theme.spacingM

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Leave"
                    onClicked: {
                        NetworkManager.leaveRoom();
                        lobbyPage.leaveClicked();
                    }
                }

                NavBtn {
                    visible: isHost
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                    labelText: "Start Race"
                    variant: "primary"
                    enabled: players.length >= 1 && gameText.length > 0
                    onClicked: {
                        // Only trigger countdown - page transition handled by onCountdownStarted signal
                        // This ensures host and guest transition together after countdown sync
                        NetworkManager.startCountdown();
                    }
                }

                Text {
                    visible: !isHost
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Waiting for host to start..."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                }
            }
        }
    }

    // Auto-generate text when authority creates room
    Component.onCompleted: {
        if (isHost && gameText.length === 0) {
            NetworkManager.refreshGameText();
        }
    }

    // Listen for countdown signal from host - this triggers transition for guests
    Connections {
        target: NetworkManager

        function onCountdownStarted(seconds) {
            // When countdown starts, transition to race gameplay page
            // This is triggered for BOTH host and guests
            lobbyPage.startGameClicked();
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            NetworkManager.leaveRoom();
            lobbyPage.leaveClicked();
            event.accepted = true;
        }
    }
}
