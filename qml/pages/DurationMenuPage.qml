/**
 * @file DurationMenuPage.qml
 * @brief Halaman menu pemilihan durasi permainan.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menyediakan antarmuka untuk memilih durasi
 * tes mengetik. Pengguna dapat memilih dari opsi preset atau
 * memasukkan durasi kustom.
 *
 * @par Opsi Durasi:
 * - 15 detik [1] - Tes cepat
 * - 30 detik [2] - Standar pendek
 * - 60 detik [3] - Standar
 * - Custom [4] - Durasi kustom (5-600 detik)
 * - Infinity [5] - Tanpa batas waktu
 *
 * @par Durasi Default:
 * Menekan Enter akan menggunakan durasi default yang tersimpan
 * di GameBackend.defaultDuration. Nilai -1 berarti infinity.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | 1 | Pilih 15 detik |
 * | 2 | Pilih 30 detik |
 * | 3 | Pilih 60 detik |
 * | 4 | Buka halaman durasi kustom |
 * | 5 | Pilih infinity |
 * | Enter | Gunakan durasi default |
 * | Escape | Kembali |
 *
 * @see CustomDurationPage Halaman input durasi kustom
 * @see GameBackend Backend untuk pengaturan default
 * @see GameplayPage Halaman permainan setelah memilih durasi
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import rapid_texter 1.0
import "../components"

/**
 * @brief Komponen halaman pemilihan durasi.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk
 * menu pemilihan durasi. Menangani input keyboard dan menampilkan
 * opsi durasi dalam bentuk daftar menu.
 */
Rectangle {
    id: durationMenuPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal durationSelected
     * @brief Dipancarkan ketika durasi dipilih.
     * @param duration string Durasi dalam format "Xs" (contoh: "15s", "30s") atau "Infinity".
     *
     * @details Signal ini di-emit ketika user:
     * - Mengklik salah satu opsi menu
     * - Menekan tombol angka 1-5
     * - Menekan Enter untuk durasi default
     */
    signal durationSelected(string duration)

    /**
     * @signal customDurationClicked
     * @brief Dipancarkan ketika user memilih opsi Custom.
     *
     * @details Signal ini menavigasi ke CustomDurationPage
     * untuk input durasi kustom.
     */
    signal customDurationClicked

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika user menekan ESC atau tombol Back.
     */
    signal backClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard:
     * - Angka 1-5: Pilih durasi sesuai opsi
     * - Enter: Gunakan durasi default
     * - Escape: Kembali ke menu sebelumnya
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_1:
            durationSelected("15s");
            event.accepted = true;
            break;
        case Qt.Key_2:
            durationSelected("30s");
            event.accepted = true;
            break;
        case Qt.Key_3:
            durationSelected("60s");
            event.accepted = true;
            break;
        case Qt.Key_4:
            customDurationClicked();
            event.accepted = true;
            break;
        case Qt.Key_5:
            durationSelected("Infinity");
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            durationSelected(GameBackend.defaultDuration === -1 ? "Infinity" : GameBackend.defaultDuration + "s");
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
     * @details Item ini centered di parent dan berisi
     * ColumnLayout dengan judul, opsi menu, dan tombol navigasi.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: durCol.implicitHeight

        /// @brief Layout kolom utama
        ColumnLayout {
            id: durCol
            anchors.fill: parent
            spacing: 0

            /// @brief Judul halaman
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "SELECT DURATION"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk item-item menu durasi.
             *
             * @details ColumnLayout ini berisi 5 opsi durasi:
             * - 3 opsi preset (15s, 30s, 60s)
             * - 1 opsi kustom
             * - 1 opsi infinity
             */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                /// @brief Opsi 15 detik
                MenuItemC {
                    keyText: "[1]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                    labelText: "15 Seconds"
                    onClicked: durationMenuPage.durationSelected("15s")
                }

                /// @brief Opsi 30 detik
                MenuItemC {
                    keyText: "[2]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                    labelText: "30 Seconds"
                    onClicked: durationMenuPage.durationSelected("30s")
                }

                /// @brief Opsi 60 detik
                MenuItemC {
                    keyText: "[3]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                    labelText: "60 Seconds"
                    onClicked: durationMenuPage.durationSelected("60s")
                }

                /// @brief Opsi durasi kustom (navigasi ke CustomDurationPage)
                MenuItemC {
                    keyText: "[4]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/sliders.svg"
                    labelText: "Custom"
                    accentType: "yellow"
                    onClicked: durationMenuPage.customDurationClicked()
                }

                /// @brief Opsi infinity (tanpa batas waktu)
                MenuItemC {
                    keyText: "[5]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/infinity.svg"
                    labelText: "Infinity (No Limit)"
                    onClicked: durationMenuPage.durationSelected("Infinity")
                }
            }

            /**
             * @brief Teks petunjuk durasi default.
             *
             * @details Menampilkan durasi default yang tersimpan.
             * Menekan Enter akan menggunakan nilai ini.
             * Menampilkan "∞" jika defaultDuration = -1.
             */
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 15
                text: "[Enter] Use Default (" + (GameBackend.defaultDuration === -1 ? "∞" : GameBackend.defaultDuration + "s") + ")"
                color: Theme.accentGreen
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
                horizontalAlignment: Text.AlignHCenter
            }

            /// @brief Baris tombol navigasi
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30

                /// @brief Tombol Back
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back (ESC)"
                    onClicked: durationMenuPage.backClicked()
                }
            }
        }
    }
}
