/**
 * @file LobbyPage.qml
 * @brief Halaman ruang tunggu/lobby untuk permainan multiplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menampilkan ruang tunggu sebelum race multiplayer dimulai.
 * Halaman ini berfungsi sebagai tempat berkumpul pemain sebelum host memulai permainan.
 *
 * @par Fitur Utama:
 * - Daftar pemain yang terhubung (maksimal 8 pemain)
 * - Pemilihan bahasa teks race (ID/EN/PROG) - hanya host
 * - Preview teks yang akan digunakan untuk race
 * - Pemilihan network interface untuk hosting
 * - Kemampuan kick pemain (hanya host)
 * - Tombol Start Race (hanya host)
 *
 * @par Perbedaan Host vs Guest:
 * | Fitur | Host | Guest |
 * |-------|------|-------|
 * | Pilih bahasa | ✓ | ✗ |
 * | Refresh teks | ✓ | ✗ |
 * | Start race | ✓ | ✗ |
 * | Kick pemain | ✓ | ✗ |
 * | Lihat IP server | ✓ | ✗ |
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Enter/Return | Mulai race (host saja) |
 * | Escape | Keluar dari lobby |
 *
 * @see NetworkManager Untuk logika multiplayer dan networking
 * @see MultiplayerRacePage Halaman race setelah countdown selesai
 * @see MultiplayerMenuPage Menu untuk membuat/join room
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen halaman lobby multiplayer.
 * @inherits FocusScope
 *
 * @details FocusScope ini berfungsi sebagai container utama untuk halaman lobby.
 * Menggunakan FocusScope (bukan Rectangle) untuk menangani fokus keyboard
 * dengan benar pada komponen-komponen child seperti dialog.
 *
 * @par Alur Penggunaan:
 * 1. User membuat atau bergabung ke room multiplayer
 * 2. Halaman lobby ditampilkan dengan daftar pemain
 * 3. Host mengatur pengaturan permainan (bahasa, teks)
 * 4. Host menekan Start Race untuk memulai countdown
 * 5. Semua pemain transisi ke MultiplayerRacePage
 */
