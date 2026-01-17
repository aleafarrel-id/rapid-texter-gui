/**
 * @file RaceResultsPage.qml
 * @brief Halaman hasil race yang menampilkan ranking final.
 * @author Alea Farrel & Team
 * @date 2026
 *
 * @details RaceResultsPage menampilkan hasil akhir dari race multiplayer
 * dengan informasi lengkap tentang performa semua pemain.
 *
 * @par Fitur Utama:
 * - Statistik pemain lokal (WPM, akurasi, errors)
 * - Daftar ranking dengan medal untuk top 3
 * - Tombol Play Again untuk host
 * - Popup invitation untuk guest saat host ingin bermain lagi
 * - Handling untuk late join (game in progress)
 *
 * @par Flow Play Again:
 * 1. Host mengklik "Play Again" → mengirim invite ke semua guest
 * 2. Guest menerima popup invitation
 * 3. Jika Accept: kembali ke lobby, jika Decline: exit
 *
 * @par Keyboard Shortcuts:
 * - ESC: Keluar dari hasil/decline invite
 * - P: Play Again (host) atau Accept invite (guest)
 *
 * @see RaceGameplayPage.qml
 * @see MultiplayerLobbyPage.qml
 * @see NetworkManager
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen utama halaman hasil race.
 *
 * @details FocusScope digunakan untuk menangani keyboard shortcuts.
 */
