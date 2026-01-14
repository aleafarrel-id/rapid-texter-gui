/**
 * @file RaceTrack.qml
 * @brief Visualisasi trek balap kompak yang menampilkan progress semua pemain.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Didesain agar tidak mengganggu saat mengetik - menggunakan ruang vertikal minimal.
 * Mendukung layout dua kolom untuk 6+ pemain agar semua pemain terlihat.
 *
 * @section features Fitur
 * - Layout adaptif (single column vs dual column)
 * - Header START/FINISH untuk setiap kolom
 * - Integrasi dengan komponen RaceLane
 */
import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: raceTrack

    // Array {id, name, progress, wpm, isLocal, finished, position}
    property var players: []

    // Mode dual column untuk 6+ pemain
    property bool useDualColumn: players.length >= 6

    // Membagi pemain menjadi kolom kiri dan kanan
    property var leftPlayers: {
        if (!useDualColumn)
            return players;
        var half = Math.ceil(players.length / 2);
        return players.slice(0, half);
    }
    property var rightPlayers: {
        if (!useDualColumn)
            return [];
        var half = Math.ceil(players.length / 2);
        return players.slice(half);
    }

    // Menghitung tinggi berdasarkan lane per kolom
    property int lanesPerColumn: useDualColumn ? Math.ceil(players.length / 2) : players.length
    property int trackHeight: Math.min(lanesPerColumn * 28 + 16, 150)

    implicitHeight: trackHeight
    color: Theme.bgSecondary
    border.color: Theme.borderPrimary
    border.width: 1

    // Kontainer layout dua kolom
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: useDualColumn ? 12 : 0

        // Kolom kiri (atau satu-satunya kolom dalam mode single)
        Item {
            width: useDualColumn ? (parent.width - 12) / 2 : parent.width
            height: parent.height

            // Header trek dengan label start/finish
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

            // Lane pemain - kolom kiri
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

        // Kolom kanan (hanya terlihat dalam mode dual column)
        Item {
            visible: useDualColumn
            width: useDualColumn ? (parent.width - 12) / 2 : 0
            height: parent.height

            // Header trek dengan label start/finish
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

            // Lane pemain - kolom kanan
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

    // State kosong
    Text {
        anchors.centerIn: parent
        visible: players.length === 0
        text: "Menunggu pemain..."
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSM
    }
}