FocusScope {
    id: lobbyPage
    focus: true

    /* ========================================================================
     * PROPERTI DATA DARI NETWORK MANAGER
     * ======================================================================== */

    /**
     * @property isHost
     * @brief Menandakan apakah user lokal adalah host room.
     * @type bool
     *
     * @details Properti ini menentukan UI mana yang ditampilkan.
     * Host memiliki kontrol penuh atas pengaturan permainan.
     */
    property bool isHost: NetworkManager.isAuthority

    /**
     * @property players
     * @brief Daftar pemain yang terhubung ke room.
     * @type var (QVariantList)
     *
     * @details Setiap item dalam list berisi:
     * - id: UUID pemain
     * - name: Nama pemain
     * - isLocal: Apakah ini pemain lokal
     * - isHost: Apakah pemain ini adalah host
     */
    property var players: NetworkManager.players

    /**
     * @property gameText
     * @brief Teks yang akan digunakan untuk race.
     * @type string
     *
     * @details Teks ini di-generate oleh TextProvider berdasarkan
     * bahasa yang dipilih. Host dapat me-refresh teks kapan saja.
     */
    property string gameText: NetworkManager.gameText

    /**
     * @property gameLanguage
     * @brief Kode bahasa yang dipilih untuk race.
     * @type string
     * @default "id"
     *
     * @details Nilai yang valid: "id" (Indonesia), "en" (English), "prog" (Programming)
     */
    property string gameLanguage: NetworkManager.gameLanguage

    /**
     * @property selectedInterface
     * @brief IP address interface jaringan yang dipilih untuk hosting.
     * @type string
     *
     * @details Hanya relevan untuk host. Menentukan IP mana yang
     * digunakan untuk menerima koneksi dari guest.
     */
    property string selectedInterface: NetworkManager.selectedInterface

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal startGameClicked
     * @brief Dipancarkan ketika race dimulai (setelah countdown).
     *
     * @details Signal ini di-emit oleh Connections handler saat
     * NetworkManager.onCountdownStarted() dipanggil. Berlaku untuk
     * host DAN guest karena keduanya harus transisi ke race page.
     */
    signal startGameClicked

    /**
     * @signal leaveClicked
     * @brief Dipancarkan ketika user meninggalkan lobby.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Leave
     * - User di-kick oleh host dan menekan OK
     *
     * Parent component harus menangani signal ini untuk navigasi.
     */
    signal leaveClicked

    /**
     * @signal textChanged
     * @brief Dipancarkan ketika teks race berubah.
     * @param text string Teks baru untuk race.
     *
     * @details Signal ini digunakan untuk sinkronisasi teks antar pemain.
     */
    signal textChanged(string text)

    /* ========================================================================
     * HELPER FUNCTIONS FOR KEYBOARD SHORTCUTS
     * ======================================================================== */

    /**
     * @brief Cycle ke interface berikutnya dalam daftar.
     * @details Digunakan oleh shortcut [I] untuk host.
     */
    function cycleInterface() {
        var interfaces = NetworkManager.availableInterfaces;
        if (interfaces.length === 0)
            return;

        var currentIndex = 0;
        for (var i = 0; i < interfaces.length; i++) {
            if (interfaces[i].ip === selectedInterface) {
                currentIndex = i;
                break;
            }
        }
        var nextIndex = (currentIndex + 1) % interfaces.length;
        NetworkManager.setSelectedInterface(interfaces[nextIndex].ip);
    }

    /**
     * @brief Cycle bahasa ke pilihan berikutnya.
     * @details Digunakan oleh shortcut [L] untuk host.
     * Urutan: id -> en -> prog -> id
     */
    function cycleLanguage() {
        var langs = ["id", "en", "prog"];
        var currentIndex = langs.indexOf(gameLanguage);
        if (currentIndex === -1)
            currentIndex = 0;
        var nextIndex = (currentIndex + 1) % langs.length;
        NetworkManager.setGameLanguage(langs[nextIndex]);
    }

    /**
     * @brief Background utama halaman lobby.
     * @details Rectangle dengan z-index rendah untuk memastikan
     * konten lain tampil di atasnya.
     */
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    /* ========================================================================
     * STATE DIALOG KICK PEMAIN
     * ======================================================================== */

    /**
     * @property pendingKickUuid
     * @brief UUID pemain yang akan di-kick (menunggu konfirmasi).
     * @type string
     *
     * @details Jika tidak kosong, dialog konfirmasi kick akan ditampilkan.
     * Dikosongkan saat user membatalkan atau mengkonfirmasi kick.
     */
    property string pendingKickUuid: ""

    /**
     * @property pendingKickName
     * @brief Nama pemain yang akan di-kick (untuk tampilan dialog).
     * @type string
     */
    property string pendingKickName: ""

    /**
     * @brief Dialog konfirmasi untuk kick pemain.
     *
     * @details Dialog modal yang muncul saat host mengklik tombol kick
     * pada salah satu pemain. Menampilkan konfirmasi sebelum benar-benar
     * mengeluarkan pemain dari room.
     *
     * @par Visual Elements:
     * - Overlay gelap semi-transparan
     * - Dialog box dengan judul, pesan, dan tombol Cancel/Kick
     * - Tombol Kick berwarna merah untuk emphasis
     */
    Rectangle {
        id: kickConfirmDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: pendingKickUuid !== ""
        z: 1000
        focus: visible

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                NetworkManager.kickPlayer(pendingKickUuid);
                pendingKickUuid = "";
                pendingKickName = "";
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                pendingKickUuid = "";
                pendingKickName = "";
                event.accepted = true;
            }
        }

        /// @brief Klik di luar dialog untuk menutup
        MouseArea {
            anchors.fill: parent
            onClicked: {
                pendingKickUuid = "";
                pendingKickName = "";
            }
        }

        /// @brief Kotak dialog utama
        Rectangle {
            anchors.centerIn: parent
            width: 300
            height: 150
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            /// @brief Mencegah klik menutup dialog saat klik di dalam kotak
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from closing dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                /// @brief Judul dialog
                Text {
                    Layout.fillWidth: true
                    text: "Kick Player"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                /// @brief Pesan konfirmasi dengan nama pemain
                Text {
                    Layout.fillWidth: true
                    text: "Remove " + pendingKickName + " from room?"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                /// @brief Baris tombol aksi
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    /// @brief Tombol Cancel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.bgTertiary
                        border.color: Theme.borderPrimary

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel (ESC)"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pendingKickUuid = "";
                                pendingKickName = "";
                            }
                        }
                    }

                    /// @brief Tombol Kick (merah)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.accentRed

                        Text {
                            anchors.centerIn: parent
                            text: "Kick (Enter)"
                            color: "white"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkManager.kickPlayer(pendingKickUuid);
                                pendingKickUuid = "";
                                pendingKickName = "";
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * @brief Dialog konfirmasi untuk bermain solo (hanya host).
     *
     * @details Dialog ini muncul saat host mencoba memulai race dengan
     * hanya satu pemain (diri sendiri). Memberikan konfirmasi karena
     * multiplayer dengan satu pemain tidak umum.
     *
     * @par Visual Elements:
     * - Overlay gelap semi-transparan
     * - Dialog box dengan judul, pesan, dan tombol Cancel/Start
     * - Tombol Start berwarna biru
     */
    Rectangle {
        id: soloPlayConfirmDialog
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: false
        z: 1000
        focus: visible

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                soloPlayConfirmDialog.visible = false;
                NetworkManager.startCountdown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                soloPlayConfirmDialog.visible = false;
                event.accepted = true;
            }
        }

        /// @brief Klik di luar dialog untuk menutup
        MouseArea {
            anchors.fill: parent
            onClicked: soloPlayConfirmDialog.visible = false
        }

        /// @brief Kotak dialog utama
        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 180
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            /// @brief Mencegah klik menutup dialog
            MouseArea {
                anchors.fill: parent
                // Prevent clicks from closing dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                /// @brief Judul dialog
                Text {
                    Layout.fillWidth: true
                    text: "Start Solo Race?"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                /// @brief Pesan konfirmasi
                Text {
                    Layout.fillWidth: true
                    text: "There's only you in the race, continue?"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                /// @brief Baris tombol aksi
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    /// @brief Tombol Cancel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.bgTertiary
                        border.color: Theme.borderPrimary

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel (ESC)"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: soloPlayConfirmDialog.visible = false
                        }
                    }

                    /// @brief Tombol Start (biru)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.accentBlue

                        Text {
                            anchors.centerIn: parent
                            text: "Start (Enter)"
                            color: "white"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                soloPlayConfirmDialog.visible = false;
                                NetworkManager.startCountdown();
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 550)
        height: contentCol.implicitHeight

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            // Header with role badge
            Column {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "WAITING ROOM"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                    font.bold: true
                }

                // Role badge row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Rectangle {
                        width: roleBadgeText.width + 16
                        height: 24
                        radius: 4
                        color: isHost ? Qt.rgba(0.24, 0.72, 0.31, 0.2) : Qt.rgba(0.34, 0.65, 1, 0.2)
                        border.color: isHost ? Theme.accentGreen : Theme.accentBlue
                        border.width: 1

                        Text {
                            id: roleBadgeText
                            anchors.centerIn: parent
                            text: isHost ? "★ HOST" : "GUEST"
                            color: isHost ? Theme.accentGreen : Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: isHost ? "You control the game" : "Host controls the game"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }
                }
            }

            // Server IP list (for host)
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.preferredHeight: NetworkManager.availableInterfaces.length === 0 ? 80 : Math.min(NetworkManager.availableInterfaces.length * 40 + 36, 130)
                color: "transparent"
                border.color: NetworkManager.availableInterfaces.length === 0 ? Theme.accentRed : Theme.borderPrimary
                border.width: 1
                visible: isHost

                // Warning when no interfaces available
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: NetworkManager.availableInterfaces.length === 0

                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: warningIcon
                            anchors.fill: parent
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                            sourceSize: Qt.size(20, 20)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: warningIcon
                            source: warningIcon
                            color: Theme.accentRed
                        }
                    }

                    Text {
                        text: "No network detected. Connect to a local network."
                        color: Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Header
                Rectangle {
                    id: ipHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 32
                    color: Theme.bgSecondary
                    visible: NetworkManager.availableInterfaces.length > 0

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: globeIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: globeIcon
                                source: globeIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "YOUR IP (Share with friends)"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }

                        Text {
                            text: "[I]"
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            visible: isHost
                        }
                    }
                }

                // IP list
                ListView {
                    anchors.top: ipHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true
                    visible: NetworkManager.availableInterfaces.length > 0

                    model: NetworkManager.availableInterfaces

                    ScrollBar.vertical: ScrollBar {
                        id: ipListScrollBar
                        policy: ScrollBar.AsNeeded
                        width: 8
                        hoverEnabled: true
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: ipListScrollBar.pressed ? "#6A6A6A" : "#4A4A4A"
                            opacity: ipListScrollBar.hovered || ipListScrollBar.pressed ? 1.0 : 0.6

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: interfaceDelegate
                        width: parent ? parent.width : 0
                        height: 42

                        // Highlight selected interface or hover
                        property bool isSelected: selectedInterface === modelData.ip || (selectedInterface === "" && index === 0)
                        color: isSelected ? Qt.rgba(0.34, 0.65, 1, 0.15) : interfaceMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Selection indicator (radio button style)
                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: "transparent"
                                border.color: interfaceDelegate.isSelected ? Theme.accentBlue : Theme.borderSecondary
                                border.width: 2

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: Theme.accentBlue
                                    visible: interfaceDelegate.isSelected
                                }
                            }

                            // Type badge (Ethernet/WiFi)
                            Rectangle {
                                width: 70
                                height: 22
                                color: modelData.type === "Ethernet" ? Qt.rgba(0.15, 0.85, 0.5, 0.12) : modelData.type === "WiFi" ? Qt.rgba(0.34, 0.65, 1, 0.12) : Qt.rgba(0.5, 0.5, 0.5, 0.12)
                                border.color: modelData.type === "Ethernet" ? Theme.accentGreen : modelData.type === "WiFi" ? Theme.accentBlue : Theme.textMuted
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.type
                                    color: modelData.type === "Ethernet" ? Theme.accentGreen : modelData.type === "WiFi" ? Theme.accentBlue : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            // IP address
                            Text {
                                Layout.fillWidth: true
                                text: modelData.ip
                                color: interfaceDelegate.isSelected ? Theme.accentBlue : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: interfaceDelegate.isSelected
                            }

                            // Active badge for selected
                            Rectangle {
                                width: 60
                                height: 20
                                color: Theme.accentBlue
                                visible: interfaceDelegate.isSelected

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    color: Theme.bgPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // Click handler
                        MouseArea {
                            id: interfaceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkManager.setSelectedInterface(modelData.ip);
                            }
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < NetworkManager.availableInterfaces.length - 1
                        }
                    }
                }
            }

            /**
             * @brief Container daftar pemain yang terhubung.
             *
             * @details Menampilkan semua pemain yang ada di room dengan
             * informasi nama, status host, dan tombol kick (untuk host).
             * Maksimal 8 pemain dapat terhubung.
             *
             * @par Visual Elements:
             * - Header dengan judul "PLAYERS (X/8)"
             * - ListView dengan delegate untuk setiap pemain
             * - Highlight biru untuk pemain lokal
             * - Tombol kick merah untuk host
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(players.length * 44 + 44, 220)
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                /// @brief Header daftar pemain
                Rectangle {
                    id: playersHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            Image {
                                id: usersIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: usersIcon
                                source: usersIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "PLAYERS (" + players.length + "/8)"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }
                    }
                }

                /**
                 * @brief ListView untuk daftar pemain.
                 *
                 * @details Setiap item menampilkan:
                 * - Ikon user (biru untuk lokal, abu-abu untuk remote)
                 * - Nama pemain dengan suffix "(You)" dan/atau "- Host"
                 * - Ikon check hijau (ready indicator)
                 * - Tombol kick merah (hanya visible untuk host)
                 */
                ListView {
                    anchors.top: playersHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true

                    model: players

                    ScrollBar.vertical: ScrollBar {
                        id: playerListScrollBar
                        policy: ScrollBar.AsNeeded
                        width: 8
                        hoverEnabled: true
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: playerListScrollBar.pressed ? "#6A6A6A" : "#4A4A4A"
                            opacity: playerListScrollBar.hovered || playerListScrollBar.pressed ? 1.0 : 0.6

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    /// @brief Delegate untuk setiap pemain
                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: modelData.isLocal ? Qt.rgba(0.34, 0.65, 1, 0.1) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Item {
                                width: 16
                                height: 16
                                Image {
                                    id: userIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/user.svg"
                                    sourceSize: Qt.size(16, 16)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: userIcon
                                    source: userIcon
                                    color: modelData.isLocal ? Theme.accentBlue : Theme.textSecondary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.isHost ? " - Host" : "")
                                color: modelData.isLocal ? Theme.accentBlue : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: modelData.isLocal
                            }

                            // Ready indicator
                            Item {
                                width: 14
                                height: 14
                                Image {
                                    id: checkIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                                    sourceSize: Qt.size(14, 14)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: checkIcon
                                    source: checkIcon
                                    color: Theme.accentGreen
                                }
                            }

                            // Kick button (host only, not for self)
                            Item {
                                width: 14
                                height: 14
                                visible: isHost && !modelData.isLocal

                                Image {
                                    id: kickIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                                    sourceSize: Qt.size(14, 14)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: kickIcon
                                    source: kickIcon
                                    color: Theme.accentRed
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        pendingKickUuid = modelData.id;
                                        pendingKickName = modelData.name;
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < players.length - 1
                        }
                    }
                }
            }

            /**
             * @brief Pemilih bahasa (hanya untuk host).
             *
             * @details Host dapat memilih bahasa teks race dari tiga opsi:
             * - ID: Bahasa Indonesia
             * - EN: Bahasa Inggris
             * - PROG: Kode pemrograman
             *
             * Perubahan bahasa akan otomatis di-sync ke semua guest.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: 50
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1
                visible: isHost

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Text {
                        text: "LANGUAGE:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }

                    Text {
                        text: "[L]"
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }

                    Row {
                        spacing: 8

                        Repeater {
                            model: [
                                {
                                    code: "id",
                                    label: "ID"
                                },
                                {
                                    code: "en",
                                    label: "EN"
                                },
                                {
                                    code: "prog",
                                    label: "PROG"
                                }
                            ]

                            Rectangle {
                                width: 50
                                height: 28
                                color: gameLanguage === modelData.code ? Theme.accentBlue : "transparent"
                                border.color: gameLanguage === modelData.code ? Theme.accentBlue : Theme.borderSecondary
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: gameLanguage === modelData.code ? Theme.bgPrimary : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkManager.setGameLanguage(modelData.code)
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Current: " + gameLanguage.toUpperCase()
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }
                }
            }

            /**
             * @brief Indikator bahasa (untuk guest/non-host).
             *
             * @details Guest tidak dapat mengubah bahasa, hanya melihat
             * bahasa yang dipilih oleh host. Ditampilkan sebagai read-only.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: 36
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1
                visible: !isHost

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "Language:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                    }

                    Text {
                        text: gameLanguage.toUpperCase()
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }
            }

            /**
             * @brief Preview teks yang akan digunakan untuk race.
             *
             * @details Menampilkan preview 80 karakter pertama dari teks race.
             * Host memiliki tombol "Refresh Text" untuk generate teks baru.
             * Guest hanya bisa melihat preview tanpa mengubah.
             *
             * @par States:
             * - Ada teks: Menampilkan preview dengan warna textPrimary
             * - Belum ada teks: Menampilkan "No text set yet..." dengan warna muted
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 16
                Layout.preferredHeight: textPreviewCol.height + 24
                color: Theme.bgSecondary
                border.color: Theme.borderPrimary
                border.width: 1

                Column {
                    id: textPreviewCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    Row {
                        spacing: 8

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            Image {
                                id: terminalIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/terminal.svg"
                                sourceSize: Qt.size(14, 14)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: terminalIcon
                                source: terminalIcon
                                color: Theme.textSecondary
                            }
                        }

                        Text {
                            text: "Race Text"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                            font.bold: true
                        }
                    }

                    Text {
                        width: parent.width
                        text: gameText.length > 0 ? (gameText.substring(0, 80) + (gameText.length > 80 ? "..." : "")) : "No text set yet..."
                        color: gameText.length > 0 ? Theme.textPrimary : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        wrapMode: Text.WordWrap
                    }

                    NavBtn {
                        visible: isHost
                        labelText: "Refresh Text [R]"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                        onClicked: NetworkManager.refreshGameText()
                    }
                }
            }

            /**
             * @brief Baris tombol aksi.
             *
             * @details Berisi tombol navigasi:
             * - Leave: Keluar dari room (semua user)
             * - Start Race: Mulai countdown (hanya host)
             * - Teks waiting: Ditampilkan untuk guest
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 24
                spacing: Theme.spacingM

                /// @brief Tombol Leave untuk keluar dari room
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Leave (ESC)"
                    onClicked: {
                        NetworkManager.leaveRoom();
                        lobbyPage.leaveClicked();
                    }
                }

                /**
                 * @brief Tombol Start Race (hanya host).
                 *
                 * @details Memulai race multiplayer dengan countdown.
                 * - Enabled: Minimal 1 pemain DAN teks sudah tersedia
                 * - Solo: Menampilkan dialog konfirmasi jika hanya 1 pemain
                 * - Multi: Langsung mulai countdown
                 */
                NavBtn {
                    visible: isHost
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                    labelText: "Start Race (Enter)"
                    variant: "primary"
                    enabled: players.length >= 1 && gameText.length > 0
                    onClicked: {
                        if (players.length === 1) {
                            soloPlayConfirmDialog.visible = true;
                        } else {
                            NetworkManager.startCountdown();
                        }
                    }
                }

                /// @brief Teks waiting untuk guest saat menunggu host
                Text {
                    visible: !isHost
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Waiting for host to start..."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                }
            }
        }
    }

    /**
     * @brief Handler inisialisasi saat komponen selesai dimuat.
     *
     * @details Jika user adalah host dan belum ada teks race,
     * otomatis generate teks baru menggunakan NetworkManager.
     */
    Component.onCompleted: {
        if (isHost && gameText.length === 0) {
            NetworkManager.refreshGameText();
        }
    }

    /**
     * @brief Connections untuk signal dari NetworkManager.
     *
     * @details Menangani event networking:
     * - onCountdownStarted: Transisi ke halaman race (host & guest)
     * - onKicked: Menampilkan notifikasi bahwa user di-kick
     */
    Connections {
        target: NetworkManager

        /**
         * @brief Handler saat countdown dimulai oleh host.
         * @param seconds int Durasi countdown dalam detik.
         *
         * @details Signal ini diterima oleh SEMUA pemain (host dan guest).
         * Memicu transisi ke MultiplayerRacePage.
         */
        function onCountdownStarted(seconds) {
            lobbyPage.startGameClicked();
        }

        /**
         * @brief Handler saat user di-kick oleh host.
         *
         * @details Menampilkan dialog notifikasi yang menginformasikan
         * bahwa user telah dikeluarkan dari room oleh host.
         */
        function onKicked() {
            kickedNotification.visible = true;
        }
    }

    /**
     * @brief Overlay notifikasi saat user di-kick dari room.
     *
     * @details Dialog ini muncul saat host mengeluarkan user dari room.
     * User harus menekan OK untuk kembali ke menu multiplayer.
     * Menggunakan z-index tinggi (2000) untuk memastikan tampil di atas segalanya.
     *
     * @par Visual Elements:
     * - Overlay gelap 70% opacity
     * - Dialog dengan judul merah "Kicked from Room"
     * - Tombol OK biru untuk navigasi kembali
     */
    Rectangle {
        id: kickedNotification
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: false
        z: 2000
        focus: visible

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape) {
                kickedNotification.visible = false;
                lobbyPage.leaveClicked();
                event.accepted = true;
            }
        }

        /// @brief Dialog box utama
        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 160
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    Layout.fillWidth: true
                    text: "Kicked from Room"
                    color: Theme.accentRed
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "You have been kicked by the host."
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: Theme.accentBlue

                    Text {
                        anchors.centerIn: parent
                        text: "OK (Enter)"
                        color: "white"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            kickedNotification.visible = false;
                            lobbyPage.leaveClicked();
                        }
                    }
                }
            }
        }
    }

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard global untuk halaman lobby:
     * - Escape: Keluar dari room dan navigasi kembali
     * - Enter/Return (host saja): Mulai race jika kondisi terpenuhi
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     *
     * @note Tombol Enter/Return hanya berfungsi untuk host dan
     * hanya jika minimal ada 1 pemain dan teks sudah tersedia.
     */
    Keys.onPressed: function (event) {
        // Skip jika ada dialog yang visible - biarkan dialog handle sendiri
        if (kickConfirmDialog.visible || soloPlayConfirmDialog.visible || kickedNotification.visible) {
            return;
        }

        if (event.key === Qt.Key_Escape) {
            NetworkManager.leaveRoom();
            lobbyPage.leaveClicked();
            event.accepted = true;
        } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && isHost) {
            if (players.length >= 1 && gameText.length > 0) {
                if (players.length === 1) {
                    soloPlayConfirmDialog.visible = true;
                } else {
                    NetworkManager.startCountdown();
                }
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_I && isHost) {
            // [I] Cycle interface
            cycleInterface();
            event.accepted = true;
        } else if (event.key === Qt.Key_L && isHost) {
            // [L] Cycle language
            cycleLanguage();
            event.accepted = true;
        } else if (event.key === Qt.Key_R && isHost) {
            // [R] Refresh text
            NetworkManager.refreshGameText();
            event.accepted = true;
        }
    }
}
