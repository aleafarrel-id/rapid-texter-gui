/**
 * @file ManualSetupPage.qml
 * @brief Halaman pengaturan mode manual untuk konfigurasi target WPM.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini memungkinkan pengguna untuk mengatur target WPM
 * (Words Per Minute) sebelum memulai sesi latihan bebas (free practice mode).
 *
 * @par Fitur Utama:
 * - Input field untuk target WPM dengan validasi (1-200)
 * - Tampilan nilai default 60 WPM
 * - Feedback visual saat input fokus (border biru)
 * - Validasi otomatis menggunakan IntValidator
 *
 * Target WPM yang diatur akan digunakan untuk menentukan apakah
 * pengguna berhasil mencapai tujuan mereka di halaman hasil.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter/Return | Mulai permainan dengan WPM yang ditentukan |
 * | Escape | Kembali ke halaman sebelumnya |
 *
 * @see GamePage Halaman permainan yang akan dimulai
 * @see ResultsPage Halaman hasil yang menampilkan pencapaian target
 * @see GameModeSelectPage Halaman pemilihan mode permainan
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman pengaturan mode manual.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk UI
 * pengaturan mode manual. Menyediakan input field untuk target WPM
 * dengan validasi dan navigasi keyboard.
 *
 * @par Alur Penggunaan:
 * 1. User memilih mode Manual dari GameModeSelectPage
 * 2. Halaman ini ditampilkan dengan nilai default 60 WPM
 * 3. User dapat mengubah nilai target WPM (1-200)
 * 4. User menekan Enter atau klik Confirm untuk memulai
 * 5. Signal startClicked(wpm) di-emit dengan nilai yang dipilih
 */
Rectangle {
    id: manualSetupPage
    color: Theme.bgPrimary
    focus: true

    /**
     * @property targetWpm
     * @brief Nilai target WPM default.
     * @type int
     * @default 60
     *
     * @details Nilai ini digunakan sebagai fallback jika input kosong
     * atau tidak valid saat user mengkonfirmasi.
     */
    property int targetWpm: 60

    /**
     * @signal startClicked
     * @brief Dipancarkan dengan target WPM untuk memulai permainan.
     * @param wpm int Nilai WPM yang dipilih oleh pengguna.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Enter/Return
     * - User mengklik tombol Confirm
     *
     * Jika input tidak valid atau kosong, nilai default 60 akan digunakan.
     *
     * Parent component harus menangani signal ini untuk:
     * 1. Menyimpan target WPM ke GameBackend
     * 2. Menavigasi ke GamePage
     */
    signal startClicked(int wpm)

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika pengguna menekan [ESC].
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Back
     *
     * Parent component harus menangani signal ini untuk navigasi
     * kembali ke halaman pemilihan mode permainan.
     */
    signal backClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi:
     * - Enter/Return: Mulai permainan dengan WPM dari input
     * - Escape: Kembali ke halaman sebelumnya
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     *
     * @note Jika wpmInput.text kosong atau tidak valid, nilai 60 digunakan.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            startClicked(parseInt(wpmInput.text) || 60);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            backClicked();
            event.accepted = true;
        }
    }

    /**
     * @brief Container utama untuk UI pengaturan.
     *
     * @details Item ini berisi seluruh komponen UI untuk halaman setup,
     * termasuk judul, input field, dan tombol navigasi.
     *
     * @par Layout:
     * - Centered di parent
     * - Lebar maksimum: Theme.maxContentWidth
     * - Padding horizontal: Theme.paddingHuge * 2
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: setupCol.implicitHeight

        /**
         * @brief Layout kolom utama untuk konten setup.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Judul halaman ("MANUAL SETUP")
         * 2. Input field untuk target WPM
         * 3. Tombol navigasi (Back dan Confirm)
         *
         * @par Properti Layout:
         * - Spacing: 0 (spacing dikontrol per-elemen via margin)
         * - Fill: Mengisi seluruh parent Item
         */
        ColumnLayout {
            id: setupCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Judul halaman setup.
             *
             * @details Menampilkan teks "MANUAL SETUP" dengan
             * styling display (bold, ukuran besar) dan warna tema primer.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "MANUAL SETUP"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk input WPM dan label.
             *
             * @details Column ini berisi:
             * 1. Label instruksi ("Enter Target WPM:")
             * 2. Input field dengan border dinamis
             * 3. Teks helper untuk range yang valid
             */
            Column {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                /**
                 * @brief Label instruksi untuk input WPM.
                 */
                Text {
                    text: "Enter Target WPM:"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                }

                /**
                 * @brief Container untuk input field WPM.
                 *
                 * @details Rectangle ini menyediakan border visual untuk input.
                 * Border berubah warna menjadi biru saat input fokus untuk
                 * memberikan feedback visual kepada user.
                 *
                 * @par Visual Elements:
                 * - Height: 50px tetap
                 * - Border: 1px (abu-abu normal, biru saat fokus)
                 * - Label "WPM" di sisi kanan
                 */
                Rectangle {
                    width: parent.width
                    height: 50
                    color: Theme.bgPrimary
                    border.width: 1
                    border.color: wpmInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary

                    /**
                     * @brief Input field untuk nilai WPM.
                     *
                     * @details TextInput untuk memasukkan nilai target WPM.
                     * Menggunakan IntValidator untuk membatasi input ke
                     * angka antara 1-200.
                     *
                     * @par Properti:
                     * - Default text: "60"
                     * - Validator: 1-200
                     * - Auto-focus saat halaman dimuat
                     */
                    TextInput {
                        id: wpmInput
                        anchors.fill: parent
                        anchors.margins: Theme.paddingL
                        text: "60"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        validator: IntValidator {
                            bottom: 1
                            top: 200
                        }
                        selectByMouse: true
                        Component.onCompleted: forceActiveFocus()
                    }

                    /**
                     * @brief Label suffix "WPM" di sisi kanan input.
                     * @details Memberikan konteks satuan untuk nilai yang diinput.
                     */
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingL
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WPM"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                }

                /**
                 * @brief Teks helper menunjukkan range yang valid.
                 * @details Menginformasikan user bahwa nilai yang valid adalah 1-200.
                 */
                Text {
                    text: "Valid range: 1 - 200 WPM"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSM
                }
            }

            /**
             * @brief Container untuk tombol navigasi.
             *
             * @details Row ini berisi dua tombol navigasi:
             * - Back: Kembali ke halaman sebelumnya
             * - Confirm: Mulai permainan dengan target WPM
             *
             * @par Layout:
             * - Alignment: Center horizontal
             * - Top margin: 30px dari input field
             * - Spacing: Theme.spacingM antar tombol
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingM

                /**
                 * @brief Tombol Back untuk kembali.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: arrow-left (panah kiri)
                 * - Label: "Back (ESC)"
                 * - Aksi: Emit signal backClicked()
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back (ESC)"
                    onClicked: manualSetupPage.backClicked()
                }

                /**
                 * @brief Tombol Confirm untuk memulai permainan.
                 *
                 * @details Menggunakan komponen NavBtn dengan:
                 * - Ikon: arrow-right (panah kanan)
                 * - Label: "Confirm (ENTER)"
                 * - Variant: "primary" (styling biru utama)
                 * - Aksi: Emit signal startClicked() dengan nilai WPM
                 *
                 * @note Jika input tidak valid, nilai 60 akan digunakan.
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                    labelText: "Confirm (ENTER)"
                    variant: "primary"
                    onClicked: manualSetupPage.startClicked(parseInt(wpmInput.text) || 60)
                }
            }
        }
    }
}
