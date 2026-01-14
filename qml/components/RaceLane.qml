/**
 * @file RaceLane.qml
 * @brief Lane balap individual dengan mobil animasi (menggunakan ikon SVG).
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen lane balap untuk visualisasi progress pemain dalam mode multiplayer.
 * Menggunakan desain kompak - satu baris per pemain dengan animasi halus.
 *
 * @par Struktur Visual:
 * ```
 * [Nama Pemain] ─────────────[🚗]──────────────────|
 *                            ↑                     ↑
 *                          Mobil              Garis Finish
 * ```
 *
 * @section features Fitur
 * - Animasi pergerakan mobil berdasarkan progress
 * - Indikator posisi finish
 * - Label WPM di atas mobil
 * - Mode kompak untuk layout dual-column
 *
 * @see RaceTrack Komponen parent yang menampilkan banyak lane
 */
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "."

/**
 * @brief Komponen lane balap individual untuk satu pemain.
 * @inherits Item
 *
 * @details Item ini merepresentasikan satu lane balap dengan
 * nama pemain, trek, mobil yang bergerak, dan label WPM.
 */
Item {
    id: raceLane
    height: 24

    /* ========================================================================
     * PROPERTI
     * ======================================================================== */

    /**
     * @property playerName
     * @brief Nama pemain yang ditampilkan di sisi kiri lane.
     * @type string
     * @default "Player"
     */
    property string playerName: "Player"

    /**
     * @property progress
     * @brief Progress pengetikan pemain (0.0 sampai 1.0).
     * @type real
     * @default 0.0
     *
     * @details Nilai 0.0 = belum mulai, 1.0 = selesai.
     * Mobil bergerak berdasarkan nilai ini.
     */
    property real progress: 0.0

    /**
     * @property wpm
     * @brief Words per minute pemain saat ini.
     * @type int
     * @default 0
     */
    property int wpm: 0

    /**
     * @property isLocal
     * @brief Apakah lane ini milik pemain lokal.
     * @type bool
     * @default false
     *
     * @details Jika true, nama dan mobil ditampilkan dengan warna biru.
     */
    property bool isLocal: false

    /**
     * @property finished
     * @brief Apakah pemain sudah selesai mengetik.
     * @type bool
     * @default false
     */
    property bool finished: false

    /**
     * @property position
     * @brief Posisi peringkat pemain (1, 2, 3, dst).
     * @type int
     * @default 0
     *
     * @details Ditampilkan sebagai prefix "#X" di depan nama jika finished.
     */
    property int position: 0

    /**
     * @property compactMode
     * @brief Mode kompak untuk layout dual-column.
     * @type bool
     * @default false
     *
     * @details Jika true, ukuran font dan lebar nama lebih kecil.
     */
    property bool compactMode: false

    /* ========================================================================
     * ELEMEN UI
     * ======================================================================== */

    /// @brief Garis trek horizontal (background)
    Rectangle {
        anchors.left: nameLabel.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        height: 2
        color: Theme.borderSecondary
    }

    /// @brief Penanda garis finish (vertikal hijau di ujung kanan)
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 16
        color: Theme.accentGreen
    }

    /**
     * @brief Label nama pemain di sisi kiri lane.
     *
     * @details Menampilkan prefix posisi "#X" jika pemain sudah selesai.
     * Warna biru untuk pemain lokal.
     */
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

    /**
     * @brief Mobil yang bergerak di sepanjang trek.
     *
     * @details Rectangle yang bergerak berdasarkan progress.
     * Warna berubah sesuai state:
     * - Biru: Pemain lokal
     * - Hijau: Sudah finish
     * - Abu: Sedang berlomba
     */
    Rectangle {
        id: car
        width: 20
        height: 14
        color: isLocal ? Theme.accentBlue : (finished ? Theme.accentGreen : Theme.textSecondary)

        /// @brief Posisi awal trek (setelah label nama)
        property real trackStart: nameLabel.width + 16
        /// @brief Posisi akhir trek
        property real trackEnd: parent.width - 8
        /// @brief Lebar total trek
        property real trackWidth: trackEnd - trackStart

        x: trackStart + trackWidth * Math.min(progress, 1.0)
        anchors.verticalCenter: parent.verticalCenter

        /// @brief Animasi pergerakan mobil yang halus
        Behavior on x {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        /// @brief Ikon panah di dalam mobil (saat belum selesai)
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

        /// @brief Ikon centang di dalam mobil (saat sudah selesai)
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

    /// @brief Label WPM yang muncul di atas mobil
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
