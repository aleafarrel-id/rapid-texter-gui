/**
 * @file GameBrowserPage.qml
 * @brief Halaman browser game dengan auto-discovery untuk mencari game multiplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menyediakan antarmuka untuk mencari dan bergabung
 * ke permainan multiplayer yang tersedia di jaringan lokal.
 *
 * @par Fitur Utama:
 * - Auto-discovery game di jaringan lokal via UDP broadcast
 * - Daftar game yang ditemukan dengan info host dan status
 * - Input manual IP untuk koneksi langsung
 * - Indikator status koneksi (scanning/connecting)
 * - Overlay error handling
 *
 * @par Proses Discovery:
 * 1. Saat halaman dimuat, NetworkManager.startScanning() dipanggil
 * 2. NetworkManager mengirim UDP broadcast ke jaringan lokal
 * 3. Game yang ditemukan ditampilkan dalam ListView
 * 4. User dapat double-click game untuk bergabung
 * 5. Saat halaman di-destroy, scanning dihentikan
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | Escape | Kembali ke menu |
 * | Ctrl+R | Refresh daftar game |
 *
 * @see NetworkManager Backend untuk discovery dan networking
 * @see LobbyPage Halaman setelah berhasil bergabung
 * @see MultiplayerMenuPage Menu multiplayer utama
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen halaman browser game multiplayer.
 * @inherits FocusScope
 *
 * @details FocusScope ini berfungsi sebagai container utama untuk
 * fitur discovery dan join game multiplayer. Menangani state
 * scanning, connecting, dan error.
 *
 * @par Alur Penggunaan:
 * 1. Halaman dimuat dan mulai scanning otomatis
 * 2. Game yang ditemukan ditampilkan dalam list
 * 3. User double-click game atau input IP manual
 * 4. Loading overlay muncul saat connecting
 * 5. Success: navigasi ke LobbyPage, Fail: tampilkan error
 */
