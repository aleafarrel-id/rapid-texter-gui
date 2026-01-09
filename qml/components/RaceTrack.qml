/**
 * @file RaceTrack.qml
 * @brief Compact race track visualization showing all players' progress.
 *
 * Designed to be non-intrusive during typing - uses minimal vertical space.
 */
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: raceTrack

    // Array of {id, name, progress, wpm, isLocal, finished, position}
    property var players: []
    property int trackHeight: Math.min(players.length * 28 + 16, 150)

    implicitHeight: trackHeight
    color: Theme.bgSecondary
    border.color: Theme.borderPrimary
    border.width: 1

    // Track header with start/finish labels
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8

        Text {
            text: "START"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
        }

        Item {
            Layout.fillWidth: true
            width: parent.width - 80
        }

        Text {
            anchors.right: parent.right
            text: "FINISH"
            color: Theme.accentGreen
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
        }
    }

    // Player lanes
    Column {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 20
        spacing: 2

        Repeater {
            model: raceTrack.players

            delegate: RaceLane {
                width: parent.width
                height: 24
                playerName: modelData.name || "Player"
                progress: modelData.progress || 0
                wpm: modelData.wpm || 0
                isLocal: modelData.isLocal || false
                finished: modelData.finished || false
                position: modelData.position || 0
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
