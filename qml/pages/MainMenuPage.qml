/**
 * @file MainMenuPage.qml
 * @brief Halaman menu utama dengan opsi navigasi untuk aplikasi RapidTexter.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan halaman pembuka aplikasi dengan logo
 * dan pilihan navigasi utama. Ini adalah halaman pertama yang dilihat
 * pengguna saat membuka aplikasi.
 *
 * @par Opsi Navigasi:
 * - Start Game [1]: Memulai permainan baru (navigasi ke GameModeSelectPage)
 * - Show History [2]: Melihat riwayat hasil permainan sebelumnya
 * - Quit [Q]: Keluar dari aplikasi
 *
 * @par Desain Visual:
 * Halaman menggunakan layout centered dengan logo "RAPID TEXTER" besar
 * di atas dan item menu dengan ikon berwarna di bawahnya.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | 1 | Mulai permainan |
 * | 2 | Lihat riwayat |
 * | Q | Keluar aplikasi |
 *
 * @see GameModeSelectPage Halaman pemilihan mode setelah Start Game
 * @see HistoryPage Halaman riwayat yang ditampilkan saat Show History
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman menu utama.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk halaman
 * menu utama. Menampilkan logo aplikasi dan item menu navigasi yang
 * dapat diklik atau diakses melalui pintasan keyboard.
 *
 * @par Alur Penggunaan:
 * 1. Aplikasi dibuka, halaman ini ditampilkan sebagai halaman pertama
 * 2. User memilih salah satu opsi menu (keyboard atau klik)
 * 3. Signal yang sesuai di-emit untuk navigasi ke halaman target
 */
Rectangle {
    id: mainMenuPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal startGameClicked
     * @brief Dipancarkan ketika pengguna menekan [1] atau klik Start Game.
     *
     * @details Signal ini di-emit untuk memulai alur permainan baru.
     * Parent component harus menangani signal ini untuk navigasi
     * ke GameModeSelectPage untuk pemilihan mode permainan.
     */
    signal startGameClicked

    /**
     * @signal showHistoryClicked
     * @brief Dipancarkan ketika pengguna menekan [2] atau klik Show History.
     *
     * @details Signal ini di-emit untuk menampilkan riwayat permainan.
     * Parent component harus menangani signal ini untuk navigasi
     * ke HistoryPage untuk melihat hasil permainan sebelumnya.
     */
    signal showHistoryClicked

    /**
     * @signal quitClicked
     * @brief Dipancarkan ketika pengguna menekan [Q] atau klik Quit.
     *
     * @details Signal ini di-emit untuk menutup aplikasi.
     * Parent component harus menangani signal ini untuk memanggil
     * Qt.quit() atau proses cleanup yang diperlukan.
     */
    signal quitClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi menu:
     * - Key_1: Mulai permainan (emit startGameClicked())
     * - Key_2: Lihat riwayat (emit showHistoryClicked())
     * - Key_Q: Keluar aplikasi (emit quitClicked())
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_1:
            startGameClicked();
            event.accepted = true;
            break;
        case Qt.Key_2:
            showHistoryClicked();
            event.accepted = true;
            break;
        case Qt.Key_Q:
            quitClicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Container utama untuk konten menu.
     *
     * @details Item ini berisi seluruh komponen UI untuk menu utama,
     * termasuk logo dan item menu navigasi.
     *
     * @par Layout:
     * - Centered di parent
     * - Lebar maksimum: Theme.maxContentWidth
     * - Padding horizontal: Theme.paddingHuge * 2
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: mainCol.implicitHeight

        /**
         * @brief Layout kolom utama untuk konten menu.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Logo aplikasi (RAPID TEXTER)
         * 2. Item menu navigasi
         * 3. Teks helper navigasi
         *
         * @par Properti Layout:
         * - Spacing: 0 (spacing dikontrol per-elemen via margin)
         * - Fill: Mengisi seluruh parent Item
         */
        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Container untuk logo aplikasi.
             *
             * @details Column ini menampilkan logo "RAPID TEXTER" dengan
             * dua baris teks: "RAPID" dalam warna biru besar dan
             * "TEXTER" dalam warna abu-abu sedikit lebih kecil.
             *
             * @par Visual Design:
             * - RAPID: Warna biru (Theme.accentBlue), bold, spacing negatif
             * - TEXTER: Warna abu-abu, bold, letter-spacing positif, opacity 0.7
             */
            Column {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Theme.spacingLogo
                spacing: Theme.spacingM

                /**
                 * @brief Teks logo utama "RAPID".
                 * @details Ditampilkan dalam warna biru dengan ukuran besar
                 * dan letter-spacing negatif untuk tampilan modern.
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "RAPID"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLogo
                    font.bold: true
                    font.letterSpacing: -3
                }

                /**
                 * @brief Teks logo subtitle "TEXTER".
                 * @details Ditampilkan dalam warna abu-abu dengan opacity rendah
                 * dan letter-spacing positif untuk kontras dengan "RAPID".
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "TEXTER"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLogoSubtitle
                    font.bold: true
                    font.letterSpacing: 5
                    opacity: 0.7
                }
            }

            /**
             * @brief Container untuk item menu navigasi.
             *
             * @details ColumnLayout ini berisi tiga MenuItemC component
             * untuk opsi navigasi utama aplikasi.
             *
             * @par Item Menu:
             * 1. Start Game: Aksen hijau, ikon play
             * 2. Show History: Aksen kuning, ikon history
             * 3. Quit: Aksen merah, ikon close
             */
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 30
                spacing: Theme.spacingSM

                /**
                 * @brief Item menu Start Game.
                 *
                 * @details Menggunakan komponen MenuItemC dengan:
                 * - Key: [1]
                 * - Ikon: play
                 * - Aksen: hijau (green)
                 * - Aksi: Emit signal startGameClicked()
                 */
                MenuItemC {
                    keyText: "[1]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                    labelText: "Start Game"
                    accentType: "green"
                    onClicked: mainMenuPage.startGameClicked()
                }

                /**
                 * @brief Item menu Show History.
                 *
                 * @details Menggunakan komponen MenuItemC dengan:
                 * - Key: [2]
                 * - Ikon: history
                 * - Aksen: kuning (yellow)
                 * - Aksi: Emit signal showHistoryClicked()
                 */
                MenuItemC {
                    keyText: "[2]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                    labelText: "Show History"
                    accentType: "yellow"
                    onClicked: mainMenuPage.showHistoryClicked()
                }

                /**
                 * @brief Item menu Quit.
                 *
                 * @details Menggunakan komponen MenuItemC dengan:
                 * - Key: (Q)
                 * - Ikon: close
                 * - Aksen: merah (red)
                 * - Aksi: Emit signal quitClicked()
                 *
                 * @note Menggunakan tanda kurung (Q) bukan bracket [Q]
                 * untuk menandakan ini shortcut khusus, bukan nomor urut.
                 */
                MenuItemC {
                    keyText: "(Q)"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                    labelText: "Quit"
                    accentType: "red"
                    onClicked: mainMenuPage.quitClicked()
                }
            }

            /**
             * @brief Teks helper untuk navigasi.
             * @details Menginformasikan user bahwa mereka dapat menggunakan
             * keyboard atau klik untuk menavigasi menu.
             */
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 30
                text: "Press keys or click to navigate"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
