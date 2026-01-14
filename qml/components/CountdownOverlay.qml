/**
 * @file CountdownOverlay.qml
 * @brief Overlay countdown layar penuh (3, 2, 1, GO!)
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen overlay yang menampilkan animasi hitung mundur sebelum
 * gameplay dimulai. Menggunakan desain teks bersih tanpa emoji.
 *
 * @par Alur Countdown:
 * 1. Panggil start() untuk memulai countdown
 * 2. Timer menghitung mundur setiap 1 detik (3, 2, 1)
 * 3. Saat mencapai 0, ditampilkan "GO!"
 * 4. Signal finished() dipancarkan setelah selesai
 *
 * @section animation Animasi
 * - Animasi skala pulse pada teks countdown
 * - Progress dots yang menunjukkan tahap countdown
 * - Timer interval 1 detik untuk setiap tahap
 *
 * @see LobbyPage Halaman yang menggunakan overlay ini untuk multiplayer
 */
import QtQuick
import "."

/**
 * @brief Komponen overlay countdown layar penuh.
 * @inherits Rectangle
 *
 * @details Rectangle semi-transparan hitam yang menutupi seluruh layar
 * dan menampilkan animasi hitung mundur sebelum permainan dimulai.
 */
Rectangle {
    id: overlay
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.9)
    visible: false
    z: 1000

    /* ========================================================================
     * PROPERTI
     * ======================================================================== */

    /**
     * @property countdown
     * @brief Nilai countdown saat ini (3, 2, 1, 0).
     * @type int
     * @default 3
     *
     * @details Nilai 0 menampilkan "GO!" sebelum overlay ditutup.
     */
    property int countdown: 3

    /**
     * @property isActive
     * @brief Apakah countdown sedang berjalan.
     * @type bool
     * @default false
     */
    property bool isActive: false

    /* ========================================================================
     * SIGNAL
     * ======================================================================== */

    /**
     * @signal finished
     * @brief Dipancarkan ketika countdown selesai.
     *
     * @details Signal ini di-emit setelah "GO!" ditampilkan
     * dan overlay mulai menghilang.
     */
    signal finished

    /* ========================================================================
     * FUNGSI PUBLIK
     * ======================================================================== */

    /**
     * @brief Memulai countdown dari awal.
     *
     * @details Fungsi ini:
     * 1. Reset countdown ke 3
     * 2. Menampilkan overlay
     * 3. Mengaktifkan state isActive
     * 4. Memulai timer countdown
     */
    function start() {
        countdown = 3;
        visible = true;
        isActive = true;
        countdownTimer.start();
    }

    /**
     * @brief Menghentikan countdown secara paksa.
     *
     * @details Fungsi ini:
     * 1. Menghentikan timer
     * 2. Menyembunyikan overlay
     * 3. Menonaktifkan state isActive
     */
    function stop() {
        countdownTimer.stop();
        visible = false;
        isActive = false;
    }

    /* ========================================================================
     * TIMER
     * ======================================================================== */

    /**
     * @brief Timer untuk mengatur interval countdown.
     *
     * @details Timer berjalan setiap 1 detik dan mengurangi nilai countdown.
     * Saat countdown mencapai nilai negatif, overlay ditutup dan
     * signal finished dipancarkan.
     */
    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            countdown--;
            if (countdown < 0) {
                stop();
                overlay.visible = false;
                overlay.isActive = false;
                overlay.finished();
            }
        }
    }

    /* ========================================================================
     * UI LAYOUT
     * ======================================================================== */

    /**
     * @brief Container utama untuk elemen countdown.
     *
     * @details Column centered yang berisi:
     * - Teks angka countdown / "GO!"
     * - Subtitle "Get Ready!" / "Type!"
     * - Progress dots
     */
    Column {
        anchors.centerIn: parent
        spacing: 16

        /**
         * @brief Teks angka countdown utama.
         *
         * @details Menampilkan angka 3, 2, 1, atau "GO!" dengan
         * animasi pulse saat countdown aktif.
         */
        Text {
            id: countdownText
            anchors.horizontalCenter: parent.horizontalCenter
            text: countdown > 0 ? countdown.toString() : "GO!"
            color: countdown > 0 ? Theme.textPrimary : Theme.accentGreen
            font.family: Theme.fontFamily
            font.pixelSize: 140
            font.bold: true

            /// @brief Transform untuk animasi skala pulse
            transform: Scale {
                id: scaleTransform
                origin.x: countdownText.width / 2
                origin.y: countdownText.height / 2
                xScale: 1.0
                yScale: 1.0
            }

            /// @brief Animasi pulse skala untuk efek visual menarik
            SequentialAnimation {
                running: overlay.isActive
                loops: Animation.Infinite

                NumberAnimation {
                    target: scaleTransform
                    properties: "xScale,yScale"
                    to: 1.15
                    duration: 400
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: scaleTransform
                    properties: "xScale,yScale"
                    to: 1.0
                    duration: 400
                    easing.type: Easing.InQuad
                }
            }
        }

        /// @brief Subtitle yang berubah berdasarkan tahap countdown
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: countdown > 0 ? "Get Ready!" : "Type!"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXL
        }

        /**
         * @brief Progress dots yang menunjukkan tahap countdown.
         *
         * @details Tiga titik yang berubah warna menjadi hijau
         * seiring berjalannya countdown (3→2→1→GO).
         */
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: 3

                /// @brief Dot individual dengan animasi warna
                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: (3 - countdown) > index ? Theme.accentGreen : Theme.bgTertiary
                    border.color: Theme.borderSecondary
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }
        }
    }

    /// @brief MouseArea untuk menangkap klik (dinonaktifkan di produksi)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Dinonaktifkan di produksi
        }
    }
}
