/**
 * @file HistoryPage.qml
 * @brief Halaman tampilan riwayat permainan dengan paginasi.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan daftar riwayat permainan sebelumnya
 * dalam format tabel dengan paginasi. Setiap entri menunjukkan statistik
 * lengkap dari sesi permainan.
 *
 * @par Kolom yang Ditampilkan:
 * - WPM: Kecepatan mengetik (Words Per Minute)
 * - ACCURACY: Persentase akurasi
 * - TARGET: Target WPM yang ditetapkan
 * - ERRORS: Jumlah kesalahan
 * - DIFFICULTY: Tingkat kesulitan (Easy/Medium/Hard/Expert)
 * - LANG: Bahasa yang digunakan (ID/EN/PROG)
 * - MODE: Mode permainan (Campaign/Manual)
 * - DATE/TIME: Waktu permainan
 *
 * @par Fitur Visual:
 * - Indikator warna hijau/merah untuk status pass/fail
 * - Hover effect pada setiap baris
 * - Header tabel yang sticky
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Escape | Kembali ke menu |
 * | C | Hapus semua riwayat |
 * | M | Lihat riwayat multiplayer |
 *
 * @see HistoryManager Backend untuk penyimpanan riwayat
 * @see ResetHistoryPage Halaman konfirmasi hapus riwayat
 * @see MultiplayerHistoryPage Riwayat permainan multiplayer
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../components"

/**
 * @brief Komponen halaman riwayat permainan.
 * @inherits Rectangle
 *
 * @details Rectangle ini berfungsi sebagai container utama untuk tampilan
 * riwayat permainan. Menggunakan ListView untuk menampilkan data dengan
 * performa yang baik meskipun ada banyak entri.
 *
 * @par Alur Penggunaan:
 * 1. Parent component memuat data dari HistoryManager ke historyData
 * 2. Halaman menampilkan data dalam format tabel
 * 3. User dapat browse, hapus riwayat, atau lihat multiplayer history
 */
