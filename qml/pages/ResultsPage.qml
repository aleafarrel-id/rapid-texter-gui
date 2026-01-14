/**
 * @file ResultsPage.qml
 * @brief Halaman tampilan hasil permainan dengan metrik performa.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan hasil tes mengetik setelah sesi
 * permainan selesai. Halaman ini menunjukkan berbagai statistik performa
 * dan status pass/fail untuk mode campaign.
 *
 * @par Metrik yang Ditampilkan:
 * - WPM (Words Per Minute): Kecepatan mengetik utama
 * - Accuracy: Persentase akurasi (0-100%)
 * - Time: Waktu yang dihabiskan untuk menyelesaikan
 * - Errors: Jumlah kesalahan ketik
 *
 * @par Status Pass/Fail:
 * Untuk mode campaign, halaman ini juga menampilkan apakah user
 * berhasil memenuhi persyaratan level (WPM minimum, akurasi minimum, dll.).
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter/Return | Lanjutkan ke halaman berikutnya |
 * | H | Buka halaman riwayat |
 *
 * @see GamePage Halaman permainan yang menghasilkan data ini
 * @see HistoryPage Halaman riwayat yang dapat diakses dari sini
 * @see GameBackend Untuk kalkulasi statistik
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman hasil permainan.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk seluruh UI
 * hasil permainan. Menampilkan statistik performa dalam layout yang
 * terstruktur dengan visual feedback berdasarkan status pass/fail.
 *
 * @par Alur Penggunaan:
 * 1. Parent component mengatur properti (wpm, accuracy, dll.) sebelum menampilkan
 * 2. Halaman menampilkan statistik dengan styling berdasarkan hasil
 * 3. User dapat lanjut (Enter) atau lihat riwayat (H)
 * 4. Signal yang sesuai akan di-emit ke parent
 */
