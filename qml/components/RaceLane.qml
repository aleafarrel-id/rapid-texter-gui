/**
 * @file RaceLane.qml
 * @brief Lane balap individual dengan mobil animasi (menggunakan ikon SVG).
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen lane balap untuk visualisasi progress pemain dalam mode multiplayer.
 * Menggunakan desain kompak - satu baris per pemain dengan animasi halus.
 *
 * @section features Fitur
 * - Animasi pergerakan mobil berdasarkan progress
 * - Indikator posisi finish
 * - Label WPM di atas mobil
 * - Mode kompak untuk layout dual-column
 */
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "."

Item {
    id: raceLane
    height: 24

    property string playerName: "Player"
    property real progress: 0.0  // 0.0 sampai 1.0
    property int wpm: 0
    property bool isLocal: false
    property bool finished: false
    property int position: 0
    property bool compactMode: false  // Ukuran lebih kecil untuk layout dual-column

    // Garis trek (background)
    Rectangle {
        anchors.left: nameLabel.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        height: 2
        color: Theme.borderSecondary
    }

    // Penanda garis finish
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 16
        color: Theme.accentGreen
    }

    // Nama pemain (sisi kiri)
    Text {
        id: nameLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: compactMode ? 60 : 80
        text: {
            let prefix = "";
            if (finished && position > 0) {
                prefix = "#" + position + " ";
            }
            return prefix + playerName;
        }
        color: isLocal ? Theme.accentBlue : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: compactMode ? 10 : 11
        font.bold: isLocal
        elide: Text.ElideRight
    }

    // Mobil (animasi menggunakan ikon)
    Rectangle {
        id: car
        width: 20
        height: 14
        color: isLocal ? Theme.accentBlue : (finished ? Theme.accentGreen : Theme.textSecondary)

        // Perhitungan posisi
        property real trackStart: nameLabel.width + 16
        property real trackEnd: parent.width - 8
        property real trackWidth: trackEnd - trackStart

        x: trackStart + trackWidth * Math.min(progress, 1.0)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on x {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        // Ikon panah di dalam mobil (indikator arah)
        Item {
            anchors.centerIn: parent
            width: 10
            height: 10
            visible: !finished

            Image {
                id: arrowIcon
                anchors.fill: parent
                source: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                sourceSize: Qt.size(10, 10)
                visible: false
            }
            ColorOverlay {
                anchors.fill: arrowIcon
                source: arrowIcon
                color: "white"
            }
        }

        // Ikon centang saat selesai
        Item {
            anchors.centerIn: parent
            width: 10
            height: 10
            visible: finished

            Image {
                id: checkIcon
                anchors.fill: parent
                source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                sourceSize: Qt.size(10, 10)
                visible: false
            }
            ColorOverlay {
                anchors.fill: checkIcon
                source: checkIcon
                color: "white"
            }
        }
    }

    // Label WPM (di atas mobil)
    Text {
        anchors.bottom: car.top
        anchors.bottomMargin: 1
        anchors.horizontalCenter: car.horizontalCenter
        text: wpm > 0 ? wpm + "" : ""
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 8
        font.bold: true
        visible: wpm > 0
    }
}
