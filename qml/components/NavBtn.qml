/**
 * @file NavBtn.qml
 * @brief Komponen tombol navigasi yang dapat digunakan kembali dengan dukungan ikon dan label.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details NavBtn adalah tombol bergaya yang digunakan untuk aksi navigasi di seluruh
 * aplikasi. Mendukung beberapa varian visual untuk berbagai tipe aksi
 * dan mencakup ikon SVG opsional dengan color overlays.
 *
 * @section usage Contoh Penggunaan
 * @code
 * NavBtn {
 *     iconSource: "qrc:/icons/arrow-left.svg"
 *     labelText: "Kembali (ESC)"
 *     variant: "default"
 *     onClicked: stackView.pop()
 * }
 * @endcode
 *
 * @section variants Varian Visual
 * - "default": Aksen biru (navigasi netral)
 * - "primary": Aksen hijau dengan background terisi (aksi utama)
 * - "danger": Aksen merah (aksi destruktif)
 * - "reset"/"yellow": Aksen kuning (aksi reset/peringatan)
 */
import QtQuick
import Qt5Compat.GraphicalEffects

/**
 * @brief Tombol navigasi bergaya dengan ikon dan teks.
 * @inherits Rectangle
 *
 * @details Fitur:
 * - Dukungan ikon SVG dengan color overlay otomatis
 * - Lima varian visual untuk berbagai tipe aksi
 * - State hover dengan transisi warna yang halus
 * - Tinggi konsisten 36px di semua instance
 */
