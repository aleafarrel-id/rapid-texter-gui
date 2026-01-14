/**
 * @file ResetMultiplayerHistoryPage.qml
 * @brief Halaman dialog konfirmasi untuk menghapus riwayat permainan multiplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan dialog konfirmasi berbasis state-machine
 * sebelum menghapus semua entri riwayat pertandingan multiplayer secara permanen.
 *
 * Halaman ini menggunakan tiga state:
 * - "confirm": Menampilkan UI konfirmasi dengan tombol Cancel dan Confirm
 * - "processing": Menampilkan animasi loading saat proses penghapusan
 * - "success": Menampilkan pesan sukses sebelum kembali ke halaman sebelumnya
 *
 * @warning Aksi penghapusan tidak dapat dibatalkan (irreversible).
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter/Return | Konfirmasi penghapusan |
 * | Escape | Batalkan dan kembali |
 *
 * @see MultiplayerHistoryManager Untuk logika penyimpanan riwayat
 * @see MultiplayerHistoryPage Untuk halaman tampilan riwayat
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen halaman konfirmasi reset riwayat Multiplayer.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk seluruh UI
 * konfirmasi penghapusan riwayat. Menggunakan warna latar belakang tema primer
 * dan menangani input keyboard untuk navigasi.
 *
 * @par Alur Penggunaan:
 * 1. User membuka halaman ini dari menu pengaturan
 * 2. Dialog konfirmasi ditampilkan dengan peringatan
 * 3. User memilih Confirm (Enter) atau Cancel (Escape)
 * 4. Jika Confirm: animasi processing → success → emit cleared()
 * 5. Jika Cancel: emit cancelClicked()
 */
