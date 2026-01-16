/**
 * @file MultiplayerHistoryPage.qml
 * @brief Halaman untuk menampilkan riwayat pertandingan multiplayer.
 * @author Alea Farrel & Team
 * @date 2026
 *
 * @details MultiplayerHistoryPage menampilkan daftar semua pertandingan
 * multiplayer yang telah dimainkan oleh pengguna. Halaman ini menyediakan
 * fitur-fitur berikut:
 *
 * @par Fitur Utama:
 * - Daftar riwayat dengan sorting berdasarkan tanggal, WPM, atau rank
 * - Tampilan expandable untuk melihat detail semua pemain
 * - Indikator visual untuk peringkat (warna berdasarkan posisi)
 * - Empty state saat belum ada riwayat
 * - Opsi untuk menghapus semua riwayat
 *
 * @par Integrasi Data:
 * Data riwayat diambil dari MultiplayerHistoryManager singleton yang
 * menyimpan data dalam format JSON di disk.
 *
 * @par Keyboard Shortcuts:
 * - ESC: Kembali ke menu sebelumnya
 * - C: Hapus semua riwayat
 *
 * @see MultiplayerHistoryManager
 * @see MainWindow.qml
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen utama halaman riwayat multiplayer.
 *
 * @details Rectangle digunakan sebagai root untuk menyediakan
 * background color dan mengaktifkan keyboard focus.
 */