Rectangle {
    id: resultsPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * PROPERTI DATA HASIL
     * ======================================================================== */

    /**
     * @property wpm
     * @brief Words per minute yang dicapai dalam sesi permainan.
     * @type int
     * @default 84
     *
     * @details Nilai ini dihitung oleh GameBackend berdasarkan:
     * - Jumlah kata yang berhasil diketik
     * - Waktu total sesi permainan
     * - Formula: (total karakter / 5) / menit
     */
    property int wpm: 84

    /**
     * @property accuracy
     * @brief Persentase akurasi mengetik (0-100).
     * @type int
     * @default 99
     *
     * @details Dihitung dari rasio karakter benar vs total karakter yang diketik.
     * Formula: (karakter benar / total karakter) * 100
     */
    property int accuracy: 99

    /**
     * @property timeElapsed
     * @brief Waktu yang dihabiskan untuk menyelesaikan sesi (format string).
     * @type string
     * @default "15.0s"
     *
     * @details Format waktu ditentukan oleh GameBackend, biasanya dalam
     * format "X.Xs" untuk detik dengan satu desimal.
     */
    property string timeElapsed: "15.0s"

    /**
     * @property errors
     * @brief Jumlah kesalahan ketik selama sesi.
     * @type int
     * @default 1
     *
     * @details Setiap karakter yang salah saat pertama kali diketik
     * dihitung sebagai satu error.
     */
    property int errors: 1

    /**
     * @property passed
     * @brief Status apakah persyaratan level terpenuhi.
     * @type bool
     * @default true
     *
     * @details Untuk mode campaign, ini menentukan apakah user berhasil
     * memenuhi persyaratan minimum level (WPM, accuracy, dll.).
     * Mempengaruhi visual styling (hijau untuk pass, merah untuk fail).
     */
    property bool passed: true

    /**
     * @property passMessage
     * @brief Header pesan pass/fail yang ditampilkan.
     * @type string
     * @default "LEVEL PASSED!"
     *
     * @details Pesan ini bisa dikustomisasi oleh parent component untuk
     * berbagai konteks (campaign, practice, multiplayer, dll.).
     */
    property string passMessage: "LEVEL PASSED!"

    /**
     * @property passDescription
     * @brief Deskripsi detail untuk pesan pass/fail.
     * @type string
     * @default "Great job! You've achieved the requirements."
     *
     * @details Memberikan konteks tambahan tentang pencapaian user.
     */
    property string passDescription: "Great job! You've achieved the requirements."

    /**
     * @signal continueClicked
     * @brief Dipancarkan ketika user ingin melanjutkan.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Enter/Return
     * - User mengklik tombol Continue
     *
     * Parent component harus menangani signal ini untuk navigasi
     * ke halaman berikutnya (menu, level selanjutnya, dll.).
     */
    signal continueClicked

    /**
     * @signal historyClicked
     * @brief Dipancarkan ketika user ingin melihat riwayat.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol H
     * - User mengklik tombol History
     *
     * Parent component harus menangani signal ini untuk navigasi
     * ke halaman HistoryPage.
     */
    signal historyClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi:
     * - Enter/Return: Lanjutkan (emit continueClicked())
     * - H: Lihat riwayat (emit historyClicked())
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            continueClicked();
            event.accepted = true;
            break;
        case Qt.Key_H:
            historyClicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Container utama untuk UI hasil.
     *
     * @details Item ini berisi seluruh komponen UI untuk tampilan hasil,
     * termasuk judul, kartu WPM, statistik, pesan pass, dan tombol navigasi.
     *
     * @par Layout:
     * - Centered di parent
     * - Lebar maksimum: Theme.maxContentWidth
     * - Padding horizontal: Theme.paddingHuge * 2
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: resCol.implicitHeight

        /**
         * @brief Layout kolom utama untuk konten hasil.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Judul halaman ("RESULTS")
         * 2. Kartu WPM utama dengan highlight hijau/merah
         * 3. Baris statistik (Accuracy, Time, Errors)
         * 4. Pesan pass/fail (jika passed)
         * 5. Tombol navigasi (Continue, History)
         *
         * @par Properti Layout:
         * - Spacing: 0 (spacing dikontrol per-elemen via margin)
         * - Fill: Mengisi seluruh parent Item
         */
        ColumnLayout {
            id: resCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Judul halaman hasil.
             *
             * @details Menampilkan teks "RESULTS" dengan
             * styling display (bold, ukuran besar) dan warna tema primer.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "RESULTS"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Kartu tampilan WPM utama.
             *
             * @details Rectangle ini menampilkan skor WPM sebagai metrik utama
             * dengan ukuran font besar. Warna background dan teks berubah
             * berdasarkan status pass/fail:
             * - Pass: Background hijau, teks hijau
             * - Fail: Background transparan, teks putih
             *
             * @par Visual Elements:
             * - Height: 100px tetap
             * - Accent bar: 3px di sisi kiri (hijau/merah)
             * - Font size: 48px untuk WPM value
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: resultsPage.passed ? Theme.successBg : "transparent"
                border.width: 1
                border.color: Theme.borderPrimary

                /// @brief Accent bar dinamis (hijau jika pass, merah jika fail)
                Rectangle {
                    width: 3
                    height: parent.height
                    color: resultsPage.passed ? Theme.accentGreen : Theme.accentRed
                }

                /**
                 * @brief Teks nilai WPM dengan format "XX WPM".
                 * @details Warna berubah berdasarkan status pass/fail.
                 */
                Text {
                    anchors.centerIn: parent
                    text: resultsPage.wpm + " WPM"
                    color: resultsPage.passed ? Theme.accentGreen : Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 48
                    font.bold: true
                }
            }

            /**
             * @brief Baris kartu statistik sekunder.
             *
             * @details RowLayout ini menampilkan tiga kartu statistik
             * dalam satu baris horizontal:
             * 1. ACCURACY: Persentase akurasi
             * 2. TIME: Waktu yang dihabiskan
             * 3. ERRORS: Jumlah kesalahan
             *
             * @par Layout:
             * - Fill width dengan spacing Theme.spacingL
             * - Top margin: Theme.spacingL dari kartu WPM
             */
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingL
                spacing: Theme.spacingL

                /**
                 * @brief Repeater untuk membuat kartu statistik.
                 *
                 * @details Menggunakan model array untuk membuat tiga kartu
                 * statistik dengan struktur yang sama tapi nilai berbeda.
                 * Setiap kartu memiliki label di atas dan nilai di bawah.
                 *
                 * @par Model Structure:
                 * - label: Nama statistik (ACCURACY, TIME, ERRORS)
                 * - value: Nilai statistik (dengan format)
                 * - color: Warna untuk nilai (errors menggunakan merah)
                 */
                Repeater {
                    model: [
                        {
                            label: "ACCURACY",
                            value: resultsPage.accuracy + "%",
                            color: Theme.textPrimary
                        },
                        {
                            label: "TIME",
                            value: resultsPage.timeElapsed,
                            color: Theme.textPrimary
                        },
                        {
                            label: "ERRORS",
                            value: resultsPage.errors.toString(),
                            color: Theme.accentRed
                        }
                    ]

                    /**
                     * @brief Template kartu statistik individual.
                     *
                     * @details Setiap kartu menampilkan satu metrik dengan
                     * layout vertikal: label kecil di atas, nilai besar di bawah.
                     *
                     * @par Visual Elements:
                     * - Height: 80px tetap
                     * - Accent bar: 3px abu-abu di sisi kiri
                     * - Background: Transparan dengan border
                     */
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.borderPrimary

                        /// @brief Accent bar abu-abu untuk kartu statistik
                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.borderSecondary
                        }

                        /**
                         * @brief Konten kartu dengan label dan nilai.
                         */
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            /// @brief Label statistik (ACCURACY, TIME, ERRORS)
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeS
                                font.letterSpacing: 1
                            }

                            /// @brief Nilai statistik dengan warna dinamis
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: modelData.color
                                font.family: Theme.fontFamily
                                font.pixelSize: 32
                                font.bold: true
                            }
                        }
                    }
                }
            }

            /**
             * @brief Kartu pesan pass/fail.
             *
             * @details Rectangle ini menampilkan pesan sukses ketika
             * user berhasil memenuhi persyaratan level. Hanya visible
             * ketika passed === true.
             *
             * @par Visual Elements:
             * - Background: Theme.successBg (hijau transparan)
             * - Border: 1px Theme.accentGreen
             * - Accent bar: 3px hijau di sisi kiri
             * - Checkmark: "✓" prefix pada pesan
             *
             * @note Kartu ini hanya ditampilkan untuk status pass.
             * Untuk status fail, tidak ada kartu pesan yang ditampilkan.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.preferredHeight: passCol.implicitHeight + 30
                color: resultsPage.passed ? Theme.successBg : "transparent"
                border.width: 1
                border.color: resultsPage.passed ? Theme.accentGreen : Theme.borderPrimary
                visible: resultsPage.passed

                /// @brief Accent bar hijau untuk pesan sukses
                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.accentGreen
                }

                /**
                 * @brief Konten pesan pass dengan header dan deskripsi.
                 */
                Column {
                    id: passCol
                    anchors.centerIn: parent
                    spacing: 6

                    /**
                     * @brief Header pesan sukses dengan checkmark.
                     * @details Format: "✓ LEVEL PASSED!" atau pesan kustom.
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "✓ " + resultsPage.passMessage
                        color: Theme.accentGreen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                    }

                    /**
                     * @brief Deskripsi detail pencapaian.
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: resultsPage.passDescription
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                }
            }

            /**
             * @brief Container untuk tombol navigasi.
             *
             * @details Row ini berisi dua tombol navigasi:
             * - Continue: Lanjut ke halaman berikutnya
             * - History: Lihat riwayat permainan
             *
             * @par Layout:
             * - Alignment: Center horizontal
             * - Top margin: 30px dari konten di atas
             * - Spacing: Theme.spacingM antar tombol
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingM

                /**
                 * @brief Tombol Continue untuk melanjutkan.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: arrow-right (panah kanan)
                 * - Label: "Continue (ENTER)"
                 * - Variant: "primary" (styling utama/biru)
                 * - Aksi: Emit signal continueClicked()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                    labelText: "Continue (ENTER)"
                    variant: "primary"
                    onClicked: resultsPage.continueClicked()
                }

                /**
                 * @brief Tombol History untuk melihat riwayat.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: history (ikon jam/riwayat)
                 * - Label: "History (H)"
                 * - Variant: "yellow" (styling kuning)
                 * - Aksi: Emit signal historyClicked()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                    labelText: "History (H)"
                    variant: "yellow"
                    onClicked: resultsPage.historyClicked()
                }
            }
        }
    }
}