Rectangle {
    id: resetMpHistoryPage
    color: Theme.bgPrimary
    focus: true

    /**
     * @signal cancelClicked
     * @brief Dipancarkan ketika pengguna membatalkan operasi.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Cancel
     *
     * Parent component harus menangani signal ini untuk navigasi kembali.
     */
    signal cancelClicked

    /**
     * @signal cleared
     * @brief Dipancarkan ketika riwayat berhasil dihapus.
     *
     * @details Signal ini di-emit setelah:
     * 1. User mengkonfirmasi penghapusan
     * 2. MultiplayerHistoryManager.clearHistory() dipanggil
     * 3. Animasi processing selesai (500ms)
     * 4. Animasi success selesai (1000ms)
     *
     * Parent component harus menangani signal ini untuk navigasi kembali
     * ke halaman riwayat yang sudah kosong.
     */
    signal cleared

    /**
     * @property pageState
     * @brief State machine untuk mengontrol tampilan UI.
     * @type string
     * @default "confirm"
     *
     * @details Nilai yang valid:
     * - "confirm": Menampilkan UI konfirmasi (state awal)
     * - "processing": Menampilkan spinner loading
     * - "success": Menampilkan pesan sukses dengan checkmark
     *
     * Transisi state:
     * @code
     * confirm → (user konfirmasi) → processing → (500ms) → success → (1000ms) → emit cleared()
     * confirm → (user cancel) → emit cancelClicked()
     * @endcode
     */
    property string pageState: "confirm" // "confirm", "processing", "success"

    /**
     * @brief Timer untuk delay proses penghapusan.
     *
     * @details Timer ini memberikan jeda 500ms setelah proses penghapusan
     * dimulai sebelum menampilkan pesan sukses. Interval ini dipilih untuk
     * memberikan feedback visual yang cukup kepada user bahwa ada proses
     * yang sedang berjalan (mirip dengan behavior TUI version).
     *
     * @par Behavior:
     * - Interval: 500 milidetik
     * - One-shot: Tidak berulang (repeat: false)
     * - Trigger: Mengubah state ke "success" dan memulai rpSuccessTimer
     */
    Timer {
        id: rpProcessingTimer
        interval: 500
        repeat: false
        onTriggered: {
            resetMpHistoryPage.pageState = "success";
            rpSuccessTimer.start();
        }
    }

    /**
     * @brief Timer untuk durasi tampilan pesan sukses.
     *
     * @details Timer ini memberikan jeda 1 detik untuk menampilkan
     * pesan sukses sebelum memancarkan signal cleared() dan kembali
     * ke halaman sebelumnya.
     *
     * @par Behavior:
     * - Interval: 1000 milidetik (1 detik)
     * - One-shot: Tidak berulang (repeat: false)
     * - Trigger: Memancarkan signal cleared()
     */
    Timer {
        id: rpSuccessTimer
        interval: 1000
        repeat: false
        onTriggered: {
            resetMpHistoryPage.cleared();
        }
    }

    /**
     * @brief Memulai proses penghapusan riwayat.
     *
     * @details Fungsi ini dipanggil ketika user mengkonfirmasi penghapusan,
     * baik melalui keyboard (Enter/Return) atau klik tombol Confirm.
     *
     * Urutan eksekusi:
     * 1. Mengubah pageState ke "processing" untuk menampilkan spinner
     * 2. Memanggil MultiplayerHistoryManager.clearHistory() untuk menghapus data
     * 3. Memulai rpProcessingTimer untuk transisi ke state success
     *
     * @note Fungsi ini tidak memiliki return value karena hasilnya
     * dikomunikasikan melalui perubahan state dan signal.
     */
    function startProcessing() {
        pageState = "processing";
        MultiplayerHistoryManager.clearHistory();
        rpProcessingTimer.start();
    }

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi cepat:
     * - Enter/Return: Konfirmasi penghapusan (memanggil startProcessing())
     * - Escape: Batalkan operasi (emit cancelClicked())
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     *
     * @note Input keyboard dinonaktifkan saat pageState bukan "confirm"
     * untuk mencegah aksi ganda selama proses atau tampilan sukses.
     */
    Keys.onPressed: function (event) {
        // Nonaktifkan input keyboard saat processing/success
        if (pageState !== "confirm") {
            event.accepted = true;
            return;
        }

        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            startProcessing();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            cancelClicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Container untuk UI konfirmasi.
     *
     * @details Item ini berisi seluruh komponen UI untuk state "confirm",
     * termasuk judul, kotak peringatan merah, dan tombol aksi.
     *
     * Visibility dikontrol oleh pageState - hanya visible saat
     * pageState === "confirm". Transisi visibility menggunakan
     * animasi opacity untuk efek fade yang halus.
     *
     * @par Layout:
     * - Centered di parent
     * - Lebar maksimum: Theme.maxContentWidth
     * - Padding horizontal: Theme.paddingHuge * 2
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: rhCol.implicitHeight
        visible: resetMpHistoryPage.pageState === "confirm"
        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        /**
         * @brief Layout kolom utama untuk konten konfirmasi.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Judul halaman ("CLEAR MULTIPLAYER HISTORY")
         * 2. Kotak peringatan merah dengan pesan konfirmasi
         * 3. Tombol aksi (Cancel dan Confirm)
         *
         * @par Properti Layout:
         * - Spacing: 0 (spacing dikontrol per-elemen via margin)
         * - Fill: Mengisi seluruh parent Item
         */
        ColumnLayout {
            id: rhCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Judul halaman konfirmasi.
             *
             * @details Menampilkan teks "CLEAR MULTIPLAYER HISTORY" dengan
             * styling display (bold, ukuran besar) dan warna tema primer.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CLEAR MULTIPLAYER HISTORY"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Kotak peringatan dengan border merah.
             *
             * @details Rectangle ini berisi pesan konfirmasi dan peringatan.
             * Menggunakan warna Theme.dangerBg sebagai background dan
             * Theme.accentRed sebagai border untuk memberikan visual
             * "danger zone" yang jelas kepada user.
             *
             * @par Visual Elements:
             * - Background: Theme.dangerBg (merah transparan)
             * - Border: 1px Theme.accentRed
             * - Accent bar: 3px merah di sisi kiri
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: rhConfirmCol.implicitHeight + 60
                color: Theme.dangerBg
                border.width: 1
                border.color: Theme.accentRed

                /**
                 * @brief Accent bar merah di sisi kiri kotak peringatan.
                 *
                 * @details Memberikan visual emphasis seperti alert/callout
                 * yang umum digunakan di design system modern.
                 */
                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.accentRed
                }

                /**
                 * @brief Container untuk konten pesan konfirmasi.
                 *
                 * @details Column ini berisi tiga elemen:
                 * 1. Pertanyaan konfirmasi ("Are you sure?")
                 * 2. Deskripsi aksi yang akan dilakukan
                 * 3. Peringatan dengan ikon ("This action cannot be undone")
                 */
                Column {
                    id: rhConfirmCol
                    anchors.centerIn: parent
                    spacing: Theme.spacingL

                    /**
                     * @brief Teks pertanyaan konfirmasi utama.
                     * @details Ditampilkan dengan warna merah untuk emphasis.
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Are you sure?"
                        color: Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }

                    /**
                     * @brief Deskripsi detail tentang aksi yang akan dilakukan.
                     * @details Menjelaskan bahwa semua riwayat multiplayer akan dihapus.
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "This will permanently delete all your multiplayer match history."
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeL
                    }

                    /**
                     * @brief Baris peringatan dengan ikon warning.
                     *
                     * @details Menampilkan ikon segitiga peringatan kuning
                     * diikuti teks "This action cannot be undone" untuk
                     * memberikan peringatan final kepada user.
                     */
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingS

                        /**
                         * @brief Container untuk ikon warning.
                         *
                         * @details Menggunakan pattern Image + ColorOverlay
                         * untuk menampilkan ikon SVG dengan warna yang dapat
                         * dikustomisasi sesuai tema.
                         */
                        Item {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter

                            /// @brief Source image untuk ikon warning (hidden)
                            Image {
                                id: warningIcon
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                                anchors.fill: parent
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }

                            /// @brief Overlay warna kuning untuk ikon warning
                            ColorOverlay {
                                anchors.fill: warningIcon
                                source: warningIcon
                                color: Theme.accentYellow
                            }
                        }

                        /**
                         * @brief Teks peringatan irreversible action.
                         * @details Ditampilkan dengan warna kuning untuk attention.
                         */
                        Text {
                            text: "This action cannot be undone"
                            color: Theme.accentYellow
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }
                }
            }

            /**
             * @brief Container untuk tombol aksi.
             *
             * @details Row ini berisi dua tombol navigasi:
             * - Cancel: Membatalkan operasi dan kembali
             * - Confirm: Mengkonfirmasi penghapusan
             *
             * @par Layout:
             * - Alignment: Center horizontal
             * - Top margin: 30px dari kotak peringatan
             * - Spacing: Theme.spacingM antar tombol
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingM

                /**
                 * @brief Tombol Cancel untuk membatalkan operasi.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: arrow-left (panah kiri)
                 * - Label: "Cancel (ESC)"
                 * - Aksi: Emit signal cancelClicked()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Cancel (ESC)"
                    onClicked: resetMpHistoryPage.cancelClicked()
                }

                /**
                 * @brief Tombol Confirm untuk mengkonfirmasi penghapusan.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: trash (tempat sampah)
                 * - Label: "Confirm (ENTER)"
                 * - Variant: "danger" (styling merah untuk aksi berbahaya)
                 * - Aksi: Memanggil startProcessing()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                    labelText: "Confirm (ENTER)"
                    variant: "danger"
                    onClicked: resetMpHistoryPage.startProcessing()
                }
            }
        }
    }

    /**
     * @brief Overlay tampilan saat proses penghapusan berjalan.
     *
     * @details Item ini menampilkan animasi loading spinner dan teks
     * "Clearing history..." saat pageState === "processing".
     *
     * @par Visual Elements:
     * - Spinner: Ikon refresh yang berputar 360° per detik
     * - Teks: "Clearing history..." dengan warna kuning
     *
     * @par Animasi:
     * - Fade in/out opacity dengan durasi 200ms
     * - Rotasi spinner infinite loop selama processing
     */
    Item {
        anchors.centerIn: parent
        visible: resetMpHistoryPage.pageState === "processing"
        opacity: visible ? 1 : 0

        /// @brief Animasi transisi opacity untuk efek fade
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        /**
         * @brief Layout kolom untuk konten processing.
         * @details Menyusun spinner dan teks secara vertikal.
         */
        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingXL

            /**
             * @brief Container untuk spinner loading.
             *
             * @details Menampilkan ikon refresh yang berputar dengan
             * animasi rotasi 360° setiap 1 detik.
             *
             * @par Ukuran: 48x48 pixel
             * @par Warna: Theme.accentYellow
             */
            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                /// @brief Source image untuk spinner (hidden)
                Image {
                    id: rpLoaderIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }

                /**
                 * @brief Overlay warna dan animasi rotasi untuk spinner.
                 *
                 * @details ColorOverlay memberikan warna kuning pada ikon,
                 * sementara RotationAnimation memberikan efek berputar.
                 *
                 * @par Animasi Rotasi:
                 * - Range: 0° → 360°
                 * - Durasi: 1000ms per putaran
                 * - Loop: Infinite (selama processing aktif)
                 */
                ColorOverlay {
                    id: rpLoaderOverlay
                    anchors.fill: rpLoaderIcon
                    source: rpLoaderIcon
                    color: Theme.accentYellow

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: resetMpHistoryPage.pageState === "processing"
                    }
                }
            }

            /**
             * @brief Teks status proses penghapusan.
             * @details Menampilkan "Clearing history..." dengan styling bold.
             */
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Clearing history..."
                color: Theme.accentYellow
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                font.bold: true
            }
        }
    }

    /**
     * @brief Overlay tampilan sukses setelah penghapusan selesai.
     *
     * @details Item ini menampilkan ikon checkmark dengan efek glow
     * dan teks "History cleared successfully!" saat pageState === "success".
     *
     * @par Visual Elements:
     * - Checkmark: Ikon check berwarna hijau
     * - Glow: Lingkaran hijau transparan dengan animasi pulse
     * - Teks: Pesan sukses dengan warna hijau
     *
     * @par Animasi:
     * - Fade in opacity dengan durasi 200ms
     * - Pulse glow dengan scale 1.0 → 1.2 → 1.0 (infinite loop)
     *
     * @note Overlay ini tampil selama 1 detik sebelum navigasi keluar
     */
    Item {
        anchors.centerIn: parent
        visible: resetMpHistoryPage.pageState === "success"
        opacity: visible ? 1 : 0

        /// @brief Animasi transisi opacity untuk efek fade
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        /**
         * @brief Layout kolom untuk konten sukses.
         * @details Menyusun ikon checkmark dan teks secara vertikal.
         */
        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingXL

            /**
             * @brief Container untuk ikon checkmark dengan efek glow.
             *
             * @details Menampilkan ikon check dengan lingkaran glow
             * yang memiliki animasi pulse (membesar-mengecil).
             *
             * @par Ukuran: 48x48 pixel (ikon), 64x64 pixel (glow)
             * @par Warna: Theme.accentGreen
             */
            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                /**
                 * @brief Efek glow berupa lingkaran hijau transparan.
                 *
                 * @details Rectangle bulat (radius 32) dengan animasi
                 * scale pulse untuk memberikan visual feedback sukses
                 * yang menarik perhatian.
                 *
                 * @par Animasi SequentialAnimation:
                 * 1. Scale 1.0 → 1.2 (500ms, OutQuad easing)
                 * 2. Scale 1.2 → 1.0 (500ms, InQuad easing)
                 * 3. Loop infinite selama success state aktif
                 */
                Rectangle {
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    radius: 32
                    color: Theme.accentGreen
                    opacity: 0.2

                    SequentialAnimation on scale {
                        running: resetMpHistoryPage.pageState === "success"
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 1.2
                            duration: 500
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 500
                            easing.type: Easing.InQuad
                        }
                    }
                }

                /// @brief Source image untuk ikon checkmark (hidden)
                Image {
                    id: rpSuccessIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }

                /// @brief Overlay warna hijau untuk ikon checkmark
                ColorOverlay {
                    anchors.fill: rpSuccessIcon
                    source: rpSuccessIcon
                    color: Theme.accentGreen
                }
            }

            /**
             * @brief Teks pesan sukses.
             * @details Menampilkan "History cleared successfully!" dengan styling bold hijau.
             */
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "History cleared successfully!"
                color: Theme.accentGreen
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                font.bold: true
            }
        }
    }
}
