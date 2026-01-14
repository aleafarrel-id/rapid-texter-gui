/**
 * @file Theme.qml
 * @brief Singleton design system yang menyediakan theming konsisten di seluruh aplikasi.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Singleton ini mendefinisikan semua design token visual yang digunakan di seluruh
 * aplikasi RapidTexter, mengimplementasikan tema gelap terinspirasi GitHub. Dengan
 * memusatkan nilai-nilai ini, aplikasi menjaga konsistensi visual dan memungkinkan
 * modifikasi tema dengan mudah.
 *
 * @note Ini adalah QML Singleton - hanya ada satu instance dan dapat diakses
 *       di seluruh aplikasi tanpa perlu instantiasi.
 *
 * @section colors Palet Warna
 * Skema warna menggunakan background gelap dengan warna aksen kontras tinggi:
 * - Background: Abu-abu gelap (#0d1117 → #21262d)
 * - Teks: Abu-abu terang (#c9d1d9 untuk primer, #484f58 untuk muted)
 * - Aksen: Biru (#58a6ff), Hijau (#3fb950), Kuning (#d29922), Merah (#f85149)
 *
 * @section typography Skala Tipografi
 * Menggunakan font JetBrains Mono dengan skala ukuran modular dari 11px hingga 64px.
 *
 * @section spacing Sistem Spacing
 * Nilai spacing konsisten dari 6px (small) hingga 50px (logo spacing).
 */
pragma Singleton
import QtQuick

/**
 * @brief Objek tema root yang berisi semua design token.
 *
 * @details Akses properti via Theme.propertyName (contoh: Theme.bgPrimary, Theme.fontSizeL)
 */
