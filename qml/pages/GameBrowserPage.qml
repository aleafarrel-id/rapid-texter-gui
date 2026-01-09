/**
 * @file GameBrowserPage.qml
 * @brief Auto-discovery game browser - scans network for available games.
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

FocusScope {
    id: gameBrowserPage
    focus: true

    signal gameSelected(string hostIp, int port)
    signal joinSuccess
    signal backClicked

    property bool isScanning: NetworkManager.isScanning
    property bool isConnecting: NetworkManager.isConnecting
    property var discoveredGames: NetworkManager.discoveredRooms
    property string errorMsg: ""

    Connections {
        target: NetworkManager
        function onJoinFailed(reason) {
            errorMsg = reason;
            loadingOverlay.visible = false;
        }
        function onJoinSucceeded() {
            loadingOverlay.visible = false;
            gameBrowserPage.joinSuccess();
        }
        function onConnectingChanged() {
            if (NetworkManager.isConnecting) {
                loadingOverlay.visible = true;
                errorMsg = "";
            }
        }
    }

    Component.onCompleted: {
        NetworkManager.startScanning();
    }

    Component.onDestruction: {
        NetworkManager.stopScanning();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 550)
        height: contentCol.implicitHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            // Header
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                text: "JOIN GAME"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Scanning indicator
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 20
                spacing: 10

                Item {
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: scanIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(16, 16)
                        visible: false

                        RotationAnimation on rotation {
                            running: isScanning
                            from: 0
                            to: 360
                            duration: 2000
                            loops: Animation.Infinite
                        }
                    }

                    ColorOverlay {
                        anchors.fill: scanIcon
                        source: scanIcon
                        color: Theme.accentBlue
                        rotation: scanIcon.rotation
                    }
                }

                Text {
                    text: isScanning ? "Scanning for games..." : "Scan complete"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                }
            }

            // Games list container
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                // Header
                Rectangle {
                    id: listHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "AVAILABLE GAMES (" + discoveredGames.length + ")"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }

                // Games list
                ListView {
                    id: gamesListView
                    anchors.top: listHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    anchors.topMargin: 0
                    clip: true

                    model: discoveredGames

                    delegate: Rectangle {
                        width: gamesListView.width
                        height: 50
                        color: mouseArea.containsMouse ? Theme.bgSecondary : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Game icon
                            Item {
                                width: 20
                                height: 20
                                Image {
                                    id: gamepadIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/gamepad.svg"
                                    sourceSize: Qt.size(20, 20)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: gamepadIcon
                                    source: gamepadIcon
                                    color: Theme.accentBlue
                                }
                            }

                            // Game info
                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.hostName + "'s Game"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeM
                                    font.bold: true
                                }

                                Row {
                                    spacing: 8

                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        Image {
                                            id: usersIconSmall
                                            anchors.fill: parent
                                            source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                                            sourceSize: Qt.size(12, 12)
                                            visible: false
                                        }
                                        ColorOverlay {
                                            anchors.fill: usersIconSmall
                                            source: usersIconSmall
                                            color: Theme.textMuted
                                        }
                                    }

                                    Text {
                                        text: modelData.playerCount + "/" + modelData.maxPlayers
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSM
                                    }
                                }
                            }

                            // Status badge
                            Rectangle {
                                width: statusText.width + 16
                                height: 22
                                color: modelData.status === "waiting" ? Qt.rgba(0.24, 0.72, 0.31, 0.15) : Qt.rgba(0.82, 0.60, 0.13, 0.15)
                                border.color: modelData.status === "waiting" ? Theme.accentGreen : Theme.accentYellow
                                border.width: 1

                                Text {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: modelData.status === "waiting" ? "Open" : "In Game"
                                    color: modelData.status === "waiting" ? Theme.accentGreen : Theme.accentYellow
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            // Join button
                            NavBtn {
                                labelText: "Join"
                                variant: "primary"
                                enabled: modelData.status === "waiting"
                                onClicked: {
                                    gameBrowserPage.gameSelected(modelData.hostIp, modelData.port);
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onDoubleClicked: {
                                if (modelData.status === "waiting") {
                                    gameBrowserPage.gameSelected(modelData.hostIp, modelData.port);
                                }
                            }
                        }

                        // Bottom border
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < discoveredGames.length - 1
                        }
                    }

                    // Empty state
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: discoveredGames.length === 0

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 32
                            height: 32

                            Image {
                                id: emptyGlobeIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                                sourceSize: Qt.size(32, 32)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: emptyGlobeIcon
                                source: emptyGlobeIcon
                                color: Theme.textMuted
                                opacity: 0.5
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: isScanning ? "Looking for games..." : "No games found"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                    }
                }
            }

            // Buttons row
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                spacing: Theme.spacingM

                // Refresh button with animation
                Rectangle {
                    id: refreshBtn
                    width: 120
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    color: isScanning ? Theme.bgTertiary : Theme.accentYellow
                    border.color: isScanning ? Theme.borderPrimary : "transparent"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: refreshIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                                sourceSize: Qt.size(16, 16)
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: refreshIcon
                                source: refreshIcon
                                color: isScanning ? Theme.textMuted : Theme.bgPrimary

                                RotationAnimation on rotation {
                                    id: spinAnimation
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                    running: isScanning
                                }
                            }
                        }

                        Text {
                            text: isScanning ? "Scanning..." : "Refresh"
                            color: isScanning ? Theme.textMuted : Theme.bgPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !isScanning
                        onClicked: NetworkManager.refreshRooms()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back (ESC)"
                    onClicked: gameBrowserPage.backClicked()
                }
            }

            // Manual IP fallback section
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 24
                height: 1
                color: Theme.borderSecondary
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 16
                text: "Can't find the game? Enter IP manually:"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: Theme.spacingM

                Rectangle {
                    width: 180
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.bgSecondary
                    border.color: manualIpInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary
                    border.width: 1

                    TextInput {
                        id: manualIpInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            text: "192.168.1.xxx"
                            color: Theme.textMuted
                            font: parent.font
                            verticalAlignment: Text.AlignVCenter
                            visible: parent.text.length === 0
                        }

                        onAccepted: {
                            if (text.length > 0) {
                                gameBrowserPage.gameSelected(text, 52765);
                            }
                        }
                    }
                }

                NavBtn {
                    labelText: "Connect"
                    enabled: manualIpInput.text.length > 0
                    onClicked: {
                        gameBrowserPage.gameSelected(manualIpInput.text, 52765);
                    }
                }
            }
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            gameBrowserPage.backClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
            NetworkManager.refreshRooms();
            event.accepted = true;
        }
    }
    // Loading Overlay
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        z: 100
        visible: false

        Column {
            anchors.centerIn: parent
            spacing: 20

            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: loadIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false

                    RotationAnimation on rotation {
                        running: loadingOverlay.visible
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                ColorOverlay {
                    anchors.fill: loadIcon
                    source: loadIcon
                    color: Theme.accentBlue
                    rotation: loadIcon.rotation
                }
            }

            Text {
                text: "Connecting..."
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeL
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Error Overlay
    Rectangle {
        id: errorOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        z: 100
        visible: errorMsg !== ""

        Rectangle {
            width: 400
            height: 200
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1
            anchors.centerIn: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Text {
                    Layout.fillWidth: true
                    text: "Connection Failed"
                    color: Theme.accentRed
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: errorMsg
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                NavBtn {
                    Layout.alignment: Qt.AlignHCenter
                    labelText: "Close"
                    onClicked: errorMsg = ""
                }
            }
        }
    }
}