FocusScope {
    id: resultsPage
    focus: true

    //=========================================================================
    // RESULTS DATA PROPERTIES - Properti data hasil race
    //=========================================================================

    /**
     * @property rankings
     * @brief Array ranking pemain dari race.
     *
     * @details Setiap objek berisi:
     * - id: ID pemain
     * - name: Nama pemain
     * - wpm: Words per minute
     * - position: Posisi finish (1, 2, 3, ...)
     * - isLocal: true jika pemain lokal
     * - accuracy: Akurasi dalam persen
     * - errors: Jumlah kesalahan
     * - duration: Durasi dalam detik
     * - hasLeft: true jika pemain disconnect
     */
    property var rankings: []

    /**
     * @property localWpm
     * @brief WPM pemain lokal.
     */
    property int localWpm: 0

    /**
     * @property localAccuracy
     * @brief Akurasi pemain lokal dalam persen.
     */
    property real localAccuracy: 0

    /**
     * @property localErrors
     * @brief Jumlah kesalahan pemain lokal.
     */
    property int localErrors: 0

    /**
     * @property localPosition
     * @brief Posisi finish pemain lokal.
     */
    property int localPosition: 0

    //=========================================================================
    // SIGNALS - Sinyal untuk komunikasi dengan parent
    //=========================================================================

    /**
     * @brief Dipancarkan saat user memilih untuk bermain lagi.
     * @note Hanya untuk host.
     */
    signal playAgainClicked

    /**
     * @brief Dipancarkan saat user memilih untuk keluar.
     */
    signal exitClicked

    /**
     * @brief Dipancarkan saat user kembali ke lobby (setelah accept play again).
     */
    signal returnToLobbyClicked

    //=========================================================================
    // POPUP STATE PROPERTIES - State untuk popup dialog
    //=========================================================================

    /**
     * @property showInvitePopup
     * @brief Flag untuk menampilkan popup invitation play again.
     * @details Hanya untuk guest saat host mengirim invite.
     */
    property bool showInvitePopup: false

    /**
     * @property showGameInProgressPopup
     * @brief Flag untuk menampilkan popup game in progress.
     * @details Ditampilkan saat guest mencoba join padahal race sudah dimulai.
     */
    property bool showGameInProgressPopup: false

    //=========================================================================
    // HOST STATE - State dinamis untuk status host
    //=========================================================================

    /**
     * @property isHost
     * @brief Flag apakah pemain ini adalah host.
     * @details Diupdate saat authority berubah (misal host disconnect).
     */
    property bool isHost: NetworkManager.isAuthority

    /**
     * @brief Refresh isHost saat komponen selesai dimuat.
     */
    Component.onCompleted: {
        resultsPage.isHost = NetworkManager.isAuthority;
    }

    /**
     * @brief Connections untuk menangani perubahan authority.
     */
    Connections {
        target: NetworkManager

        /**
         * @brief Handler saat authority berubah.
         */
        function onAuthorityChanged() {
            resultsPage.isHost = NetworkManager.isAuthority;
        }

        /**
         * @brief Handler saat daftar pemain berubah.
         * @details Juga refresh isHost karena mungkin ada yang keluar.
         */
        function onPlayersChanged() {
            resultsPage.isHost = NetworkManager.isAuthority;
        }
    }

    //=========================================================================
    // BACKGROUND - Latar belakang halaman
    //=========================================================================

    /**
     * @brief Rectangle latar belakang.
     */
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    //=========================================================================
    // MAIN CONTENT - Konten utama hasil race
    //=========================================================================

    /**
     * @brief Container yang memusatkan konten dengan lebar maksimum 500px.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 500)
        height: contentCol.implicitHeight

        /**
         * @brief ColumnLayout utama untuk konten hasil race.
         */
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 0

            //=================================================================
            // TROPHY ICON - Ikon trophy untuk header
            //=================================================================

            /**
             * @brief Container untuk ikon trophy.
             *
             * @details Warna hijau jika juara 1, abu-abu jika tidak.
             */
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16
                width: 48
                height: 48

                Image {
                    id: trophyIcon
                    anchors.fill: parent
                    source: "qrc:/qt/qml/rapid_texter/assets/icons/trophy.svg"
                    sourceSize: Qt.size(48, 48)
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: trophyIcon
                    source: trophyIcon
                    color: localPosition === 1 ? Theme.accentGreen : Theme.textSecondary
                }
            }

            //=================================================================
            // HEADER - Judul dan posisi finish
            //=================================================================

            /**
             * @brief Judul "RACE COMPLETE".
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                text: "RACE COMPLETE"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Teks posisi finish pemain lokal.
             *
             * @details Warna hijau jika juara 1.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 24
                text: localPosition > 0 ? "You finished #" + localPosition : "Race finished"
                color: localPosition === 1 ? Theme.accentGreen : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                horizontalAlignment: Text.AlignHCenter
            }

            //=================================================================
            // LOCAL STATS BOX - Box statistik pemain lokal
            //=================================================================

            /**
             * @brief Rectangle untuk menampilkan statistik pemain lokal.
             *
             * @details Menampilkan WPM, Accuracy, dan Errors dalam format
             * yang prominent dengan border biru.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                height: 80
                color: Theme.bgSecondary
                border.color: Theme.accentBlue
                border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 40

                    /**
                     * @brief Kolom WPM.
                     */
                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localWpm.toString()
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "WPM"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    /**
                     * @brief Kolom Accuracy.
                     */
                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localAccuracy.toFixed(1) + "%"
                            color: Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Accuracy"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    /**
                     * @brief Kolom Errors.
                     *
                     * @details Warna merah jika ada error, hijau jika 0.
                     */
                    Column {
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: localErrors.toString()
                            color: localErrors > 0 ? Theme.accentRed : Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Errors"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }
                }
            }

            //=================================================================
            // RANKINGS LIST - Daftar ranking pemain
            //=================================================================

            /**
             * @brief Container untuk daftar ranking.
             *
             * @details Tinggi dinamis berdasarkan jumlah pemain dengan
             * maksimum 170px.
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(rankings.length * 44 + 40, 170)
                Layout.bottomMargin: 16
                color: "transparent"
                border.color: Theme.borderPrimary
                border.width: 1

                /**
                 * @brief Header "FINAL RANKINGS".
                 */
                Rectangle {
                    id: rankHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    color: Theme.bgSecondary

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Theme.radiusM
                        color: Theme.bgSecondary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "FINAL RANKINGS"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        font.bold: true
                    }
                }

                /**
                 * @brief ListView untuk menampilkan ranking pemain.
                 */
                ListView {
                    anchors.top: rankHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    clip: true

                    model: rankings

                    ScrollBar.vertical: ScrollBar {
                        id: rankingsScrollBar
                        policy: ScrollBar.AsNeeded
                        width: 8
                        hoverEnabled: true
                        background: Rectangle {
                            color: "transparent"
                        }
                        contentItem: Rectangle {
                            implicitWidth: 6
                            radius: 3
                            color: rankingsScrollBar.pressed ? "#6A6A6A" : "#4A4A4A"
                            opacity: rankingsScrollBar.hovered || rankingsScrollBar.pressed ? 1.0 : 0.6

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    /**
                     * @brief Delegate untuk setiap item ranking.
                     *
                     * @details Menampilkan:
                     * - Medal posisi (gold/silver/bronze untuk top 3)
                     * - Nama pemain (dengan tag "(You)" dan "(Left)")
                     * - WPM, Accuracy, Errors, Duration
                     */
                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: modelData.isLocal ? Qt.rgba(0.34, 0.65, 1, 0.1) : (modelData.hasLeft ? Qt.rgba(1, 0.8, 0.3, 0.1) : "transparent")

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            /**
                             * @brief Medal posisi dengan warna berdasarkan ranking.
                             *
                             * @details Warna:
                             * - 1st: Gold (#FFD700)
                             * - 2nd: Silver (#C0C0C0)
                             * - 3rd: Bronze (#CD7F32)
                             * - Lainnya: bgTertiary
                             */
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: {
                                    switch (modelData.position) {
                                    case 1:
                                        return "#FFD700";  // Gold
                                    case 2:
                                        return "#C0C0C0";  // Silver
                                    case 3:
                                        return "#CD7F32";  // Bronze
                                    default:
                                        return Theme.bgTertiary;
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.position.toString()
                                    color: modelData.position <= 3 ? "#000" : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            /**
                             * @brief Nama pemain dengan status.
                             */
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name + (modelData.isLocal ? " (You)" : "") + (modelData.hasLeft ? " (Left)" : "")
                                color: modelData.hasLeft ? Theme.textMuted : (modelData.isLocal ? Theme.accentBlue : Theme.textPrimary)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                font.bold: modelData.isLocal
                                font.italic: modelData.hasLeft
                                elide: Text.ElideRight
                            }

                            /**
                             * @brief WPM pemain.
                             */
                            Text {
                                Layout.preferredWidth: 65
                                text: modelData.wpm + " WPM"
                                color: Theme.accentBlue
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                                font.bold: true
                            }

                            /**
                             * @brief Akurasi pemain.
                             */
                            Text {
                                Layout.preferredWidth: 50
                                text: (modelData.accuracy !== undefined ? modelData.accuracy.toFixed(1) : "100.0") + "%"
                                color: Theme.accentGreen
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                            }

                            /**
                             * @brief Jumlah error pemain.
                             */
                            Text {
                                Layout.preferredWidth: 40
                                text: (modelData.errors !== undefined ? modelData.errors : 0) + " err"
                                color: (modelData.errors !== undefined && modelData.errors > 0) ? Theme.accentRed : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                            }

                            /**
                             * @brief Durasi atau status "Left".
                             */
                            Text {
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                                text: {
                                    if (modelData.hasLeft)
                                        return "Left";
                                    var duration = modelData.duration !== undefined ? modelData.duration : 0;
                                    return duration + "s";
                                }
                                color: modelData.hasLeft ? Theme.textMuted : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSM
                                font.italic: modelData.hasLeft
                            }
                        }

                        /**
                         * @brief Garis pembatas antar item.
                         */
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.borderPrimary
                            visible: index < rankings.length - 1
                        }
                    }
                }
            }

            //=================================================================
            // ACTION BUTTONS - Tombol aksi
            //=================================================================

            /**
             * @brief Row untuk tombol aksi.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 32
                spacing: Theme.spacingM

                /**
                 * @brief Tombol Play Again (hanya untuk host).
                 *
                 * @details Mengirim invite ke semua guest dan kembali ke lobby.
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    labelText: "Play Again"
                    variant: "primary"
                    visible: resultsPage.isHost
                    onClicked: {
                        NetworkManager.sendPlayAgainInvite();
                        // Navigation handled by onReturnedToLobby signal
                    }
                }

                /**
                 * @brief Tombol Exit (selalu terlihat).
                 */
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                    labelText: "Exit"
                    onClicked: {
                        NetworkManager.leaveRoom();
                        resultsPage.exitClicked();
                    }
                }
            }
        }
    }

    //=========================================================================
    // PLAY AGAIN INVITATION POPUP - Popup invitation untuk guest
    //=========================================================================

    /**
     * @brief Overlay popup untuk invitation play again.
     *
     * @details Hanya ditampilkan untuk guest saat host mengirim invite.
     * Berisi tombol Accept dan Decline.
     */
    Rectangle {
        id: invitePopup
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: showInvitePopup && !resultsPage.isHost
        z: 100

        /**
         * @brief MouseArea untuk memblokir klik pada background.
         */
        MouseArea {
            anchors.fill: parent
            onClicked: {}  // Absorb clicks
        }

        /**
         * @brief Dialog box untuk invitation.
         */
        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: 260
            color: Theme.bgSecondary
            border.color: Theme.borderSecondary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 24

                /**
                 * @brief Ikon dan judul popup.
                 */
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    /**
                     * @brief Container untuk ikon refresh.
                     */
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48
                        height: 48

                        Image {
                            id: refreshIcon
                            anchors.fill: parent
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: refreshIcon
                            source: refreshIcon
                            color: Theme.accentBlue
                        }
                    }

                    /**
                     * @brief Judul popup "Play Again?".
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Play Again?"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                /**
                 * @brief Pesan invitation.
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Host wants to start another race!"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }

                /**
                 * @brief Tombol Accept dan Decline.
                 */
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    /**
                     * @brief Tombol Accept invitation.
                     */
                    NavBtn {
                        labelText: "Accept"
                        variant: "primary"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                        onClicked: {
                            resultsPage.showInvitePopup = false;
                            NetworkManager.acceptPlayAgain();
                            // Navigation handled by onReturnedToLobby
                        }
                    }

                    /**
                     * @brief Tombol Decline invitation.
                     */
                    NavBtn {
                        labelText: "Decline"
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                        onClicked: {
                            resultsPage.showInvitePopup = false;
                            NetworkManager.declinePlayAgain();
                            resultsPage.exitClicked();
                        }
                    }
                }
            }
        }
    }

    //=========================================================================
    // GAME IN PROGRESS POPUP - Popup untuk late join
    //=========================================================================

    /**
     * @brief Overlay popup untuk menginformasikan game sudah dimulai.
     *
     * @details Ditampilkan saat guest mencoba join padahal race sudah berjalan.
     */
    Rectangle {
        id: gameInProgressPopupOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: showGameInProgressPopup
        z: 110

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        /**
         * @brief Dialog box untuk game in progress.
         */
        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: 240
            color: Theme.bgSecondary
            border.color: Theme.borderPrimary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 24
                width: parent.width - 40

                /**
                 * @brief Ikon dan judul popup.
                 */
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    /**
                     * @brief Container untuk ikon clock/warning.
                     */
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 40
                        height: 40

                        Image {
                            id: clockIcon
                            anchors.fill: parent
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            sourceSize: Qt.size(40, 40)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: clockIcon
                            source: clockIcon
                            color: Theme.accentRed
                        }

                        /**
                         * @brief Fallback lingkaran jika ikon tidak ditemukan.
                         */
                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "transparent"
                            border.color: Theme.accentRed
                            border.width: 2
                            visible: clockIcon.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: "!"
                                color: Theme.accentRed
                                font.bold: true
                                font.pixelSize: 24
                            }
                        }
                    }

                    /**
                     * @brief Judul "Race Already Started".
                     */
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Race Already Started"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                /**
                 * @brief Pesan penjelasan.
                 */
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: "The host has already started the race. You cannot join this session."
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                /**
                 * @brief Tombol OK untuk menutup popup.
                 */
                NavBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    labelText: "OK"
                    variant: "primary"
                    onClicked: {
                        resultsPage.showGameInProgressPopup = false;
                        resultsPage.showInvitePopup = false;
                        NetworkManager.declinePlayAgain();  // Leave room
                        resultsPage.exitClicked();
                    }
                }
            }
        }
    }

    //=========================================================================
    // NETWORK CONNECTIONS - Handler untuk signal dari NetworkManager
    //=========================================================================

    /**
     * @brief Connections untuk play again flow.
     */
    Connections {
        target: NetworkManager

        /**
         * @brief Handler saat menerima invitation play again dari host.
         */
        function onPlayAgainInviteReceived() {
            console.log("[RaceResultsPage] Received play again invite");
            resultsPage.showInvitePopup = true;
        }

        /**
         * @brief Handler saat game sudah in progress (late join).
         */
        function onGameInProgress() {
            console.log("[RaceResultsPage] Game in progress - late join prevented");
            resultsPage.showInvitePopup = false;  // Hide invite popup if open
            resultsPage.showGameInProgressPopup = true;
        }

        /**
         * @brief Handler saat berhasil kembali ke lobby.
         */
        function onReturnedToLobby() {
            console.log("[RaceResultsPage] Successfully returned to lobby - navigating");
            resultsPage.returnToLobbyClicked();
        }
    }

    //=========================================================================
    // KEYBOARD SHORTCUTS - Handler untuk shortcut keyboard
    //=========================================================================

    /**
     * @brief Handler untuk keyboard shortcuts.
     *
     * @details Mapping:
     * - ESC: Keluar (atau decline jika popup terbuka)
     * - P: Play Again (host) atau Accept (guest dengan popup)
     */
    Keys.onPressed: function (event) {
        // ESC key: exit atau decline invite
        if (event.key === Qt.Key_Escape) {
            if (resultsPage.showInvitePopup) {
                // Decline invite
                resultsPage.showInvitePopup = false;
                NetworkManager.declinePlayAgain();
            }
            NetworkManager.leaveRoom();
            resultsPage.exitClicked();
            event.accepted = true;
            return;
        }

        // P untuk Play Again (host) atau Accept (guest dengan popup)
        if (event.key === Qt.Key_P) {
            if (showInvitePopup && !resultsPage.isHost) {
                // Guest accepts invite
                showInvitePopup = false;
                NetworkManager.acceptPlayAgain();
                // Navigation handled by onReturnedToLobby
            } else if (resultsPage.isHost) {
                // Host starts play again
                NetworkManager.sendPlayAgainInvite();
                // Navigation handled by onReturnedToLobby
            }
            event.accepted = true;
        }
    }
}
