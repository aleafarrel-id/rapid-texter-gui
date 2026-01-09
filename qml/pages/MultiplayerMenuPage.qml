/**
 * @file MultiplayerMenuPage.qml
 * @brief Multiplayer mode menu - Create or Join game options.
 */
import QtQuick
import QtQuick.Layouts
import "../components"

FocusScope {
    id: multiplayerMenuPage
    focus: true

    signal createGameClicked
    signal joinGameClicked
    signal backClicked

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 500)
        height: menuCol.implicitHeight

        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            spacing: 0

            // Header
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                text: "MULTIPLAYER"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 40
                text: "Race against friends on your local network"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
                horizontalAlignment: Text.AlignHCenter
            }

            // Menu items
            MenuItemC {
                Layout.fillWidth: true
                keyText: "[1]"
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                labelText: "Create Game"
                accentType: "green"
                onClicked: multiplayerMenuPage.createGameClicked()
            }

            MenuItemC {
                Layout.fillWidth: true
                keyText: "[2]"
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                labelText: "Join Game"
                accentType: "blue"
                onClicked: multiplayerMenuPage.joinGameClicked()
            }

            // Spacer
            Item {
                Layout.preferredHeight: 30
            }

            // Back button
            NavBtn {
                Layout.alignment: Qt.AlignHCenter
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back (ESC)"
                onClicked: multiplayerMenuPage.backClicked()
            }
        }
    }

    // Keyboard shortcuts
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_1) {
            multiplayerMenuPage.createGameClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_2) {
            multiplayerMenuPage.joinGameClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            multiplayerMenuPage.backClicked();
            event.accepted = true;
        }
    }
}
