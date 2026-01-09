/**
 * @file PlayerNamePage.qml
 * @brief Page for entering player name before creating/joining game.
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

FocusScope {
    id: playerNamePage
    focus: true

    property bool isCreating: true  // true = create game, false = join game
    property string initialName: ""

    signal confirmed(string name)
    signal backClicked

    Component.onCompleted: {
        nameInput.text = initialName || NetworkManager.playerName || "";
        nameInput.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 450)
        height: contentCol.implicitHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            // Header
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                text: isCreating ? "CREATE GAME" : "JOIN GAME"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 40
                text: "Enter your player name"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
                horizontalAlignment: Text.AlignHCenter
            }

            // Name input field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: Theme.bgSecondary
                border.color: nameInput.activeFocus ? Theme.accentBlue : Theme.borderPrimary
                border.width: 2
                radius: Theme.radiusM

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Item {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: userIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/user.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(24, 24)
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: userIcon
                            source: userIcon
                            color: Theme.accentBlue
                        }
                    }

                    TextInput {
                        id: nameInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXL
                        maximumLength: 16
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            text: "Your name..."
                            color: Theme.textMuted
                            font: parent.font
                            visible: parent.text.length === 0
                        }

                        onAccepted: {
                            if (text.trim().length > 0) {
                                NetworkManager.playerName = text.trim();
                                playerNamePage.confirmed(text.trim());
                            }
                        }
                    }
                }
            }

            // Character count
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: nameInput.text.length + "/16"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
                horizontalAlignment: Text.AlignRight
            }

            // Spacer
            Item {
                Layout.preferredHeight: 30
            }

            // Buttons
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingM

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back"
                    onClicked: playerNamePage.backClicked()
                }

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                    labelText: "Continue"
                    variant: "primary"
                    enabled: nameInput.text.trim().length > 0
                    onClicked: {
                        NetworkManager.playerName = nameInput.text.trim();
                        playerNamePage.confirmed(nameInput.text.trim());
                    }
                }
            }
        }
    }

    // Keyboard handling
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            playerNamePage.backClicked();
            event.accepted = true;
        }
    }
}
