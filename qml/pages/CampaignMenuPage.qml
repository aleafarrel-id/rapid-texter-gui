/**
 * @file CampaignMenuPage.qml
 * @brief Halaman menu pemilihan tingkat kesulitan campaign dengan sistem unlock.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan daftar level campaign dengan
 * sistem progres unlock. Level akan terbuka setelah level sebelumnya
 * berhasil diselesaikan.
 *
 * @par Tingkat Kesulitan:
 * | Level | Minimum WPM | Minimum Akurasi | Unlock |
 * |-------|-------------|-----------------|--------|
 * | Easy [1] | 40 WPM | 80% | Selalu tersedia |
 * | Medium [2] | 60 WPM | 85% | Setelah Easy |
 * | Hard [3] | 80 WPM | 90% | Setelah Medium |
 * | Programmer [4] | 50 WPM | 90% | Selalu tersedia |
 *
 * @par Status Level:
 * - [PASSED]: Level sudah berhasil diselesaikan (hijau)
 * - [LOCKED]: Level belum terbuka (abu-abu)
 * - [CERTIFIED]: Sertifikasi programmer mode (biru)
 * - [AVAILABLE]: Dapat dimainkan
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | 1 | Pilih Easy |
 * | 2 | Pilih Medium (jika terbuka) |
 * | 3 | Pilih Hard (jika terbuka) |
 * | 4 | Pilih Programmer Mode |
 * | C | Lihat Credits |
 * | R | Reset Progress |
 * | Escape | Kembali |
 *
 * @see GameplayPage Halaman permainan setelah memilih level
 * @see CreditsPage Halaman kredit developer
 * @see ResetProgressPage Halaman konfirmasi reset progres
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen halaman pemilihan tingkat kesulitan campaign.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk
 * menu campaign. Mengelola state progres dan menampilkan opsi
 * level dengan indikator status unlock.
 */
