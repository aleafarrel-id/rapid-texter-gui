/**
 * @file HistoryPage.qml
 * @brief Paginated game history display page.
 * @author RapidTexter Team
 * @date 2026
 *
 * Displays a paginated list of past game results with details
 * including WPM, accuracy, difficulty, language, mode, and timestamps.
 *
 * @section shortcuts Keyboard Shortcuts
 * - Key_Escape: Go back
 * - Key_C: Clear history
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"

/**
 * @brief Game history display page component.
 * @inherits Rectangle
 */
Rectangle {
    id: historyPage
    color: Theme.bgPrimary
    focus: true

    /** @property historyData @brief Array of game history entries (populated from backend). */
    property var historyData: []
    property int currentPage: 1
    property int totalPages: 1
    property int totalEntries: 0

    // Navigation signals
    signal backClicked
    signal clearHistoryClicked
    signal multiplayerHistoryClicked

    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Escape:
            backClicked();
            event.accepted = true;
            break;
        case Qt.Key_C:
            clearHistoryClicked();
            event.accepted = true;
            break;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingHuge
        spacing: 0

        // Header section
        Column {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: Theme.spacingM

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM
                Item {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: historyTitleIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(28, 28)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: historyTitleIcon
                        source: historyTitleIcon
                        color: Theme.accentBlue
                    }
                }
                Text {
                    text: "GAME HISTORY"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Page " + historyPage.currentPage + " of " + historyPage.totalPages
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: historyPage.totalEntries + " total entries"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeS
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.width: 1
            border.color: Theme.borderPrimary

            Column {
                anchors.fill: parent

                // Header row
                Rectangle {
                    width: parent.width
                    height: 40
                    color: Theme.bgSecondary

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.borderPrimary
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.paddingHuge
                        anchors.rightMargin: Theme.paddingHuge
                        spacing: 0

                        Repeater {
                            model: [
                                {
                                    text: "WPM",
                                    width: 60
                                },
                                {
                                    text: "ACCURACY",
                                    width: 80
                                },
                                {
                                    text: "TARGET",
                                    width: 60
                                },
                                {
                                    text: "ERRORS",
                                    width: 60
                                },
                                {
                                    text: "DIFFICULTY",
                                    width: 80
                                },
                                {
                                    text: "LANG",
                                    width: 50
                                },
                                {
                                    text: "MODE",
                                    width: 80
                                },
                                {
                                    text: "DATE/TIME",
                                    width: 130
                                }
                            ]
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: modelData.width
                                text: modelData.text
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeS
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - 40
                    clip: true
                    model: historyPage.historyData

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 40
                        color: histMouse.containsMouse ? Theme.bgSecondary : "transparent"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.borderPrimary
                        }
                        Rectangle {
                            width: 2
                            height: parent.height
                            color: modelData.passed ? Theme.accentGreen : Theme.accentRed
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddingHuge
                            anchors.rightMargin: Theme.paddingHuge
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.wpm.toFixed(1)
                                color: modelData.passed ? Theme.accentGreen : Theme.accentRed
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.acc.toFixed(1) + "%"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.target
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.errors
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.difficulty
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 50
                                text: modelData.lang
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.mode
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 130
                                text: modelData.date
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: histMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        // Pagination and nav
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            spacing: Theme.spacingM
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back (ESC)"
                onClicked: historyPage.backClicked()
            }
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                labelText: "Multiplayer History"
                onClicked: historyPage.multiplayerHistoryClicked()
            }
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                labelText: "Clear History (C)"
                variant: "danger"
                onClicked: historyPage.clearHistoryClicked()
            }
        }
    }
}
