/**
 * @file RaceTrack.qml
 * @brief Compact race track visualization showing all players' progress.
 *
 * Designed to be non-intrusive during typing - uses minimal vertical space.
 * Supports two-column layout for 6+ players to ensure all players are visible.
 */
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: raceTrack

    // Array of {id, name, progress, wpm, isLocal, finished, position}
    property var players: []
    
    // Dual column mode for 6+ players
    property bool useDualColumn: players.length >= 6
    
    // Split players into left and right columns
    property var leftPlayers: {
        if (!useDualColumn) return players;
        var half = Math.ceil(players.length / 2);
        return players.slice(0, half);
    }
    property var rightPlayers: {
        if (!useDualColumn) return [];
        var half = Math.ceil(players.length / 2);
        return players.slice(half);
    }
    
    // Calculate height based on lanes per column
    property int lanesPerColumn: useDualColumn ? 
        Math.ceil(players.length / 2) : players.length
    property int trackHeight: Math.min(lanesPerColumn * 28 + 16, 150)

    implicitHeight: trackHeight
    color: Theme.bgSecondary
    border.color: Theme.borderPrimary
    border.width: 1

    // Two-column layout container
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: useDualColumn ? 12 : 0

        // Left column (or only column in single mode)
        Item {
            width: useDualColumn ? (parent.width - 12) / 2 : parent.width
            height: parent.height

            // Track header with start/finish labels
            Row {
                id: leftHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    text: "START"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }

                Item {
                    width: parent.width - 80
                    height: 1
                }

                Text {
                    text: "FINISH"
                    color: Theme.accentGreen
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            // Player lanes - left column
            Column {
                anchors.top: leftHeader.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                Repeater {
                    model: raceTrack.leftPlayers

                    delegate: RaceLane {
                        width: parent.width
                        height: 24
                        playerName: modelData.name || "Player"
                        progress: modelData.progress || 0
                        wpm: modelData.wpm || 0
                        isLocal: modelData.isLocal || false
                        finished: modelData.finished || false
                        position: modelData.position || 0
                        compactMode: raceTrack.useDualColumn
                    }
                }
            }
        }

        // Right column (only visible in dual column mode)
        Item {
            visible: useDualColumn
            width: useDualColumn ? (parent.width - 12) / 2 : 0
            height: parent.height

            // Track header with start/finish labels
            Row {
                id: rightHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    text: "START"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }

                Item {
                    width: parent.width - 80
                    height: 1
                }

                Text {
                    text: "FINISH"
                    color: Theme.accentGreen
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            // Player lanes - right column
            Column {
                anchors.top: rightHeader.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                Repeater {
                    model: raceTrack.rightPlayers

                    delegate: RaceLane {
                        width: parent.width
                        height: 24
                        playerName: modelData.name || "Player"
                        progress: modelData.progress || 0
                        wpm: modelData.wpm || 0
                        isLocal: modelData.isLocal || false
                        finished: modelData.finished || false
                        position: modelData.position || 0
                        compactMode: raceTrack.useDualColumn
                    }
                }
            }
        }
    }

    // Empty state
    Text {
        anchors.centerIn: parent
        visible: players.length === 0
        text: "Waiting for players..."
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSM
    }
}
