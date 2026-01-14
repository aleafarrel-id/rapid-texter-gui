/**
 * @file MultiplayerMenuPage.qml
 * @brief Halaman menu mode multiplayer - Pilihan untuk membuat atau bergabung game.
 * @author Alea Farrel & Team
 * @date 2026
 *
 * @details MultiplayerMenuPage adalah halaman menu utama untuk mode multiplayer
 * yang menyediakan dua opsi utama:
 * - Create Game: Membuat room baru sebagai host
 * - Join Game: Bergabung ke room yang sudah ada
 *
 * @par Fitur Utama:
 * - Navigasi keyboard dengan shortcut (1, 2, ESC)
 * - Indikator loading saat membuat game
 * - Desain responsif dengan lebar maksimum 500px
 *
 * @par Integrasi:
 * Halaman ini digunakan oleh MainWindow.qml sebagai bagian dari
 * flow navigasi multiplayer.
 *
 * @see MainWindow.qml
 * @see MultiplayerLobbyPage.qml
 */
import QtQuick
import QtQuick.Layouts
import "../components"

/**
 * @brief Komponen utama halaman menu multiplayer.
 *
 * @details FocusScope digunakan sebagai root untuk menangani
 * keyboard focus dan event handling secara terpusat.
 */
FocusScope {
    id: multiplayerMenuPage
    focus: true  ///< Mengaktifkan focus untuk keyboard handling

    //=========================================================================
    // SIGNALS - Sinyal untuk komunikasi dengan parent
    //=========================================================================

    /**
     * @brief Dipancarkan saat user memilih opsi "Create Game".
     * @note Ditrigger oleh klik tombol atau shortcut keyboard (1).
     */
    signal createGameClicked

    /**
     * @brief Dipancarkan saat user memilih opsi "Join Game".
     * @note Ditrigger oleh klik tombol atau shortcut keyboard (2).
     */
    signal joinGameClicked

    /**
     * @brief Dipancarkan saat user memilih untuk kembali ke menu sebelumnya.
     * @note Ditrigger oleh klik tombol Back atau shortcut keyboard (ESC).
     */
    signal backClicked

    //=========================================================================
    // PROPERTIES - Properti state halaman
    //=========================================================================

    /**
     * @property isCreating
     * @brief Flag yang menandakan proses pembuatan game sedang berlangsung.
     *
     * @details Ketika true:
     * - Label tombol berubah menjadi "Creating..."
     * - Animasi loading ditampilkan pada tombol
     * - Mencegah multiple click
     */
    property bool isCreating: false

    //=========================================================================
    // BACKGROUND - Latar belakang halaman
    //=========================================================================

    /**
     * @brief Rectangle latar belakang yang mengisi seluruh halaman.
     *
     * @details Menggunakan warna primer dari Theme dengan z-index rendah
     * untuk memastikan elemen lain ditampilkan di atasnya.
     */
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100  ///< Z-index rendah agar berada di belakang semua elemen
    }

    //=========================================================================
    // CONTENT CONTAINER - Kontainer konten utama
    //=========================================================================

    /**
     * @brief Item container yang memusatkan konten menu di tengah layar.
     *
     * @details Lebar responsif dengan maksimum 500px dan padding
     * dari tepi layar menggunakan Theme.paddingHuge.
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 500)  ///< Lebar responsif max 500px
        height: menuCol.implicitHeight

        /**
         * @brief ColumnLayout utama yang mengatur tata letak vertikal menu.
         *
         * @details Berisi:
         * 1. Header (judul dan subtitle)
         * 2. Menu items (Create Game, Join Game)
         * 3. Spacer
         * 4. Tombol Back
         */
        ColumnLayout {
            id: menuCol
            anchors.fill: parent
            spacing: 0  ///< Spacing 0, margin diatur per-item untuk kontrol lebih baik

            //=================================================================
            // HEADER SECTION - Bagian judul halaman
            //=================================================================

            /**
             * @brief Judul utama halaman "MULTIPLAYER".
             *
             * @details Menggunakan font display size dengan style bold
             * dan alignment center.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                text: "MULTIPLAYER"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            /**
             * @brief Subtitle yang menjelaskan fungsi halaman.
             *
             * @details Memberikan konteks kepada user bahwa mode ini
             * untuk bermain dengan teman di jaringan lokal.
             */
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 40
                text: "Race against friends on your local network"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
                horizontalAlignment: Text.AlignHCenter
            }

            //=================================================================
            // MENU ITEMS SECTION - Tombol-tombol menu
            //=================================================================

            /**
             * @brief Tombol menu untuk membuat game baru.
             *
             * @details Fitur:
             * - Shortcut keyboard: [1]
             * - Ikon: play.svg
             * - Accent warna hijau (green)
             * - Menampilkan state loading saat isCreating = true
             *
             * @note Saat diklik, isCreating diset true dan signal
             * createGameClicked dipancarkan.
             */
            MenuItemC {
                Layout.fillWidth: true
                keyText: "[1]"  ///< Label shortcut keyboard
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                labelText: multiplayerMenuPage.isCreating ? "Creating..." : "Create Game"
                accentType: "green"  ///< Warna aksen hijau untuk aksi positif
                busy: multiplayerMenuPage.isCreating  ///< Tampilkan loading indicator
                onClicked: {
                    multiplayerMenuPage.isCreating = true;
                    multiplayerMenuPage.createGameClicked();
                }
            }

            /**
             * @brief Tombol menu untuk bergabung ke game yang ada.
             *
             * @details Fitur:
             * - Shortcut keyboard: [2]
             * - Ikon: globe.svg (menandakan jaringan)
             * - Accent warna biru (blue)
             *
             * @note Memancarkan signal joinGameClicked saat diklik.
             */
            MenuItemC {
                Layout.fillWidth: true
                keyText: "[2]"  ///< Label shortcut keyboard
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                labelText: "Join Game"
                accentType: "blue"  ///< Warna aksen biru untuk aksi sekunder
                onClicked: multiplayerMenuPage.joinGameClicked()
            }

            //=================================================================
            // SPACER - Pemisah visual
            //=================================================================

            /**
             * @brief Item kosong sebagai spacer antara menu items dan tombol Back.
             *
             * @details Memberikan jarak visual 30px untuk pemisahan
             * yang jelas antara aksi utama dan navigasi.
             */
            Item {
                Layout.preferredHeight: 30
            }

            //=================================================================
            // NAVIGATION - Tombol navigasi
            //=================================================================

            /**
             * @brief Tombol navigasi untuk kembali ke menu sebelumnya.
             *
             * @details Fitur:
             * - Ikon: arrow-left.svg
             * - Label menampilkan shortcut (ESC)
             * - Di-align center secara horizontal
             *
             * @note Memancarkan signal backClicked saat diklik.
             */
            NavBtn {
                Layout.alignment: Qt.AlignHCenter
                iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                labelText: "Back (ESC)"
                onClicked: multiplayerMenuPage.backClicked()
            }
        }
    }

    //=========================================================================
    // KEYBOARD SHORTCUTS - Handler untuk shortcut keyboard
    //=========================================================================

    /**
     * @brief Handler untuk keyboard shortcuts.
     *
     * @details Mapping keyboard:
     * - Key_1: Trigger createGameClicked (Create Game)
     * - Key_2: Trigger joinGameClicked (Join Game)
     * - Key_Escape: Trigger backClicked (Kembali)
     *
     * @param event Event keyboard yang diterima
     *
     * @note event.accepted diset true untuk mencegah propagasi
     * ke parent elements.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_1) {
            multiplayerMenuPage.createGameClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_2) {
            multiplayerMenuPage.joinGameClicked();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            multiplayerMenuPage.backClicked();
            event.accepted = true;
        }
    }
}