FocusScope {
    id: gameBrowserPage
    focus: true

    /* ========================================================================
     * SIGNAL NAVIGASI
     * ======================================================================== */

    /**
     * @signal gameSelected
     * @brief Dipancarkan ketika user memilih game untuk bergabung.
     * @param hostIp string IP address host game.
     * @param port int Port untuk koneksi.
     *
     * @details Signal ini di-emit ketika:
     * - User double-click game dalam list
     * - User menekan Connect setelah input IP manual
     *
     * Parent component harus memanggil NetworkManager.joinGame().
     */
    signal gameSelected(string hostIp, int port)

    /**
     * @signal joinSuccess
     * @brief Dipancarkan ketika berhasil bergabung ke game.
     *
     * @details Signal ini di-emit oleh Connections handler saat
     * NetworkManager.onJoinSucceeded() dipanggil. Parent harus
     * menavigasi ke LobbyPage.
     */
    signal joinSuccess

    /**
     * @signal backClicked
     * @brief Dipancarkan ketika user menekan tombol kembali.
     *
     * @details Signal ini di-emit ketika:
     * - User menekan tombol Escape
     * - User mengklik tombol Back
     */
    signal backClicked

    /* ========================================================================
     * PROPERTI STATE
     * ======================================================================== */

    /**
     * @property isScanning
     * @brief Menandakan apakah sedang mencari game.
     * @type bool
     *
     * @details Binding dari NetworkManager.isScanning.
     * Digunakan untuk menampilkan animasi scanning.
     */
    property bool isScanning: NetworkManager.isScanning

    /**
     * @property isConnecting
     * @brief Menandakan apakah sedang connecting ke game.
     * @type bool
     *
     * @details Binding dari NetworkManager.isConnecting.
     * Digunakan untuk menampilkan loading overlay.
     */
    property bool isConnecting: NetworkManager.isConnecting

    /**
     * @property discoveredGames
     * @brief Daftar game yang ditemukan.
     * @type var (QVariantList)
     *
     * @details Setiap item berisi:
     * - hostName: Nama host
     * - hostIp: IP address host
     * - port: Port game
     * - playerCount: Jumlah pemain saat ini
     * - maxPlayers: Maksimum pemain
     * - status: "waiting" atau "playing"
     */
    property var discoveredGames: NetworkManager.discoveredRooms

    /**
     * @property errorMsg
     * @brief Pesan error saat koneksi gagal.
     * @type string
     * @default ""
     *
     * @details Jika tidak kosong, error overlay akan ditampilkan.
     */
    property string errorMsg: ""

    /**
     * @brief Connections untuk signal dari NetworkManager.
     *
     * @details Menangani callback dari proses join:
     * - onJoinFailed: Tampilkan error message
     * - onJoinSucceeded: Emit signal joinSuccess
     * - onConnectingChanged: Tampilkan/sembunyikan loading overlay
     */
    Connections {
        target: NetworkManager

        /// @brief Handler saat join gagal
        function onJoinFailed(reason) {
            errorMsg = reason;
            loadingOverlay.visible = false;
        }

        /// @brief Handler saat join berhasil
        function onJoinSucceeded() {
            loadingOverlay.visible = false;
            gameBrowserPage.joinSuccess();
        }

        /// @brief Handler saat status connecting berubah
        function onConnectingChanged() {
            if (NetworkManager.isConnecting) {
                loadingOverlay.visible = true;
                errorMsg = "";
            }
        }
    }

    /**
     * @brief Handler inisialisasi saat komponen dimuat.
     * @details Mulai scanning game otomatis.
     */
    Component.onCompleted: {
        NetworkManager.startScanning();
    }

    /**
     * @brief Handler cleanup saat komponen di-destroy.
     * @details Hentikan scanning untuk menghemat resource.
     */
    Component.onDestruction: {
        NetworkManager.stopScanning();
    }

    /// @brief Background halaman
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    /**
     * @brief Container utama untuk konten browser.
     *
     * @details Item ini berisi seluruh UI browser game,
     * termasuk header, list game, tombol, dan input manual IP.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 550)
        height: contentCol.implicitHeight

        /**
         * @brief Layout kolom utama.
         *
         * @details ColumnLayout ini mengatur susunan vertikal dari:
         * 1. Header "JOIN GAME"
         * 2. Indikator scanning
         * 3. List game yang ditemukan
         * 4. Tombol Refresh dan Back
         * 5. Input manual IP
         */
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            /// @brief Header halaman
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                text: "JOIN GAME"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Indikator status scanning.
             *
             * @details Menampilkan ikon globe berputar dan teks status
             * saat sedang mencari game di jaringan.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 20
                spacing: 10

                /// @brief Ikon scanning dengan animasi rotasi
                Item {
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: scanIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(16, 16)
                        visible: false

                        RotationAnimation on rotation {
                            running: isScanning
                            from: 0
                            to: 360
                            duration: 2000
                            loops: Animation.Infinite
                        }
                    }

                    ColorOverlay {
                        anchors.fill: scanIcon
                        source: scanIcon
                        color: Theme.accentBlue
                        rotation: scanIcon.rotation
                    }
                }

                /// @brief Teks status scanning
                Text {
                    text: isScanning ? "Scanning for games..." : "Scan complete"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                }
            }

            /**
             * @brief Container daftar game.
             *
             * @details Rectangle ini berisi header dan ListView
             * untuk menampilkan game yang ditemukan.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                /// @brief Header daftar game
                Rectangle {
                    id: listHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Text {
                        anchors.centerIn: parent
                        text: "AVAILABLE GAMES (" + discoveredGames.length + ")"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }

                /**
                 * @brief ListView untuk daftar game.
                 *
                 * @details Menampilkan setiap game dengan:
                 * - Ikon gamepad
                 * - Nama host
                 * - Jumlah pemain
                 * - Status (Open/Playing)
                 *
                 * Double-click untuk bergabung ke game.
                 */
                ListView {
                    id: gamesListView
                    anchors.top: listHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    anchors.topMargin: 0
                    clip: true

                    model: discoveredGames

                    ScrollBar.vertical: ScrollBar {
                        id: gamesScrollBar
                        policy: ScrollBar.AsNeeded
                        width: 8
                        hoverEnabled: true
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: gamesScrollBar.pressed ? "#6A6A6A" : "#4A4A4A"
                            opacity: gamesScrollBar.hovered || gamesScrollBar.pressed ? 1.0 : 0.6

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    /// @brief Delegate untuk setiap game
                    delegate: Rectangle {
                        width: gamesListView.width
                        height: 50
                        color: mouseArea.containsMouse ? Theme.bgSecondary : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            /// @brief Ikon gamepad
                            Item {
                                width: 20
                                height: 20
                                Image {
                                    id: gamepadIcon
                                    anchors.fill: parent
                                    source: "qrc:/qt/qml/rapid_texter/assets/icons/gamepad.svg"
                                    sourceSize: Qt.size(20, 20)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: gamepadIcon
                                    source: gamepadIcon
                                    color: Theme.accentBlue
                                }
                            }

                            /// @brief Info game (nama host dan jumlah pemain)
                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.hostName + "'s Game"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeM
                                    font.bold: true
                                }

                                Row {
                                    spacing: 8

                                    Item {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        Image {
                                            id: usersIconSmall
                                            anchors.fill: parent
                                            source: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                                            sourceSize: Qt.size(12, 12)
                                            visible: false
                                        }
                                        ColorOverlay {
                                            anchors.fill: usersIconSmall
                                            source: usersIconSmall
                                            color: Theme.textMuted
                                        }
                                    }

                                    Text {
                                        text: modelData.playerCount + "/" + modelData.maxPlayers
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSM
                                    }
                                }
                            }

                            /**
                             * @brief Indikator status game.
                             *
                             * @details Dot berwarna + teks:
                             * - Hijau "Open": Game bisa di-join
                             * - Kuning "Playing": Game sedang berlangsung
                             */
                            Row {
                                spacing: 6

                                /// @brief Status dot dengan animasi pulse
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.status === "waiting" ? Theme.accentGreen : Theme.accentYellow

                                    SequentialAnimation on opacity {
                                        running: modelData.status === "waiting"
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: 0.4
                                            duration: 800
                                            easing.type: Easing.InOutQuad
                                        }
                                        NumberAnimation {
                                            to: 1.0
                                            duration: 800
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.status === "waiting" ? "Open" : "Playing"
                                    color: modelData.status === "waiting" ? Theme.accentGreen : Theme.accentYellow
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        /// @brief Mouse area untuk double-click join
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onDoubleClicked: {
                                if (modelData.status === "waiting") {
                                    gameBrowserPage.gameSelected(modelData.hostIp, modelData.port);
                                }
                            }
                        }

                        /// @brief Border bawah
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < discoveredGames.length - 1
                        }
                    }

                    /**
                     * @brief Empty state saat tidak ada game.
                     *
                     * @details Menampilkan ikon globe dan teks
                     * saat daftar game kosong.
                     */
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: discoveredGames.length === 0

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 32
                            height: 32

                            Image {
                                id: emptyGlobeIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                                sourceSize: Qt.size(32, 32)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: emptyGlobeIcon
                                source: emptyGlobeIcon
                                color: Theme.textMuted
                                opacity: 0.5
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: isScanning ? "Looking for games..." : "No games found"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                    }
                }
            }

            /// @brief Baris tombol aksi
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                spacing: Theme.spacingM

                /**
                 * @brief Tombol Refresh dengan animasi.
                 *
                 * @details Tombol kuning untuk me-refresh daftar game.
                 * Menampilkan animasi rotasi saat scanning aktif.
                 */
                Rectangle {
                    id: refreshBtn
                    width: 120
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    color: isScanning ? Theme.bgTertiary : Theme.accentYellow
                    border.color: isScanning ? Theme.borderPrimary : "transparent"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: refreshIcon
                                anchors.fill: parent
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                                sourceSize: Qt.size(16, 16)
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: refreshIcon
                                source: refreshIcon
                                color: isScanning ? Theme.textMuted : Theme.bgPrimary

                                RotationAnimation on rotation {
                                    id: spinAnimation
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                    running: isScanning
                                }
                            }
                        }

                        Text {
                            text: isScanning ? "Scanning..." : "Refresh"
                            color: isScanning ? Theme.textMuted : Theme.bgPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkManager.refreshRooms()
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                /// @brief Tombol Back
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                    labelText: "Back (ESC)"
                    onClicked: gameBrowserPage.backClicked()
                }
            }

            /* ================================================================
             * INPUT MANUAL IP
             * ================================================================ */

            /// @brief Separator sebelum input manual
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 24
                height: 1
                color: Theme.borderSecondary
            }

            /// @brief Teks instruksi input manual
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 16
                text: "Can't find the game? Enter IP manually:"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Baris input manual IP dan tombol Connect.
             *
             * @details Fallback untuk koneksi langsung jika
             * auto-discovery tidak menemukan game.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: Theme.spacingM

                /// @brief Container input IP
                Rectangle {
                    width: 180
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.bgSecondary
                    border.color: manualIpInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary
                    border.width: 1

                    TextInput {
                        id: manualIpInput
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        verticalAlignment: Text.AlignVCenter
                        selectByMouse: true

                        /// @brief Placeholder text
                        Text {
                            anchors.fill: parent
                            text: "192.168.1.xxx"
                            color: Theme.textMuted
                            font: parent.font
                            verticalAlignment: Text.AlignVCenter
                            visible: parent.text.length === 0
                        }

                        onAccepted: {
                            if (text.length > 0) {
                                gameBrowserPage.gameSelected(text, 52765);
                            }
                        }
                    }
                }

                /// @brief Tombol Connect
                NavBtn {
                    labelText: "Connect"
                    enabled: manualIpInput.text.length > 0
                    onClicked: {
                        gameBrowserPage.gameSelected(manualIpInput.text, 52765);
                    }
                }
            }
        }
    }

    /**
     * @brief Handler untuk input keyboard.
     *
     * @details Menangani pintasan keyboard:
     * - Escape: Kembali ke menu
     * - Ctrl+R: Refresh daftar game
     *
     * @param event KeyEvent yang berisi informasi tombol yang ditekan.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            gameBrowserPage.backClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
            NetworkManager.refreshRooms();
            event.accepted = true;
        }
    }

    /* ========================================================================
     * OVERLAY LOADING
     * ======================================================================== */

    /**
     * @brief Overlay loading saat connecting.
     *
     * @details Menampilkan animasi loading dan teks "Connecting..."
     * saat sedang mencoba bergabung ke game.
     */
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        z: 100
        visible: false

        Column {
            anchors.centerIn: parent
            spacing: 20

            /// @brief Ikon loading berputar
            Item {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    id: loadIcon
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    anchors.fill: parent
                    sourceSize: Qt.size(48, 48)
                    visible: false

                    RotationAnimation on rotation {
                        running: loadingOverlay.visible
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                ColorOverlay {
                    anchors.fill: loadIcon
                    source: loadIcon
                    color: Theme.accentBlue
                    rotation: loadIcon.rotation
                }
            }

            /// @brief Teks "Connecting..."
            Text {
                text: "Connecting..."
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeL
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    /* ========================================================================
     * OVERLAY ERROR
     * ======================================================================== */

    /**
     * @brief Overlay error saat koneksi gagal.
     *
     * @details Menampilkan dialog dengan pesan error dan tombol Close.
     * Visible jika errorMsg tidak kosong.
     */
    Rectangle {
        id: errorOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        z: 100
        visible: errorMsg !== ""

        /// @brief Dialog box error
        Rectangle {
            width: 400
            height: 200
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1
            anchors.centerIn: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                /// @brief Judul error
                Text {
                    Layout.fillWidth: true
                    text: "Connection Failed"
                    color: Theme.accentRed
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeL
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                /// @brief Pesan error
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: errorMsg
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                /// @brief Tombol Close
                NavBtn {
                    Layout.alignment: Qt.AlignHCenter
                    labelText: "Close"
                    onClicked: errorMsg = ""
                }
            }
        }
    }
}
