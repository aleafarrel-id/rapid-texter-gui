/**
 * @file CreditsPage.qml
 * @brief Halaman kredit dan atribusi developer aplikasi.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan kredit tim pengembang
 * dengan pesan terima kasih. Halaman ini dapat diakses dari
 * CampaignMenuPage atau menu About.
 *
 * @par Tim Pengembang:
 * - Alea Farrel
 * - Hensa Katelu
 * - Yanuar Adi Candra
 * - Arif Wibowo P.
 * - Aria Mahendra U.
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter | Kembali ke halaman sebelumnya |
 * | Escape | Kembali ke halaman sebelumnya |
 *
 * @see CampaignMenuPage Menu campaign yang memiliki tombol Credits
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"

/**
 * @brief Komponen halaman tampilan kredit.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk
 * halaman kredit. Menampilkan daftar nama developer dan pesan
 * terima kasih dengan styling yang menarik.
 */
Rectangle {
    id: creditsPage
    color: Theme.bgPrimary
    focus: true

    /**
     * @property developers
     * @brief Array nama-nama developer.
     * @type var (Array)
     *
     * @details Daftar nama anggota tim pengembang yang ditampilkan
     * di halaman kredit dengan Repeater.
     */
    property var developers: ["Alea Farrel", "Hensa Katelu", "Yanuar Adi Candra", "Arif Wibowo P.", "Aria Mahendra U."]

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal returnClicked
     * @brief Dipancarkan untuk kembali ke halaman sebelumnya.
     *
     * @details Signal ini di-emit ketika user:
     * - Menekan Enter
     * - Menekan Escape
     * - Mengklik tombol Return
     */
    signal returnClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard:
     * - Enter: Kembali
     * - Escape: Kembali
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape) {
            returnClicked();
            event.accepted = true;
        }
    }

    /**
     * @brief Container utama untuk konten kredit.
     *
     * @details Item ini centered di parent dan berisi
     * ColumnLayout dengan judul, daftar developer, pesan, dan tombol.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: credCol.implicitHeight

        /// @brief Layout kolom utama
        ColumnLayout {
            id: credCol
            anchors.fill: parent
            spacing: 0

            /// @brief Judul halaman
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CREDITS"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /// @brief Sub-judul "DEVELOPED BY"
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                text: "DEVELOPED BY:"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeL
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk daftar nama developer.
             *
             * @details Column dengan Repeater untuk menampilkan
             * setiap nama developer dengan styling biru bold.
             */
            Column {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingL

                /// @brief Repeater untuk menampilkan nama-nama developer
                Repeater {
                    model: creditsPage.developers

                    /// @brief Teks nama developer
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                    }
                }
            }

            /**
             * @brief Baris pesan terima kasih.
             *
             * @details Menampilkan ikon hati hijau dan teks
             * "Thank you for playing!" sebagai apresiasi ke pemain.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                spacing: Theme.spacingS

                /// @brief Ikon hati hijau
                Item {
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: heartIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/heart.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(16, 16)
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: heartIcon
                        source: heartIcon
                        color: Theme.accentGreen
                    }
                }

                /// @brief Teks terima kasih
                Text {
                    text: "Thank you for playing!"
                    color: Theme.accentGreen
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                }
            }

            /// @brief Baris tombol navigasi
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40

                /// @brief Tombol Return
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Return (ENTER)"
                    onClicked: creditsPage.returnClicked()
                }
            }
        }
    }
}
