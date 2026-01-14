/**
 * @file CustomDurationPage.qml
 * @brief Halaman input durasi kustom untuk permainan.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menyediakan antarmuka untuk memasukkan
 * durasi permainan kustom. Pengguna dapat memasukkan nilai antara
 * 5 hingga 600 detik (10 menit).
 *
 * @par Validasi Input:
 * - Minimum: 5 detik (tes sangat singkat)
 * - Maximum: 600 detik (10 menit)
 * - Default: 45 detik
 * - Hanya menerima angka (IntValidator)
 *
 * @par Fallback:
 * Jika input kosong atau tidak valid saat konfirmasi,
 * nilai default 30 detik akan digunakan.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter | Konfirmasi durasi |
 * | Escape | Kembali ke menu durasi |
 *
 * @see DurationMenuPage Menu pemilihan durasi
 * @see GameplayPage Halaman permainan setelah konfirmasi
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman input durasi kustom.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk
 * form input durasi kustom. Memiliki TextInput dengan validasi
 * integer dan tombol navigasi.
 */
Rectangle {
    id: customDurationPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal durationConfirmed
     * @brief Dipancarkan ketika durasi dikonfirmasi.
     * @param duration string Durasi dalam format "Xs" (contoh: "45s", "120s").
     *
     * @details Signal ini di-emit ketika user:
     * - Menekan Enter
     * - Mengklik tombol Confirm
     *
     * Jika input tidak valid, nilai default 30 akan digunakan.
     */
    signal durationConfirmed(string duration)

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika user menekan ESC atau tombol Back.
     */
    signal backClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard:
     * - Enter: Konfirmasi durasi yang dimasukkan
     * - Escape: Kembali ke DurationMenuPage
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            var seconds = parseInt(customDurInput.text) || 30;
            durationConfirmed(seconds + "s");
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            backClicked();
            event.accepted = true;
        }
    }

    /**
     * @brief Container utama untuk konten form.
     *
     * @details Item ini centered di parent dan berisi
     * ColumnLayout dengan judul, form input, dan tombol navigasi.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: customDurCol.implicitHeight

        /// @brief Layout kolom utama
        ColumnLayout {
            id: customDurCol
            anchors.fill: parent
            spacing: 0

            /// @brief Judul halaman
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CUSTOM DURATION"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk form input durasi.
             *
             * @details Column ini berisi:
             * - Label instruksi
             * - Field input dengan border focus
             * - Teks validasi range
             */
            Column {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                /// @brief Label instruksi input
                Text {
                    text: "Enter Duration (seconds):"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                }

                /**
                 * @brief Container field input durasi.
                 *
                 * @details Rectangle dengan border yang berubah warna
                 * saat input mendapat focus (biru saat aktif).
                 */
                Rectangle {
                    width: parent.width
                    height: 50
                    color: Theme.bgPrimary
                    border.width: 1
                    border.color: customDurInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary

                    /**
                     * @brief TextInput untuk memasukkan durasi.
                     *
                     * @details Input field dengan:
                     * - Validasi integer (5-600)
                     * - Teks centered
                     * - Auto-focus saat halaman dimuat
                     */
                    TextInput {
                        id: customDurInput
                        anchors.fill: parent
                        anchors.margins: Theme.paddingL
                        text: "45"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        validator: IntValidator {
                            bottom: 5
                            top: 600
                        }
                        selectByMouse: true
                        Component.onCompleted: forceActiveFocus()
                    }

                    /// @brief Label satuan "SEC" di kanan input
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingL
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEC"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                }

                /// @brief Teks petunjuk range valid
                Text {
                    text: "Valid range: 5 - 600 seconds"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSM
                }
            }

            /// @brief Baris tombol navigasi
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingM

                /// @brief Tombol Back
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back (ESC)"
                    onClicked: customDurationPage.backClicked()
                }

                /// @brief Tombol Confirm (primary style)
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                    labelText: "Confirm (ENTER)"
                    variant: "primary"
                    onClicked: {
                        var seconds = parseInt(customDurInput.text) || 30;
                        customDurationPage.durationConfirmed(seconds + "s");
                    }
                }
            }
        }
    }
}
