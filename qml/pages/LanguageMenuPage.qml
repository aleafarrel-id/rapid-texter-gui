/**
 * @file LanguageMenuPage.qml
 * @brief Halaman menu pemilihan bahasa permainan.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini memungkinkan pengguna untuk memilih bahasa
 * yang akan digunakan dalam permainan. Bahasa menentukan set kata
 * yang akan ditampilkan saat race.
 *
 * @par Bahasa yang Tersedia:
 * - Indonesia (ID): Set kata dalam Bahasa Indonesia
 * - English (EN): Set kata dalam Bahasa Inggris
 *
 * @par Catatan:
 * Bahasa Programming (PROG) hanya tersedia di mode multiplayer
 * melalui LobbyPage. Mode singleplayer hanya menyediakan ID dan EN.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | 1 | Pilih Bahasa Indonesia |
 * | 2 | Pilih Bahasa Inggris |
 * | Escape | Kembali ke menu sebelumnya |
 *
 * @see TextProvider Backend untuk mengambil teks berdasarkan bahasa
 * @see GameModeSelectPage Halaman sebelumnya dalam alur
 * @see GamePage Halaman yang dituju setelah memilih bahasa
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman pemilihan bahasa.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk menu
 * pemilihan bahasa. Menampilkan dua pilihan bahasa dalam format item
 * menu yang dapat diklik atau diakses via keyboard.
 *
 * @par Alur Penggunaan:
 * 1. User sampai di halaman ini setelah memilih mode permainan
 * 2. User memilih bahasa (tekan 1/2 atau klik)
 * 3. Signal languageSelected(lang) di-emit
 * 4. Parent navigasi ke halaman berikutnya (GamePage atau ManualSetupPage)
 */
Rectangle {
    id: languageMenuPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal languageSelected
     * @brief Dipancarkan dengan kode bahasa yang dipilih ("ID" atau "EN").
     * @param lang string Kode bahasa yang dipilih.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol 1 (untuk ID) atau 2 (untuk EN)
     * - User mengklik item menu Indonesia atau English
     *
     * Parent component harus menangani signal ini untuk:
     * 1. Menyimpan preferensi bahasa ke TextProvider
     * 2. Menavigasi ke halaman permainan
     */
    signal languageSelected(string lang)

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
     * @details Menangani pintasan keyboard untuk pemilihan bahasa:
     * - Key_1: Pilih Bahasa Indonesia (emit languageSelected("ID"))
     * - Key_2: Pilih Bahasa Inggris (emit languageSelected("EN"))
     * - Escape: Kembali ke halaman sebelumnya (emit backClicked())
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_1:
            languageSelected("ID");
            event.accepted = true;
            break;
        case Qt.Key_2:
            languageSelected("EN");
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            backClicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Container utama untuk konten menu.
     *
     * @details Item ini berisi seluruh komponen UI untuk pemilihan bahasa,
     * termasuk judul dan item menu.
     *
     * @par Layout:
     * - Centered di parent
     * - Lebar maksimum: Theme.maxContentWidth
     * - Padding horizontal: Theme.paddingHuge * 2
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: langCol.implicitHeight

        /**
         * @brief Layout kolom utama untuk konten menu.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Judul halaman ("SELECT LANGUAGE")
         * 2. Item menu bahasa (Indonesia, English)
         * 3. Tombol navigasi Back
         */
        ColumnLayout {
            id: langCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Judul halaman pemilihan bahasa.
             *
             * @details Menampilkan teks "SELECT LANGUAGE" dengan
             * styling display (bold, ukuran besar) dan warna tema primer.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "SELECT LANGUAGE"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk item menu bahasa.
             *
             * @details ColumnLayout ini berisi dua MenuItemC component
             * untuk pilihan bahasa Indonesia dan English.
             */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                /**
                 * @brief Item menu Bahasa Indonesia.
                 *
                 * @details Menggunakan komponen MenuItemC dengan:
                 * - Key: [1]
                 * - Ikon: globe
                 * - Label: "Indonesia (ID)"
                 * - Aksi: Emit signal languageSelected("ID")
                 */
                MenuItemC {
                    keyText: "[1]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                    labelText: "Indonesia (ID)"
                    onClicked: languageMenuPage.languageSelected("ID")
                }

                /**
                 * @brief Item menu Bahasa Inggris.
                 *
                 * @details Menggunakan komponen MenuItemC dengan:
                 * - Key: [2]
                 * - Ikon: globe
                 * - Label: "English (EN)"
                 * - Aksi: Emit signal languageSelected("EN")
                 */
                MenuItemC {
                    keyText: "[2]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                    labelText: "English (EN)"
                    onClicked: languageMenuPage.languageSelected("EN")
                }
            }

            /**
             * @brief Container untuk tombol navigasi.
             *
             * @details Berisi tombol Back untuk kembali ke menu sebelumnya.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30

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
                    onClicked: languageMenuPage.backClicked()
                }
            }
        }
    }
}
