/**
 * @file ResetHistoryPage.qml
 * @brief Halaman dialog konfirmasi untuk menghapus riwayat permainan singleplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan dialog konfirmasi sederhana
 * sebelum menghapus semua entri riwayat pertandingan singleplayer secara permanen.
 *
 * Berbeda dengan ResetMultiplayerHistoryPage, halaman ini tidak menggunakan
 * state machine karena proses penghapusan ditangani langsung oleh parent component.
 * Halaman ini hanya memancarkan signal dan parent yang bertanggung jawab
 * untuk memanggil HistoryManager.clearHistory().
 *
 * @warning Aksi penghapusan tidak dapat dibatalkan (irreversible).
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter/Return | Konfirmasi penghapusan |
 * | Escape | Batalkan dan kembali |
 *
 * @see HistoryManager Untuk logika penyimpanan riwayat singleplayer
 * @see HistoryPage Untuk halaman tampilan riwayat singleplayer
 * @see ResetMultiplayerHistoryPage Untuk versi multiplayer dengan state machine
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"

/**
 * @brief Komponen halaman konfirmasi reset riwayat Singleplayer.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk seluruh UI
 * konfirmasi penghapusan riwayat singleplayer. Menggunakan warna latar belakang
 * tema primer dan menangani input keyboard untuk navigasi.
 *
 * @par Alur Penggunaan:
 * 1. User membuka halaman ini dari menu pengaturan atau halaman riwayat
 * 2. Dialog konfirmasi ditampilkan dengan peringatan
 * 3. User memilih Confirm (Enter) atau Cancel (Escape)
 * 4. Jika Confirm: emit confirmClicked() → parent menghapus data
 * 5. Jika Cancel: emit cancelClicked() → parent menavigasi kembali
 *
 * @note Berbeda dengan ResetMultiplayerHistoryPage, halaman ini tidak
 * memiliki animasi processing/success karena penghapusan ditangani parent.
 */
Rectangle {
    id: resetHistoryPage
    color: Theme.bgPrimary
    focus: true

    /**
     * @signal confirmClicked
     * @brief Dipancarkan ketika pengguna mengkonfirmasi penghapusan.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Enter/Return
     * - User mengklik tombol Confirm
     *
     * Parent component harus menangani signal ini untuk:
     * 1. Memanggil HistoryManager.clearHistory()
     * 2. Menavigasi kembali ke halaman riwayat
     */
    signal confirmClicked

    /**
     * @signal cancelClicked
     * @brief Dipancarkan ketika pengguna membatalkan operasi.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Cancel
     *
     * Parent component harus menangani signal ini untuk navigasi kembali
     * tanpa melakukan perubahan apapun pada data.
     */
    signal cancelClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi cepat:
     * - Enter/Return: Konfirmasi penghapusan (emit confirmClicked())
     * - Escape: Batalkan operasi (emit cancelClicked())
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            confirmClicked();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            cancelClicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Container utama untuk UI konfirmasi.
     *
     * @details Item ini berisi seluruh komponen UI untuk dialog konfirmasi,
     * termasuk judul, kotak peringatan merah, dan tombol aksi.
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

        /**
         * @brief Layout kolom utama untuk konten konfirmasi.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Judul halaman ("CLEAR HISTORY")
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
             * @details Menampilkan teks "CLEAR HISTORY" dengan
             * styling display (bold, ukuran besar) dan warna tema primer.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CLEAR HISTORY"
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
                     * @details Menjelaskan bahwa semua riwayat game akan dihapus.
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "This will permanently delete all your game history."
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
                    onClicked: resetHistoryPage.cancelClicked()
                }

                /**
                 * @brief Tombol Confirm untuk mengkonfirmasi penghapusan.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: trash (tempat sampah)
                 * - Label: "Confirm (ENTER)"
                 * - Variant: "danger" (styling merah untuk aksi berbahaya)
                 * - Aksi: Emit signal confirmClicked()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                    labelText: "Confirm (ENTER)"
                    variant: "danger"
                    onClicked: resetHistoryPage.confirmClicked()
                }
            }
        }
    }
}