QtObject {
    id: theme

    /* ========================================================================
     * TIPOGRAFI
     * ======================================================================== */

    /**
     * @property fontFamily
     * @brief Keluarga font utama untuk semua elemen teks.
     * @details Diatur ke "JetBrains Mono" setelah font dimuat di Main.qml.
     *          Font monospace ini ideal untuk aplikasi mengetik karena
     *          menyediakan lebar karakter yang konsisten untuk posisi kursor yang akurat.
     */
    property string fontFamily: "JetBrains Mono"

    /* ========================================================================
     * WARNA BACKGROUND
     * ======================================================================== */

    /**
     * @property bgPrimary
     * @brief Warna background paling gelap untuk area konten utama.
     * @details Hex: #0d1117 (RGB: 13, 17, 23)
     */
    readonly property color bgPrimary: "#0d1117"

    /**
     * @property bgSecondary
     * @brief Background sedikit lebih terang untuk elemen terangkat (status bar, kartu).
     * @details Hex: #161b22 (RGB: 22, 27, 34)
     */
    readonly property color bgSecondary: "#161b22"

    /**
     * @property bgTertiary
     * @brief Background untuk state hover interaktif dan badge tombol.
     * @details Hex: #21262d (RGB: 33, 38, 45)
     */
    readonly property color bgTertiary: "#21262d"

    /**
     * @property bgHover
     * @brief Warna background untuk state hover.
     * @details Hex: #21262d - Sama dengan bgTertiary.
     */
    readonly property color bgHover: bgTertiary

    /* ========================================================================
     * WARNA BORDER
     * ======================================================================== */

    /**
     * @property borderPrimary
     * @brief Warna border halus untuk kontainer dan pemisah.
     * @details Hex: #21262d - Sama dengan bgTertiary untuk konsistensi.
     */
    readonly property color borderPrimary: "#21262d"

    /**
     * @property borderSecondary
     * @brief Border lebih terang untuk state hover dan kebutuhan kontras tinggi.
     * @details Hex: #30363d (RGB: 48, 54, 61)
     */
    readonly property color borderSecondary: "#30363d"

    /* ========================================================================
     * WARNA TEKS
     * ======================================================================== */

    /**
     * @property textPrimary
     * @brief Warna teks utama untuk konten penting dan heading.
     * @details Hex: #c9d1d9 - Kontras tinggi terhadap background gelap.
     */
    readonly property color textPrimary: "#c9d1d9"

    /**
     * @property textSecondary
     * @brief Warna teks redup untuk label dan konten pendukung.
     * @details Hex: #8b949e - Kontras sedang untuk informasi sekunder.
     */
    readonly property color textSecondary: "#8b949e"

    /**
     * @property textMuted
     * @brief Teks penekanan rendah untuk petunjuk dan state disabled.
     * @details Hex: #484f58 - Kontras rendah, digunakan seperlunya.
     */
    readonly property color textMuted: "#484f58"

    /* ========================================================================
     * WARNA AKSEN
     * ======================================================================== */

    /**
     * @property accentBlue
     * @brief Warna aksen utama untuk link, state fokus, dan aksi netral.
     * @details Hex: #58a6ff - Digunakan untuk status bahasa, petunjuk navigasi.
     */
    readonly property color accentBlue: "#58a6ff"

    /**
     * @property accentGreen
     * @brief Warna aksen sukses untuk state positif dan aksi utama.
     * @details Hex: #3fb950 - Digunakan untuk level lulus, input benar, tombol start.
     */
    readonly property color accentGreen: "#3fb950"

    /**
     * @property accentYellow
     * @brief Warna aksen peringatan untuk state hati-hati dan aksi sekunder.
     * @details Hex: #d29922 - Digunakan untuk tombol reset, opsi kustom.
     */
    readonly property color accentYellow: "#d29922"

    /**
     * @property accentRed
     * @brief Warna aksen bahaya untuk error dan aksi destruktif.
     * @details Hex: #f85149 - Digunakan untuk tombol keluar, level gagal, kesalahan ketik.
     */
    readonly property color accentRed: "#f85149"

    /* ========================================================================
     * WARNA BACKGROUND STATUS (tint opacity 10%)
     * ======================================================================== */

    /**
     * @property successBg
     * @brief Background hijau semi-transparan untuk pesan sukses.
     * @details RGBA: (63, 185, 80, 0.1) - tint hijau opacity 10%.
     */
    readonly property color successBg: Qt.rgba(0.247, 0.725, 0.314, 0.1)

    /**
     * @property warningBg
     * @brief Background kuning semi-transparan untuk pesan peringatan.
     * @details RGBA: (210, 153, 34, 0.1) - tint kuning opacity 10%.
     */
    readonly property color warningBg: Qt.rgba(0.824, 0.600, 0.133, 0.1)

    /**
     * @property dangerBg
     * @brief Background merah semi-transparan untuk state bahaya/error.
     * @details RGBA: (248, 81, 73, 0.1) - tint merah opacity 10%.
     */
    readonly property color dangerBg: Qt.rgba(0.973, 0.318, 0.286, 0.1)

    /**
     * @property infoBg
     * @brief Background biru semi-transparan untuk state informasi.
     * @details RGBA: (88, 166, 255, 0.1) - tint biru opacity 10%.
     */
    readonly property color infoBg: Qt.rgba(0.345, 0.651, 1.0, 0.1)

    /* ========================================================================
     * UKURAN FONT (dalam piksel)
     * ======================================================================== */

    /** @property fontSizeS @brief Ukuran teks terkecil (11px) - header tabel, petunjuk */
    readonly property int fontSizeS: 11

    /** @property fontSizeSM @brief Teks kecil-sedang (12px) - subtitle, caption */
    readonly property int fontSizeSM: 12

    /** @property fontSizeM @brief Teks sedang/default (13px) - body text, label */
    readonly property int fontSizeM: 13

    /** @property fontSizeL @brief Teks besar (14px) - label yang ditekankan */
    readonly property int fontSizeL: 14

    /** @property fontSizeXL @brief Teks ekstra besar (15px) - label menu item */
    readonly property int fontSizeXL: 15

    /** @property fontSizeXXL @brief Teks double ekstra besar (18px) - header section */
    readonly property int fontSizeXXL: 18

    /** @property fontSizeDisplay @brief Ukuran display (24px) - judul halaman */
    readonly property int fontSizeDisplay: 24

    /** @property fontSizeLogo @brief Ukuran teks logo (64px) - "RAPID" di menu utama */
    readonly property int fontSizeLogo: 64

    /** @property fontSizeLogoSubtitle @brief Subtitle logo (12px) - "TEXTER" di menu utama */
    readonly property int fontSizeLogoSubtitle: 12

    /* ========================================================================
     * SPACING (dalam piksel)
     * ======================================================================== */

    /** @property spacingS @brief Spacing kecil (6px) - jarak ikon-teks */
    readonly property int spacingS: 6

    /** @property spacingSM @brief Spacing kecil-sedang (8px) - jarak menu item */
    readonly property int spacingSM: 8

    /** @property spacingM @brief Spacing sedang (12px) - jarak section */
    readonly property int spacingM: 12

    /** @property spacingL @brief Spacing besar (16px) - jarak komponen */
    readonly property int spacingL: 16

    /** @property spacingXL @brief Spacing ekstra besar (20px) - jarak section utama */
    readonly property int spacingXL: 20

    /** @property spacingXXL @brief Spacing double ekstra besar (24px) - margin halaman */
    readonly property int spacingXXL: 24

    /** @property spacingHuge @brief Spacing sangat besar (32px) - margin konten halaman */
    readonly property int spacingHuge: 32

    /** @property spacingLogo @brief Margin bawah logo (50px) - layout menu utama */
    readonly property int spacingLogo: 50

    /* ========================================================================
     * PADDING (dalam piksel)
     * ======================================================================== */

    /** @property paddingS @brief Padding kecil (6px) */
    readonly property int paddingS: 6

    /** @property paddingM @brief Padding sedang (10px) */
    readonly property int paddingM: 10

    /** @property paddingL @brief Padding besar (14px) */
    readonly property int paddingL: 14

    /** @property paddingXL @brief Padding ekstra besar (18px) - horizontal tombol */
    readonly property int paddingXL: 18

    /** @property paddingXXL @brief Padding double ekstra besar (24px) - area konten */
    readonly property int paddingXXL: 24

    /** @property paddingHuge @brief Padding sangat besar (28px) - margin halaman */
    readonly property int paddingHuge: 28

    /* ========================================================================
     * UKURAN KOMPONEN
     * ======================================================================== */

    /**
     * @property menuKeyMinWidth
     * @brief Lebar minimum untuk badge shortcut keyboard di menu (40px).
     * @details Memastikan badge [1], [2], dll. memiliki ukuran konsisten.
     */
    readonly property int menuKeyMinWidth: 40

    /**
     * @property statusBarHeight
     * @brief Tinggi status bar atas (40px).
     * @details Berisi indikator bahasa, waktu, mode dan toggle SFX.
     */
    readonly property int statusBarHeight: 40

    /**
     * @property maxContentWidth
     * @brief Lebar maksimum untuk kontainer konten terpusat (800px).
     * @details Mencegah konten melebar terlalu lebar di layar besar.
     */
    readonly property int maxContentWidth: 800

    /* ========================================================================
     * ANIMASI
     * ======================================================================== */

    /**
     * @property animationDuration
     * @brief Durasi animasi default dalam milidetik (150ms).
     * @details Digunakan untuk transisi hover, perubahan warna, translasi.
     */
    readonly property int animationDuration: 150

    /* ========================================================================
     * RADIUS BORDER
     * ======================================================================== */

    /** @property radiusS @brief Radius kecil (4px) - tombol, badge */
    readonly property int radiusS: 4

    /** @property radiusM @brief Radius sedang (8px) - kartu, input */
    readonly property int radiusM: 8

    /** @property radiusL @brief Radius besar (12px) - modal, panel */
    readonly property int radiusL: 12
}