Rectangle {
    id: historyPage
    color: Theme.bgPrimary
    focus: true

    /* ========================================================================
     * PROPERTI DATA RIWAYAT
     * ======================================================================== */

    /**
     * @property historyData
     * @brief Array entri riwayat permainan (diisi dari backend).
     * @type var (QVariantList)
     *
     * @details Setiap entri berisi:
     * - wpm: float - Words per minute
     * - acc: float - Accuracy percentage
     * - target: int - Target WPM
     * - errors: int - Jumlah error
     * - difficulty: string - Level kesulitan
     * - lang: string - Kode bahasa
     * - mode: string - Mode permainan
     * - date: string - Timestamp
     * - passed: bool - Status pass/fail
     */
    property var historyData: []

    /**
     * @property currentPage
     * @brief Halaman saat ini dalam paginasi.
     * @type int
     * @default 1
     */
    property int currentPage: 1

    /**
     * @property totalPages
     * @brief Total halaman yang tersedia.
     * @type int
     * @default 1
     */
    property int totalPages: 1

    /**
     * @property totalEntries
     * @brief Total jumlah entri riwayat.
     * @type int
     * @default 0
     */
    property int totalEntries: 0

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika user menekan tombol kembali.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Back
     */
    signal backClicked

    /**
     * @signal clearHistoryClicked
     * @brief Dipancarkan ketika user ingin menghapus riwayat.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol C
     * - User mengklik tombol Clear History
     *
     * Parent component harus navigasi ke ResetHistoryPage untuk konfirmasi.
     */
    signal clearHistoryClicked

    /**
     * @signal multiplayerHistoryClicked
     * @brief Dipancarkan ketika user ingin melihat riwayat multiplayer.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol M
     * - User mengklik tombol Multiplayer History
     */
    signal multiplayerHistoryClicked

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard untuk navigasi:
     * - Escape: Kembali ke halaman sebelumnya
     * - C: Buka halaman hapus riwayat
     * - M: Buka halaman riwayat multiplayer
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Escape:
            backClicked();
            event.accepted = true;
            break;
        case Qt.Key_C:
            clearHistoryClicked();
            event.accepted = true;
            break;
        case Qt.Key_M:
            mpHistoryBtn.clicked();
            event.accepted = true;
            break;
        }
    }

    /**
     * @brief Layout utama halaman riwayat.
     *
     * @details ColumnLayout ini mengatur susunan vertikal dari:
     * 1. Header dengan judul dan informasi paginasi
     * 2. Tabel riwayat dengan header dan ListView
     * 3. Tombol navigasi di bagian bawah
     */
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingHuge
        spacing: 0

        /**
         * @brief Bagian header halaman.
         *
         * @details Menampilkan:
         * - Ikon dan judul "GAME HISTORY"
         * - Informasi halaman saat ini
         * - Total entri riwayat
         */
        Column {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: Theme.spacingM

            /// @brief Baris judul dengan ikon
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                /// @brief Container ikon history
                Item {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: historyTitleIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(28, 28)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: historyTitleIcon
                        source: historyTitleIcon
                        color: Theme.accentBlue
                    }
                }

                /// @brief Teks judul halaman
                Text {
                    text: "GAME HISTORY"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            /// @brief Informasi halaman paginasi
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Page " + historyPage.currentPage + " of " + historyPage.totalPages
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
            }

            /// @brief Total entri riwayat
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: historyPage.totalEntries + " total entries"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeS
            }
        }

        /**
         * @brief Container tabel riwayat.
         *
         * @details Rectangle ini berisi header tabel dan ListView
         * untuk menampilkan data riwayat permainan.
         */
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.width: 1
            border.color: Theme.borderPrimary

            Column {
                anchors.fill: parent

                /**
                 * @brief Header baris tabel.
                 *
                 * @details Menampilkan nama kolom: WPM, ACCURACY, TARGET,
                 * ERRORS, DIFFICULTY, LANG, MODE, DATE/TIME
                 */
                Rectangle {
                    width: parent.width
                    height: 40
                    color: Theme.bgSecondary

                    /// @brief Garis bawah header
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.borderPrimary
                    }

                    /// @brief Layout kolom header
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.paddingHuge
                        anchors.rightMargin: Theme.paddingHuge
                        spacing: 0

                        /// @brief Repeater untuk header kolom
                        Repeater {
                            model: [
                                {
                                    text: "WPM",
                                    width: 60
                                },
                                {
                                    text: "ACCURACY",
                                    width: 80
                                },
                                {
                                    text: "TARGET",
                                    width: 60
                                },
                                {
                                    text: "ERRORS",
                                    width: 60
                                },
                                {
                                    text: "DIFFICULTY",
                                    width: 80
                                },
                                {
                                    text: "LANG",
                                    width: 50
                                },
                                {
                                    text: "MODE",
                                    width: 80
                                },
                                {
                                    text: "DATE/TIME",
                                    width: 130
                                }
                            ]
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: modelData.width
                                text: modelData.text
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeS
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                /**
                 * @brief ListView untuk data riwayat.
                 *
                 * @details Menampilkan setiap entri riwayat sebagai baris
                 * dengan indikator warna pass/fail di sisi kiri.
                 */
                ListView {
                    width: parent.width
                    height: parent.height - 40
                    clip: true
                    model: historyPage.historyData

                    ScrollBar.vertical: ScrollBar {
                        id: historyScrollBar
                        policy: ScrollBar.AsNeeded
                        width: 8
                        hoverEnabled: true
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: historyScrollBar.pressed ? "#6A6A6A" : "#4A4A4A"
                            opacity: historyScrollBar.hovered || historyScrollBar.pressed ? 1.0 : 0.6

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    /// @brief Delegate untuk setiap entri riwayat
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 40
                        color: histMouse.containsMouse ? Theme.bgSecondary : "transparent"

                        /// @brief Garis bawah baris
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.borderPrimary
                        }

                        /// @brief Indikator status pass/fail (hijau/merah)
                        Rectangle {
                            width: 2
                            height: parent.height
                            color: modelData.passed ? Theme.accentGreen : Theme.accentRed
                        }

                        /// @brief Layout kolom data
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.paddingHuge
                            anchors.rightMargin: Theme.paddingHuge
                            spacing: 0

                            /// @brief Kolom WPM (warna dinamis)
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.wpm.toFixed(1)
                                color: modelData.passed ? Theme.accentGreen : Theme.accentRed
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Accuracy
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.acc.toFixed(1) + "%"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Target WPM
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.target
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Errors
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 60
                                text: modelData.errors
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Difficulty
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.difficulty
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Language
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 50
                                text: modelData.lang
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Mode
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                text: modelData.mode
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }

                            /// @brief Kolom Date/Time
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 130
                                text: modelData.date
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        /// @brief Mouse area untuk hover effect
                        MouseArea {
                            id: histMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }
        }

        /**
         * @brief Baris tombol navigasi dan aksi.
         *
         * @details Berisi tiga tombol:
         * - Back: Kembali ke halaman sebelumnya
         * - Multiplayer History: Lihat riwayat multiplayer
         * - Clear History: Hapus semua riwayat (danger)
         */
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            spacing: Theme.spacingM

            /// @brief Tombol kembali
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back (ESC)"
                onClicked: historyPage.backClicked()
            }

            /// @brief Tombol multiplayer history
            NavBtn {
                id: mpHistoryBtn
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                labelText: "Multiplayer History (M)"
                onClicked: historyPage.multiplayerHistoryClicked()
            }

            /// @brief Tombol hapus riwayat (danger)
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                labelText: "Clear History (C)"
                variant: "danger"
                onClicked: historyPage.clearHistoryClicked()
            }
        }
    }
}
