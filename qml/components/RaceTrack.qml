/**
 * @file RaceTrack.qml
 * @brief Visualisasi trek balap kompak yang menampilkan progress semua pemain.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Didesain agar tidak mengganggu saat mengetik - menggunakan ruang vertikal minimal.
 * Mendukung layout dua kolom untuk 6+ pemain agar semua pemain terlihat.
 *
 * @par Mode Layout:
 * - Single Column: 1-5 pemain ditampilkan dalam satu kolom
 * - Dual Column: 6+ pemain dibagi menjadi dua kolom
 *
 * @section features Fitur
 * - Layout adaptif (single column vs dual column)
 * - Header START/FINISH untuk setiap kolom
 * - Integrasi dengan komponen RaceLane
 * - Tinggi dinamis berdasarkan jumlah pemain
 *
 * @see RaceLane Komponen lane individual untuk setiap pemain
 */
import QtQuick
import QtQuick.Layouts
import "."

/**
 * @brief Komponen trek balap yang menampilkan semua lane pemain.
 * @inherits Rectangle
 *
 * @details Rectangle dengan border yang berisi layout kolom dinamis.
 * Tinggi dihitung otomatis berdasarkan jumlah pemain.
 */
Rectangle {
    id: raceTrack

    /* ========================================================================
     * PROPERTI
     * ======================================================================== */

    /**
     * @property players
     * @brief Array data pemain untuk ditampilkan.
     * @type var (Array)
     *
     * @details Setiap item harus berisi:
     * - id: ID unik pemain
     * - name: Nama pemain
     * - progress: Progress 0.0-1.0
     * - wpm: Words per minute
     * - isLocal: Apakah pemain lokal
     * - finished: Apakah sudah selesai
     * - position: Peringkat (1, 2, 3, dst)
     */
    property var players: []

    /**
     * @property useDualColumn
     * @brief Apakah menggunakan layout dua kolom.
     * @type bool
     * @readonly
     *
     * @details Otomatis true jika ada 6+ pemain.
     */
    property bool useDualColumn: players.length >= 6

    /**
     * @property leftPlayers
     * @brief Array pemain untuk kolom kiri.
     * @type var (Array)
     * @readonly
     */
    property var leftPlayers: {
        if (!useDualColumn)
            return players;
        var half = Math.ceil(players.length / 2);
        return players.slice(0, half);
    }

    /**
     * @property rightPlayers
     * @brief Array pemain untuk kolom kanan.
     * @type var (Array)
     * @readonly
     */
    property var rightPlayers: {
        if (!useDualColumn)
            return [];
        var half = Math.ceil(players.length / 2);
        return players.slice(half);
    }

    /**
     * @property lanesPerColumn
     * @brief Jumlah lane per kolom.
     * @type int
     * @readonly
     */
    property int lanesPerColumn: useDualColumn ? Math.ceil(players.length / 2) : players.length

    /**
     * @property trackHeight
     * @brief Tinggi trek yang dihitung berdasarkan jumlah lane.
     * @type int
     * @readonly
     *
     * @details Maksimum 150px untuk menjaga tampilan kompak.
     */
    property int trackHeight: Math.min(lanesPerColumn * 28 + 16, 150)

    /* ========================================================================
     * STYLING
     * ======================================================================== */

    implicitHeight: trackHeight
    color: Theme.bgSecondary
    border.color: Theme.borderPrimary
    border.width: 1

    /* ========================================================================
     * UI LAYOUT
     * ======================================================================== */

    /**
     * @brief Kontainer layout dua kolom.
     *
     * @details Row yang berisi kolom kiri (selalu terlihat)
     * dan kolom kanan (hanya terlihat dalam mode dual).
     */
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: useDualColumn ? 12 : 0

        /**
         * @brief Kolom kiri (atau satu-satunya kolom dalam mode single).
         *
         * @details Berisi header START/FINISH dan lane pemain.
         */
        Item {
            width: useDualColumn ? (parent.width - 12) / 2 : parent.width
            height: parent.height

            /// @brief Header trek dengan label START/FINISH
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

            /// @brief Container lane pemain - kolom kiri
            Column {
                anchors.top: leftHeader.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                /// @brief Repeater untuk membuat RaceLane untuk setiap pemain
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

        /**
         * @brief Kolom kanan (hanya terlihat dalam mode dual column).
         *
         * @details Struktur sama dengan kolom kiri.
         */
        Item {
            visible: useDualColumn
            width: useDualColumn ? (parent.width - 12) / 2 : 0
            height: parent.height

            /// @brief Header trek dengan label START/FINISH
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

            /// @brief Container lane pemain - kolom kanan
            Column {
                anchors.top: rightHeader.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                /// @brief Repeater untuk membuat RaceLane untuk setiap pemain
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

    /// @brief Teks state kosong saat tidak ada pemain
    Text {
        anchors.centerIn: parent
        visible: players.length === 0
        text: "Menunggu pemain..."
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSM
    }
}