Rectangle {
    id: mpHistoryPage
    color: Theme.bgPrimary  ///< Warna background utama dari tema
    focus: true  ///< Mengaktifkan focus untuk keyboard handling

    //=========================================================================
    // DATA PROPERTIES - Properti data dari MultiplayerHistoryManager
    //=========================================================================

    /**
     * @property historyData
     * @brief Data riwayat dari MultiplayerHistoryManager dalam format QVariantList.
     *
     * @details Data berisi array objek dengan struktur:
     * - timestamp: Waktu pertandingan
     * - hostName: Nama host room
     * - localWpm: WPM pemain lokal
     * - localRank: Peringkat pemain lokal
     * - players: Array detail semua pemain
     */
    property var historyData: MultiplayerHistoryManager.historyData

    /**
     * @property totalEntries
     * @brief Total jumlah entry riwayat.
     *
     * @details Digunakan untuk menampilkan jumlah pertandingan
     * dan menentukan apakah empty state harus ditampilkan.
     */
    property int totalEntries: MultiplayerHistoryManager.totalEntries

    /**
     * @brief Properti untuk mengontrol popup filter bahasa.
     */
    property bool langFilterPopupVisible: false
    property real langHeaderGlobalX: 0
    property real langHeaderGlobalY: 0

    /**
     * @brief Helper function untuk mendapatkan label bahasa.
     */
    function getLanguageLabel(lang) {
        if (lang === "id")
            return "ID";
        if (lang === "en")
            return "EN";
        if (lang === "prog")
            return "PROG";
        return "ALL";
    }

    //=========================================================================
    // SIGNALS - Sinyal untuk komunikasi dengan parent
    //=========================================================================

    /**
     * @brief Dipancarkan saat user memilih untuk kembali ke menu sebelumnya.
     * @note Ditrigger oleh klik tombol Back atau shortcut keyboard (ESC).
     */
    signal backClicked

    /**
     * @brief Dipancarkan saat user memilih untuk menghapus semua riwayat.
     * @note Ditrigger oleh klik tombol Clear History atau shortcut keyboard (C).
     */
    signal clearHistoryClicked

    //=========================================================================
    // KEYBOARD SHORTCUTS - Handler untuk shortcut keyboard
    //=========================================================================

    /**
     * @brief Handler untuk keyboard shortcuts.
     *
     * @details Mapping keyboard:
     * - Key_Escape: Trigger backClicked (Kembali)
     * - Key_C: Trigger clearHistoryClicked (Hapus Riwayat)
     *
     * @param event Event keyboard yang diterima
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            backClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_C) {
            clearHistoryClicked();
            event.accepted = true;
        }
    }

    //=========================================================================
    // MAIN LAYOUT - Tata letak utama halaman
    //=========================================================================

    /**
     * @brief ColumnLayout utama yang mengatur tata letak vertikal halaman.
     *
     * @details Struktur layout:
     * 1. Header (judul dan subtitle)
     * 2. List Header (kolom header tabel)
     * 3. List View / Empty State (konten utama)
     * 4. Footer Nav (tombol navigasi)
     */
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.paddingHuge
        spacing: 0

        //=====================================================================
        // HEADER SECTION - Bagian judul halaman
        //=====================================================================

        /**
         * @brief Column untuk header halaman.
         *
         * @details Berisi ikon, judul "MULTIPLAYER HISTORY",
         * dan subtitle yang menunjukkan jumlah pertandingan.
         */
        Column {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: Theme.spacingM

            /**
             * @brief Row untuk ikon dan judul yang di-center.
             */
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingM

                /**
                 * @brief Container untuk ikon header.
                 *
                 * @details Menggunakan ColorOverlay untuk mewarnai
                 * ikon SVG dengan warna aksen biru.
                 */
                Item {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter

                    /**
                     * @brief Image ikon users (hidden, digunakan sebagai source overlay).
                     */
                    Image {
                        id: titleIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(28, 28)
                        visible: false  ///< Hidden karena menggunakan ColorOverlay
                    }

                    /**
                     * @brief ColorOverlay untuk mewarnai ikon dengan warna aksen.
                     */
                    ColorOverlay {
                        anchors.fill: titleIcon
                        source: titleIcon
                        color: Theme.accentBlue
                    }
                }

                /**
                 * @brief Teks judul halaman "MULTIPLAYER HISTORY".
                 */
                Text {
                    text: "MULTIPLAYER HISTORY"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            /**
             * @brief Subtitle yang menampilkan jumlah pertandingan.
             *
             * @details Format: "X matches played" dimana X adalah totalEntries.
             */
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: mpHistoryPage.totalEntries + " matches played"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeS
            }
        }

        //=====================================================================
        // LIST HEADER SECTION - Header kolom tabel
        //=====================================================================

        /**
         * @brief Rectangle header untuk kolom tabel.
         *
         * @details Menampilkan label kolom yang dapat diklik untuk sorting:
         * - DATE/TIME (sortable by "date")
         * - HOST (tidak sortable)
         * - YOUR RANK (sortable by "rank")
         * - YOUR WPM (sortable by "wpm")
         */
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Theme.bgSecondary

            /**
             * @brief Garis pembatas di bagian bawah header.
             */
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.borderPrimary
            }

            /**
             * @brief RowLayout untuk mengatur kolom header.
             */
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.paddingHuge
                anchors.rightMargin: Theme.paddingHuge
                spacing: 0

                //=============================================================
                // DATE/TIME COLUMN HEADER - Header kolom tanggal/waktu
                //=============================================================

                /**
                 * @brief Header kolom DATE/TIME yang dapat diklik untuk sorting.
                 *
                 * @details Ketika diklik:
                 * - Jika sudah aktif: Toggle arah sorting (asc/desc)
                 * - Jika belum aktif: Set sebagai sort field dengan default descending
                 */
                Item {
                    Layout.preferredWidth: 200
                    Layout.fillHeight: true

                    /**
                     * @brief Row untuk label dan ikon chevron sorting.
                     */
                    RowLayout {
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 5

                        /**
                         * @brief Label "DATE/TIME" dengan highlight jika aktif.
                         */
                        Text {
                            text: "DATE/TIME"
                            color: MultiplayerHistoryManager.sortBy === "date" ? Theme.accentBlue : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: true
                        }

                        /**
                         * @brief Ikon chevron menunjukkan arah sorting.
                         *
                         * @details Hanya terlihat jika kolom ini aktif untuk sorting.
                         */
                        Image {
                            source: MultiplayerHistoryManager.sortAscending ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            visible: MultiplayerHistoryManager.sortBy === "date"
                            opacity: 0.7

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: Theme.accentBlue
                            }
                        }
                    }

                    /**
                     * @brief MouseArea untuk menangani klik pada header kolom.
                     */
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (MultiplayerHistoryManager.sortBy === "date") {
                                // Toggle arah sorting jika sudah aktif
                                MultiplayerHistoryManager.sortAscending = !MultiplayerHistoryManager.sortAscending;
                            } else {
                                // Set sebagai sort field dengan default descending (terbaru pertama)
                                MultiplayerHistoryManager.sortBy = "date";
                                MultiplayerHistoryManager.sortAscending = false;
                            }
                        }
                    }
                }

                //=============================================================
                // HOST COLUMN HEADER - Header kolom host (tidak sortable)
                //=============================================================

                /**
                 * @brief Header kolom HOST (tidak dapat diurutkan).
                 */
                Text {
                    Layout.fillWidth: true
                    text: "HOST"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                }

                //=============================================================
                // LANG COLUMN HEADER - Header kolom bahasa (clickable filter)
                //=============================================================

                /**
                 * @brief Header kolom LANG dengan dropdown filter.
                 *
                 * @details Klik untuk membuka dropdown filter bahasa.
                 * Menampilkan filter aktif: ALL, ID, EN, atau PROG.
                 */
                Item {
                    id: langHeaderItem
                    Layout.preferredWidth: 60
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: mpHistoryPage.getLanguageLabel(MultiplayerHistoryManager.filterLanguage)
                            color: MultiplayerHistoryManager.filterLanguage !== "all" ? Theme.accentBlue : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: true
                        }

                        Image {
                            id: langFilterIcon
                            source: mpHistoryPage.langFilterPopupVisible ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            opacity: 0.7
                            visible: true

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: MultiplayerHistoryManager.filterLanguage !== "all" ? Theme.accentBlue : Theme.textSecondary
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Update global position before showing popup
                            var globalPos = langHeaderItem.mapToItem(mpHistoryPage, 0, langHeaderItem.height);
                            mpHistoryPage.langHeaderGlobalX = globalPos.x;
                            mpHistoryPage.langHeaderGlobalY = globalPos.y;
                            mpHistoryPage.langFilterPopupVisible = !mpHistoryPage.langFilterPopupVisible;
                        }
                    }
                }

                //=============================================================
                // YOUR RANK COLUMN HEADER - Header kolom peringkat
                //=============================================================

                /**
                 * @brief Header kolom YOUR RANK yang dapat diklik untuk sorting.
                 *
                 * @details Ketika diklik:
                 * - Jika sudah aktif: Toggle arah sorting
                 * - Jika belum aktif: Set sebagai sort field dengan default ascending
                 *   (peringkat 1 adalah yang terbaik, jadi angka kecil dulu)
                 */
                Item {
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "YOUR RANK"
                            color: MultiplayerHistoryManager.sortBy === "rank" ? Theme.accentBlue : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                        }

                        Image {
                            source: MultiplayerHistoryManager.sortAscending ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            visible: MultiplayerHistoryManager.sortBy === "rank"
                            opacity: 0.7

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: Theme.accentBlue
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (MultiplayerHistoryManager.sortBy === "rank") {
                                MultiplayerHistoryManager.sortAscending = !MultiplayerHistoryManager.sortAscending;
                            } else {
                                MultiplayerHistoryManager.sortBy = "rank";
                                MultiplayerHistoryManager.sortAscending = true; // Ascending: 1st is best
                            }
                        }
                    }
                }

                //=============================================================
                // YOUR WPM COLUMN HEADER - Header kolom WPM
                //=============================================================

                /**
                 * @brief Header kolom YOUR WPM yang dapat diklik untuk sorting.
                 *
                 * @details Ketika diklik:
                 * - Jika sudah aktif: Toggle arah sorting
                 * - Jika belum aktif: Set sebagai sort field dengan default descending
                 *   (WPM tinggi adalah yang terbaik)
                 */
                Item {
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "YOUR WPM"
                            color: MultiplayerHistoryManager.sortBy === "wpm" ? Theme.accentBlue : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                        }

                        Image {
                            source: MultiplayerHistoryManager.sortAscending ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                            sourceSize.width: 14
                            sourceSize.height: 14
                            visible: MultiplayerHistoryManager.sortBy === "wpm"
                            opacity: 0.7

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: Theme.accentBlue
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (MultiplayerHistoryManager.sortBy === "wpm") {
                                MultiplayerHistoryManager.sortAscending = !MultiplayerHistoryManager.sortAscending;
                            } else {
                                MultiplayerHistoryManager.sortBy = "wpm";
                                MultiplayerHistoryManager.sortAscending = false; // Descending: Higher is better
                            }
                        }
                    }
                }
            }
        }

        //=====================================================================
        // LIST VIEW AND EMPTY STATE - Konten utama
        //=====================================================================

        /**
         * @brief Container untuk ListView dan empty state.
         *
         * @details Menggunakan Item sebagai container untuk memungkinkan
         * kedua child (ListView dan empty state) mengisi ruang yang sama
         * dengan visibility yang saling eksklusif.
         */
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            //=================================================================
            // LIST VIEW - Daftar riwayat pertandingan
            //=================================================================

            /**
             * @brief ListView untuk menampilkan daftar riwayat pertandingan.
             *
             * @details Hanya terlihat jika ada data riwayat (totalEntries > 0).
             * Setiap item dapat di-expand untuk melihat detail semua pemain.
             */
            ListView {
                id: historyList
                width: parent.width
                height: parent.height
                clip: true  ///< Memotong konten yang melewati batas
                model: mpHistoryPage.historyData
                spacing: 5
                visible: mpHistoryPage.totalEntries > 0

                /**
                 * @brief Delegate untuk setiap item riwayat.
                 *
                 * @details Setiap delegate berisi:
                 * - Main row dengan info ringkas (timestamp, host, rank, WPM)
                 * - Expandable details dengan daftar semua pemain
                 * - Indikator warna berdasarkan peringkat
                 * - Animasi expand/collapse
                 */
                delegate: Rectangle {
                    id: delegateItem
                    width: ListView.view.width
                    height: isExpanded ? (40 + playersList.height + 20) : 40  ///< Tinggi dinamis berdasarkan state
                    color: isExpanded ? Theme.bgSecondary : (mouseArea.containsMouse ? Theme.bgHover : "transparent")

                    /**
                     * @brief Animasi untuk perubahan tinggi saat expand/collapse.
                     */
                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }

                    /**
                     * @property isExpanded
                     * @brief State apakah detail pemain sedang ditampilkan.
                     */
                    property bool isExpanded: false

                    /**
                     * @brief Garis pembatas di bagian bawah item.
                     *
                     * @details Hanya terlihat saat item tidak di-expand.
                     */
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.borderPrimary
                        visible: !isExpanded
                        opacity: 0.5
                    }

                    //=========================================================
                    // RANK INDICATOR - Indikator warna peringkat
                    //=========================================================

                    /**
                     * @brief Indikator warna vertikal berdasarkan peringkat pemain lokal.
                     *
                     * @details Warna berdasarkan peringkat:
                     * - Peringkat 1: Kuning (accentYellow) - Juara
                     * - Peringkat 2-3: Hijau (accentGreen) - Podium
                     * - Peringkat lainnya: Abu-abu (textMuted)
                     */
                    Rectangle {
                        width: 3
                        height: 40
                        color: (modelData.localRank === 1) ? Theme.accentYellow : ((modelData.localRank <= 3) ? Theme.accentGreen : Theme.textMuted)
                    }

                    //=========================================================
                    // MAIN ROW - Baris utama dengan info ringkas
                    //=========================================================

                    /**
                     * @brief RowLayout untuk menampilkan informasi ringkas pertandingan.
                     *
                     * @details Kolom:
                     * 1. Timestamp (tanggal dan waktu)
                     * 2. Host name (nama pembuat room)
                     * 3. Local rank (peringkat pemain lokal)
                     * 4. Local WPM (kecepatan mengetik pemain lokal)
                     */
                    RowLayout {
                        id: mainRow
                        height: 40
                        width: parent.width
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingHuge
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingHuge
                        spacing: 0

                        /**
                         * @brief Kolom timestamp (tanggal/waktu pertandingan).
                         */
                        Text {
                            Layout.preferredWidth: 200
                            text: modelData.timestamp
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }

                        /**
                         * @brief Kolom host name dengan warna aksen biru.
                         */
                        Text {
                            Layout.fillWidth: true
                            text: modelData.hostName
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            elide: Text.ElideRight  ///< Potong teks panjang dengan ...
                        }

                        /**
                         * @brief Kolom bahasa game.
                         */
                        Text {
                            Layout.preferredWidth: 60
                            text: modelData.language ? modelData.language.toUpperCase() : "—"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            horizontalAlignment: Text.AlignHCenter
                        }

                        /**
                         * @brief Kolom peringkat pemain lokal.
                         *
                         * @details Format: "#X" dimana X adalah posisi.
                         * Warna kuning untuk peringkat 1.
                         */
                        Text {
                            Layout.preferredWidth: 100
                            text: "#" + modelData.localRank
                            color: (modelData.localRank === 1) ? Theme.accentYellow : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: true
                        }

                        /**
                         * @brief Kolom WPM pemain lokal dengan warna hijau.
                         */
                        Text {
                            Layout.preferredWidth: 100
                            text: modelData.localWpm
                            color: Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: true
                        }
                    }

                    /**
                     * @brief MouseArea untuk menangani klik expand/collapse.
                     */
                    MouseArea {
                        id: mouseArea
                        anchors.fill: mainRow
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: delegateItem.isExpanded = !delegateItem.isExpanded
                    }

                    //=========================================================
                    // EXPANDED DETAILS - Detail pemain yang dapat di-expand
                    //=========================================================

                    /**
                     * @brief Rectangle container untuk detail pemain yang di-expand.
                     *
                     * @details Menampilkan daftar semua pemain dalam pertandingan
                     * dengan informasi lengkap: posisi, nama, WPM, akurasi, dan error.
                     */
                    Rectangle {
                        id: detailsRect
                        anchors.top: mainRow.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        color: Theme.bgSecondary
                        visible: delegateItem.isExpanded
                        opacity: delegateItem.isExpanded ? 1 : 0

                        /**
                         * @brief Garis pembatas di bagian atas details.
                         */
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            opacity: 0.5
                        }

                        /**
                         * @brief ColumnLayout untuk daftar pemain.
                         *
                         * @details Struktur:
                         * 1. Header row (label kolom)
                         * 2. Separator
                         * 3. Repeater untuk setiap pemain
                         */
                        ColumnLayout {
                            id: playersList
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: 12

                            //=================================================
                            // PLAYER RESULTS HEADER - Header tabel pemain
                            //=================================================

                            /**
                             * @brief Row header untuk kolom detail pemain.
                             */
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                opacity: 0.7

                                /**
                                 * @brief Label kolom posisi/peringkat.
                                 */
                                Text {
                                    Layout.preferredWidth: 30
                                    text: "#"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                }

                                /**
                                 * @brief Label kolom nama pemain.
                                 */
                                Text {
                                    Layout.fillWidth: true
                                    text: "PLAYER"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                }

                                /**
                                 * @brief Label kolom WPM.
                                 */
                                Text {
                                    Layout.preferredWidth: 80
                                    text: "WPM"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    horizontalAlignment: Text.AlignRight
                                    font.bold: true
                                }

                                /**
                                 * @brief Label kolom akurasi.
                                 */
                                Text {
                                    Layout.preferredWidth: 60
                                    text: "ACCURACY"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    horizontalAlignment: Text.AlignRight
                                    font.bold: true
                                }

                                /**
                                 * @brief Label kolom error.
                                 */
                                Text {
                                    Layout.preferredWidth: 80
                                    text: "ERROR"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    horizontalAlignment: Text.AlignRight
                                    font.bold: true
                                }
                            }

                            /**
                             * @brief Garis pemisah antara header dan data pemain.
                             */
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.borderSecondary
                                opacity: 0.5
                            }

                            //=================================================
                            // PLAYER LIST - Daftar pemain
                            //=================================================

                            /**
                             * @brief Repeater untuk menampilkan setiap pemain.
                             *
                             * @details Setiap row menampilkan:
                             * - Posisi (dengan warna kuning untuk juara)
                             * - Nama (dengan tag "(You)" untuk pemain lokal, "[Left]" jika disconnect)
                             * - WPM
                             * - Akurasi (dalam persen)
                             * - Jumlah error (warna merah jika > 0)
                             */
                            Repeater {
                                model: modelData.players
                                delegate: RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    /**
                                     * @brief Kolom posisi pemain.
                                     *
                                     * @details Warna kuning untuk posisi 1 (juara).
                                     */
                                    Text {
                                        Layout.preferredWidth: 30
                                        text: modelData.position
                                        color: (modelData.position === 1) ? Theme.accentYellow : Theme.textSecondary
                                        font.family: Theme.fontFamily
                                    }

                                    /**
                                     * @brief Kolom nama pemain dengan indikator status.
                                     *
                                     * @details Menampilkan:
                                     * - Nama pemain
                                     * - "(You)" jika pemain lokal
                                     * - "[Left]" jika pemain disconnect sebelum selesai
                                     *
                                     * Warna biru dan bold untuk pemain lokal.
                                     */
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.hasLeft ? " [Left]" : "")
                                        color: modelData.isLocal ? Theme.accentBlue : Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.bold: modelData.isLocal
                                    }

                                    /**
                                     * @brief Kolom WPM pemain dengan satuan.
                                     */
                                    Text {
                                        Layout.preferredWidth: 80
                                        text: modelData.wpm + " WPM"
                                        color: Theme.accentGreen
                                        font.family: Theme.fontFamily
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    /**
                                     * @brief Kolom akurasi pemain dalam persen.
                                     */
                                    Text {
                                        Layout.preferredWidth: 60
                                        text: modelData.accuracy.toFixed(1) + "%"
                                        color: Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    /**
                                     * @brief Kolom jumlah error pemain.
                                     *
                                     * @details Warna merah jika ada error (> 0).
                                     */
                                    Text {
                                        Layout.preferredWidth: 80
                                        text: modelData.errors + " err"
                                        color: (modelData.errors > 0) ? Theme.accentRed : Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //=================================================================
            // EMPTY STATE - Tampilan saat tidak ada riwayat
            //=================================================================

            /**
             * @brief Column untuk empty state placeholder.
             *
             * @details Ditampilkan saat totalEntries === 0.
             * Berisi ikon, judul, dan subtitle informatif.
             */
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingM
                visible: mpHistoryPage.totalEntries === 0

                /**
                 * @brief Container untuk ikon empty state.
                 */
                Item {
                    width: 64
                    height: 64
                    anchors.horizontalCenter: parent.horizontalCenter

                    /**
                     * @brief Image ikon history (hidden, digunakan sebagai source overlay).
                     */
                    Image {
                        id: emptyIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(64, 64)
                        visible: false
                    }

                    /**
                     * @brief ColorOverlay untuk mewarnai ikon dengan warna muted.
                     */
                    ColorOverlay {
                        anchors.fill: emptyIcon
                        source: emptyIcon
                        color: Theme.textMuted
                        opacity: 0.5
                    }
                }

                /**
                 * @brief Judul empty state.
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No multiplayer matches yet"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                }

                /**
                 * @brief Subtitle empty state dengan instruksi.
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Play a match to see your history here"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    opacity: 0.7
                }
            }
        }

        //=====================================================================
        // FOOTER NAVIGATION - Tombol navigasi di bagian bawah
        //=====================================================================

        /**
         * @brief Row untuk tombol navigasi footer.
         *
         * @details Berisi dua tombol:
         * 1. Back: Kembali ke menu sebelumnya (shortcut: ESC)
         * 2. Clear History: Menghapus semua riwayat (shortcut: C)
         */
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            spacing: Theme.spacingM

            /**
             * @brief Tombol Back untuk kembali ke menu sebelumnya.
             */
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back (ESC)"
                onClicked: mpHistoryPage.backClicked()
            }

            /**
             * @brief Tombol Clear History untuk menghapus semua riwayat.
             *
             * @details Menggunakan variant "danger" untuk menandakan
             * aksi destruktif yang tidak dapat di-undo.
             */
            NavBtn {
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                labelText: "Clear History (C)"
                variant: "danger"  ///< Variant merah untuk aksi berbahaya
                onClicked: {
                    mpHistoryPage.clearHistoryClicked();
                }
            }
        }
    }

    /**
     * @brief Language filter popup overlay.
     *
     * @details Popup ditampilkan di level halaman dengan z-index tinggi
     * untuk memastikan tampil di atas semua elemen termasuk ListView.
     */
    Rectangle {
        id: langFilterPopup
        visible: mpHistoryPage.langFilterPopupVisible
        x: mpHistoryPage.langHeaderGlobalX
        y: mpHistoryPage.langHeaderGlobalY + 4
        width: 70
        height: langFilterColumn.height + 8
        color: Theme.bgSecondary
        border.color: Theme.borderPrimary
        border.width: 1
        radius: 4
        z: 1000

        // MouseArea untuk memblok hover events ke elemen di belakang popup
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            // Hanya untuk memblok propagation, tidak melakukan apa-apa
        }

        Column {
            id: langFilterColumn
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 2

            Repeater {
                model: ["all", "id", "en", "prog"]
                delegate: Rectangle {
                    width: langFilterColumn.width
                    height: 26
                    color: langOptionMouseArea.containsMouse ? Theme.bgHover : "transparent"
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: mpHistoryPage.getLanguageLabel(modelData)
                        color: MultiplayerHistoryManager.filterLanguage === modelData ? Theme.accentBlue : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        font.bold: MultiplayerHistoryManager.filterLanguage === modelData
                    }

                    MouseArea {
                        id: langOptionMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            MultiplayerHistoryManager.filterLanguage = modelData;
                            mpHistoryPage.langFilterPopupVisible = false;
                        }
                    }
                }
            }
        }
    }

    // Click-away handler untuk menutup popup
    MouseArea {
        anchors.fill: parent
        visible: mpHistoryPage.langFilterPopupVisible
        z: 999
        onClicked: {
            mpHistoryPage.langFilterPopupVisible = false;
        }
    }
}