Rectangle {
    id: navBtn

    /* ========================================================================
     * PROPERTI PUBLIK
     * ======================================================================== */

    /**
     * @property iconText
     * @brief Fallback emoji untuk ikon (deprecated).
     * @deprecated Gunakan iconSource sebagai gantinya untuk ikon SVG.
     */
    property string iconText: ""

    /**
     * @property iconSource
     * @brief Path ke file ikon SVG (format qrc:/).
     * @details Ikon dirender pada 14x14 piksel dengan color overlay sesuai varian.
     */
    property string iconSource: ""

    /**
     * @property labelText
     * @brief Teks tombol yang ditampilkan di samping ikon.
     * @default "Button"
     */
    property string labelText: "Button"

    /**
     * @property variant
     * @brief Varian gaya visual yang mempengaruhi warna.
     * @details Nilai valid:
     *          - "default": Warna aksen biru
     *          - "primary": Aksen hijau dengan background sukses
     *          - "danger": Aksen merah untuk aksi destruktif
     *          - "reset": Aksen kuning (alias untuk "yellow")
     *          - "yellow": Aksen kuning untuk peringatan
     * @default "default"
     */
    property string variant: "default"

    /* ========================================================================
     * SIGNAL
     * ======================================================================== */

    /**
     * @property isLoading
     * @brief Apakah tombol dalam state loading.
     * @details Ketika true, ikon berputar dan tombol sebaiknya dinonaktifkan.
     */
    property bool isLoading: false

    /* ========================================================================
     * SIGNAL
     * ======================================================================== */

    /**
     * @signal clicked
     * @brief Dipancarkan saat tombol diklik.
     */
    signal clicked

    /* ========================================================================
     * PROPERTI COMPUTED
     * ======================================================================== */

    /**
     * @property isHovered
     * @brief True saat mouse berada di atas tombol.
     * @readonly
     * @details Menggunakan HoverHandler untuk deteksi hover yang immediate,
     *          sehingga efek hover langsung muncul saat halaman baru dimuat
     *          dan cursor sudah berada di atas tombol.
     */
    readonly property bool isHovered: hoverHandler.hovered

    /**
     * @property variantColor
     * @brief Warna aksen computed berdasarkan properti variant.
     * @readonly
     * @details Memetakan string variant ke warna aksen Theme:
     *          primary → accentGreen, danger → accentRed,
     *          reset/yellow → accentYellow, default → accentBlue
     */
    readonly property color variantColor: {
        switch (variant) {
        case "primary":
            return Theme.accentGreen;
        case "danger":
            return Theme.accentRed;
        case "reset":
            return Theme.accentYellow;
        case "yellow":
            return Theme.accentYellow;
        default:
            return Theme.accentBlue;
        }
    }

    /* ========================================================================
     * UKURAN
     * ======================================================================== */

    /**
     * @brief Lebar implisit berdasarkan konten plus padding horizontal.
     * @details Lebar = lebar konten row + (paddingXL × 2) = konten + 36px
     */
    implicitWidth: navRow.implicitWidth + Theme.paddingXL * 2

    /**
     * @brief Tinggi tetap 36 piksel untuk tampilan tombol yang konsisten.
     */
    implicitHeight: 36

    /* ========================================================================
     * STYLING
     * ======================================================================== */

    /**
     * @brief Warna background berubah saat hover berdasarkan varian.
     * @details Varian default menggunakan bgSecondary saat hover.
     *          Varian lain menggunakan tint opacity 10% dari warna aksen mereka.
     *          Varian primary menampilkan successBg bahkan saat tidak di-hover.
     */
    color: isHovered ? (variant === "default" ? Theme.bgSecondary : Qt.rgba(variantColor.r, variantColor.g, variantColor.b, 0.1)) : (variant === "primary" ? Theme.successBg : "transparent")

    /** @brief Border 1 piksel di sekeliling tombol */
    border.width: 1

    /**
     * @brief Warna border berdasarkan state hover dan varian.
     * @details Saat di-hover atau varian non-default menampilkan warna aksen.
     *          Varian default menampilkan borderSecondary saat tidak di-hover.
     */
    border.color: isHovered ? variantColor : (variant !== "default" ? variantColor : Theme.borderSecondary)

    /* ========================================================================
     * LAYOUT KONTEN
     * ======================================================================== */

    /**
     * @brief Layout horizontal untuk ikon dan label.
     */
    Row {
        id: navRow
        anchors.centerIn: parent
        spacing: Theme.spacingSM  /* Jarak 8px antara ikon dan teks */

        /**
         * @brief Kontainer untuk ikon SVG dengan color overlay.
         * @details Lebar 0 saat tidak ada iconSource untuk menghilangkan spacing.
         */
        Item {
            id: iconItem
            width: navBtn.iconSource !== "" ? 14 : 0  /* Ikon 14px atau 0 jika tidak ada */
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            /**
             * @brief Animasi putar untuk state loading
             */
            RotationAnimation {
                target: iconItem
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
                running: navBtn.isLoading
            }

            /**
             * @brief Sumber gambar SVG (tersembunyi, digunakan sebagai sumber overlay).
             */
            Image {
                id: navIcon
                source: navBtn.iconSource
                anchors.fill: parent
                sourceSize: Qt.size(14, 14)
                visible: false  /* Tersembunyi - ColorOverlay merender ikon yang terlihat */
            }

            /**
             * @brief Color overlay menerapkan warna varian ke ikon.
             * @details Opacity meningkat dari 0.7 ke 1.0 saat hover untuk efek halus.
             */
            ColorOverlay {
                anchors.fill: navIcon
                source: navIcon
                color: navBtn.variantColor
                opacity: navBtn.isHovered ? 1.0 : 0.7
                visible: navBtn.iconSource !== ""
            }
        }

        /**
         * @brief Tampilan ikon emoji fallback (deprecated).
         */
        Text {
            text: navBtn.iconText
            font.pixelSize: Theme.fontSizeSM  /* 12px */
            visible: navBtn.iconText !== "" && navBtn.iconSource === ""
        }

        /**
         * @brief Teks label tombol.
         * @details Warna berubah ke aksen saat hover untuk varian non-default,
         *          atau selalu menampilkan warna aksen untuk varian non-default.
         */
        Text {
            text: navBtn.labelText
            color: navBtn.isHovered ? navBtn.variantColor : (navBtn.variant !== "default" ? navBtn.variantColor : Theme.textSecondary)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeM  /* 13px */
        }
    }

    /* ========================================================================
     * INTERAKSI MOUSE
     * ======================================================================== */

    /**
     * @brief HoverHandler untuk deteksi hover yang immediate.
     * @details Menggunakan HoverHandler sebagai pengganti MouseArea.containsMouse
     *          karena HoverHandler secara continuous memeriksa posisi cursor,
     *          memungkinkan efek hover langsung muncul saat halaman baru dimuat.
     */
    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor  /* Tampilkan kursor pointer saat hover */
    }

    /**
     * @brief Area mouse untuk deteksi klik.
     */
    MouseArea {
        id: navMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: navBtn.clicked()
    }
}