Rectangle {
    id: campaignMenuPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * PROPERTI STATE PROGRES CAMPAIGN
     * ======================================================================== */

    /**
     * @property easyPassed
     * @brief Menandakan apakah level Easy sudah diselesaikan.
     * @type bool
     * @default true
     *
     * @details Jika true, level Medium akan terbuka.
     */
    property bool easyPassed: true

    /**
     * @property mediumPassed
     * @brief Menandakan apakah level Medium sudah diselesaikan.
     * @type bool
     * @default false
     *
     * @details Jika true, level Hard akan terbuka.
     */
    property bool mediumPassed: false

    /**
     * @property hardPassed
     * @brief Menandakan apakah level Hard sudah diselesaikan.
     * @type bool
     * @default false
     */
    property bool hardPassed: false

    /**
     * @property programmerCertified
     * @brief Menandakan apakah sertifikasi Programmer Mode sudah didapat.
     * @type bool
     * @default false
     *
     * @details Programmer Mode selalu tersedia, tetapi sertifikasi
     * diberikan jika mencapai target WPM dan akurasi.
     */
    property bool programmerCertified: false

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal difficultySelected
     * @brief Dipancarkan ketika tingkat kesulitan dipilih.
     * @param difficulty string Tingkat kesulitan: "easy", "medium", "hard", atau "programmer".
     *
     * @details Signal ini di-emit ketika user:
     * - Mengklik salah satu opsi menu (jika unlocked)
     * - Menekan tombol angka 1-4 (dengan validasi unlock)
     */
    signal difficultySelected(string difficulty)

    /**
     * @signal creditsClicked
     * @brief Dipancarkan ketika user menekan C atau tombol Credits.
     *
     * @details Menavigasi ke CreditsPage.
     */
    signal creditsClicked

    /**
     * @signal resetClicked
     * @brief Dipancarkan ketika user menekan R atau tombol Reset.
     *
     * @details Menavigasi ke ResetProgressPage untuk konfirmasi reset.
     */
    signal resetClicked

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika user menekan ESC atau tombol Back.
     */
    signal backClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard:
     * - Angka 1-4: Pilih level (dengan validasi unlock)
     * - C: Lihat credits
     * - R: Reset progress
     * - Escape: Kembali
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_1:
            difficultySelected("easy");
            event.accepted = true;
            break;
        case Qt.Key_2:
            if (easyPassed)
                difficultySelected("medium");
            event.accepted = true;
            break;
        case Qt.Key_3:
            if (mediumPassed)
                difficultySelected("hard");
            event.accepted = true;
            break;
        case Qt.Key_4:
            difficultySelected("programmer");
            event.accepted = true;
            break;
        case Qt.Key_C:
            creditsClicked();
            event.accepted = true;
            break;
        case Qt.Key_R:
            resetClicked();
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
     * ColumnLayout dengan judul, opsi level, dan tombol navigasi.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
        height: campCol.implicitHeight

        /// @brief Layout kolom utama
        ColumnLayout {
            id: campCol
            anchors.fill: parent
            spacing: 0

            /// @brief Judul halaman
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 30
                text: "CAMPAIGN DIFFICULTY"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Container untuk item-item menu level.
             *
             * @details ColumnLayout ini berisi 4 opsi level:
             * - Easy: Selalu tersedia
             * - Medium: Terkunci sampai Easy passed
             * - Hard: Terkunci sampai Medium passed
             * - Programmer: Selalu tersedia (mode khusus)
             */
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSM

                /// @brief Level Easy (selalu terbuka)
                MenuItemC {
                    keyText: "[1]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/leaf.svg"
                    labelText: "Easy"
                    accentType: campaignMenuPage.easyPassed ? "green" : "default"
                    statusText: campaignMenuPage.easyPassed ? "[PASSED]" : ""
                    statusType: campaignMenuPage.easyPassed ? "passed" : ""
                    reqText: "Min: 40 WPM, 80% Acc"
                    onClicked: campaignMenuPage.difficultySelected("easy")
                }

                /// @brief Level Medium (terkunci sampai Easy passed)
                MenuItemC {
                    keyText: "[2]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trend-up.svg"
                    labelText: "Medium"
                    locked: !campaignMenuPage.easyPassed
                    accentType: campaignMenuPage.mediumPassed ? "green" : "default"
                    statusText: campaignMenuPage.mediumPassed ? "[PASSED]" : (campaignMenuPage.easyPassed ? "" : "[LOCKED]")
                    statusType: campaignMenuPage.mediumPassed ? "passed" : (campaignMenuPage.easyPassed ? "" : "locked")
                    reqText: campaignMenuPage.easyPassed ? "Min: 60 WPM, 90% Acc" : "Need: Easy passed"
                    onClicked: if (campaignMenuPage.easyPassed)
                        campaignMenuPage.difficultySelected("medium")
                }

                /// @brief Level Hard (terkunci sampai Medium passed)
                MenuItemC {
                    keyText: "[3]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/fire.svg"
                    labelText: "Hard"
                    locked: !campaignMenuPage.mediumPassed
                    accentType: campaignMenuPage.hardPassed ? "green" : "default"
                    statusText: campaignMenuPage.hardPassed ? "[PASSED]" : (campaignMenuPage.mediumPassed ? "" : "[LOCKED]")
                    statusType: campaignMenuPage.hardPassed ? "passed" : (campaignMenuPage.mediumPassed ? "" : "locked")
                    reqText: campaignMenuPage.mediumPassed ? "Min: 70 WPM, 90% Acc" : "Need: Medium passed"
                    onClicked: if (campaignMenuPage.mediumPassed)
                        campaignMenuPage.difficultySelected("hard")
                }

                /// @brief Programmer Mode (mode khusus, selalu tersedia)
                MenuItemC {
                    keyText: "[4]"
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/monitor.svg"
                    labelText: "Programmer Mode"
                    statusText: campaignMenuPage.programmerCertified ? "[CERTIFIED]" : "[AVAILABLE]"
                    statusType: "certified"
                    reqText: "50 WPM, 90% for Cert"
                    onClicked: campaignMenuPage.difficultySelected("programmer")
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
                    onClicked: campaignMenuPage.backClicked()
                }

                /// @brief Tombol Credits
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                    labelText: "Credits (C)"
                    onClicked: campaignMenuPage.creditsClicked()
                }

                /// @brief Tombol Reset (danger style)
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    labelText: "Reset (R)"
                    variant: "danger"
                    onClicked: campaignMenuPage.resetClicked()
                }
            }
        }
    }
}
