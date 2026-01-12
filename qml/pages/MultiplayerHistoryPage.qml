/**
 * @file MultiplayerHistoryPage.qml
 * @brief Page for displaying multiplayer game history.
 * @author RapidTexter Team
 * @date 2026
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

Rectangle {
    id: mpHistoryPage
    color: Theme.bgPrimary
    focus: true

    property var historyData: MultiplayerHistoryManager.historyData
    property int totalEntries: MultiplayerHistoryManager.totalEntries

    signal backClicked

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            backClicked();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingHuge
        spacing: 0

        // Header
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
                        id: titleIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(28, 28)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: titleIcon
                        source: titleIcon
                        color: Theme.accentBlue
                    }
                }
                Text {
                    text: "MULTIPLAYER HISTORY"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: mpHistoryPage.totalEntries + " matches played"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeS
            }
        }

        // List Header
        Rectangle {
            Layout.fillWidth: true
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
                spacing: 20

                Text {
                    Layout.preferredWidth: 150
                    text: "DATE/TIME"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                }
                Text {
                    Layout.preferredWidth: 150
                    text: "HOST"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                }
                Text {
                    Layout.preferredWidth: 80
                    text: "YOUR RANK"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    Layout.preferredWidth: 80
                    text: "YOUR WPM"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Item { Layout.fillWidth: true } // Spacer
            }
        }

        // List View
        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: mpHistoryPage.historyData
            spacing: 5

            delegate: Rectangle {
                id: delegateItem
                width: ListView.view.width
                height: isExpanded ? (40 + playersList.height + 20) : 40
                color: mouseArea.containsMouse ? Theme.bgSecondary : "transparent"
                Behavior on height { NumberAnimation { duration: 200 } }
                
                property bool isExpanded: false

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.borderPrimary
                    visible: !isExpanded
                }

                // Main Row
                RowLayout {
                    id: mainRow
                    height: 40
                    width: parent.width
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingHuge
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingHuge
                    spacing: 20

                    Text {
                        Layout.preferredWidth: 150
                        text: modelData.timestamp
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                    Text {
                        Layout.preferredWidth: 150
                        text: modelData.hostName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.preferredWidth: 80
                        text: "#" + modelData.localRank
                        color: (modelData.localRank === 1) ? Theme.accentYellow : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                    }
                    Text {
                        Layout.preferredWidth: 80
                        text: modelData.localWpm
                        color: Theme.accentGreen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: delegateItem.isExpanded ? "Hide Details" : "Show Details"
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        visible: mouseArea.containsMouse || delegateItem.isExpanded
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: mainRow
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: delegateItem.isExpanded = !delegateItem.isExpanded
                }

                // Expanded Details (Player List)
                Rectangle {
                    id: detailsRect
                    anchors.top: mainRow.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: Theme.bgSecondary
                    visible: delegateItem.isExpanded
                    opacity: delegateItem.isExpanded ? 1 : 0
                    
                    ColumnLayout {
                        id: playersList
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 5
                        
                        // Header for player list
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text { Layout.preferredWidth: 30; text: "#"; color: Theme.textMuted; font.family: Theme.fontFamily; font.bold: true }
                            Text { Layout.fillWidth: true; text: "Player"; color: Theme.textMuted; font.family: Theme.fontFamily; font.bold: true }
                            Text { Layout.preferredWidth: 60; text: "WPM"; color: Theme.textMuted; font.family: Theme.fontFamily; font.bold: true; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 60; text: "Acc"; color: Theme.textMuted; font.family: Theme.fontFamily; font.bold: true; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 60; text: "Err"; color: Theme.textMuted; font.family: Theme.fontFamily; font.bold: true; horizontalAlignment: Text.AlignRight }
                        }
                        
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderPrimary }

                        Repeater {
                            model: modelData.players
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Text { 
                                    Layout.preferredWidth: 30
                                    text: modelData.position
                                    color: (modelData.position === 1) ? Theme.accentYellow : Theme.textSecondary
                                    font.family: Theme.fontFamily 
                                }
                                Text { 
                                    Layout.fillWidth: true
                                    text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.hasLeft ? " [Left]" : "")
                                    color: modelData.isLocal ? Theme.accentBlue : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.bold: modelData.isLocal
                                }
                                Text { 
                                    Layout.preferredWidth: 60
                                    text: modelData.wpm
                                    color: Theme.accentGreen
                                    font.family: Theme.fontFamily 
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text { 
                                    Layout.preferredWidth: 60
                                    text: modelData.accuracy.toFixed(1) + "%"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily 
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text { 
                                    Layout.preferredWidth: 60
                                    text: modelData.errors
                                    color: (modelData.errors > 0) ? Theme.accentRed : Theme.textSecondary
                                    font.family: Theme.fontFamily 
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Footer nav
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            spacing: Theme.spacingM
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back"
                onClicked: mpHistoryPage.backClicked()
            }
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                labelText: "Clear History"
                variant: "danger"
                onClicked: {
                    MultiplayerHistoryManager.clearHistory()
                }
            }
        }
    }
}
