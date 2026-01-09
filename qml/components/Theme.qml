/**
 * @file Theme.qml
 * @brief Singleton design system providing consistent theming across the application.
 * @author RapidTexter Team
 * @date 2026
 *
 * This singleton defines all visual design tokens used throughout the RapidTexter
 * application, implementing a GitHub-inspired dark theme. By centralizing these
 * values, the application maintains visual consistency and enables easy theme
 * modifications.
 *
 * @note This is a QML Singleton - only one instance exists and is accessible
 *       application-wide without instantiation.
 *
 * @section colors Color Palette
 * The color scheme uses a dark background with high-contrast accent colors:
 * - Background: Dark grays (#0d1117 → #21262d)
 * - Text: Light grays (#c9d1d9 for primary, #484f58 for muted)
 * - Accents: Blue (#58a6ff), Green (#3fb950), Yellow (#d29922), Red (#f85149)
 *
 * @section typography Typography Scale
 * Uses JetBrains Mono font with a modular size scale from 11px to 64px.
 *
 * @section spacing Spacing System
 * Consistent spacing values from 6px (small) to 50px (logo spacing).
 */
pragma Singleton
import QtQuick

/**
 * @brief Root theme object containing all design tokens.
 *
 * Access properties via Theme.propertyName (e.g., Theme.bgPrimary, Theme.fontSizeL)
 */
QtObject {
    id: theme

    /* ========================================================================
     * TYPOGRAPHY
     * ======================================================================== */

    /**
     * @property fontFamily
     * @brief Primary font family for all text elements.
     * @details Set to "JetBrains Mono" after the font loads in Main.qml.
     *          This monospace font is ideal for typing applications as it
     *          provides consistent character widths for accurate cursor positioning.
     */
    property string fontFamily: "JetBrains Mono"

    /* ========================================================================
     * BACKGROUND COLORS
     * ======================================================================== */

    /**
     * @property bgPrimary
     * @brief Darkest background color for main content areas.
     * @details Hex: #0d1117 (RGB: 13, 17, 23)
     */
    readonly property color bgPrimary: "#0d1117"

    /**
     * @property bgSecondary
     * @brief Slightly lighter background for elevated elements (status bar, cards).
     * @details Hex: #161b22 (RGB: 22, 27, 34)
     */
    readonly property color bgSecondary: "#161b22"

    /**
     * @property bgTertiary
     * @brief Background for interactive hover states and key badges.
     * @details Hex: #21262d (RGB: 33, 38, 45)
     */
    readonly property color bgTertiary: "#21262d"

    /* ========================================================================
     * BORDER COLORS
     * ======================================================================== */

    /**
     * @property borderPrimary
     * @brief Subtle border color for containers and separators.
     * @details Hex: #21262d - Same as bgTertiary for consistency.
     */
    readonly property color borderPrimary: "#21262d"

    /**
     * @property borderSecondary
     * @brief Lighter border for hover states and higher contrast needs.
     * @details Hex: #30363d (RGB: 48, 54, 61)
     */
    readonly property color borderSecondary: "#30363d"

    /* ========================================================================
     * TEXT COLORS
     * ======================================================================== */

    /**
     * @property textPrimary
     * @brief Main text color for important content and headings.
     * @details Hex: #c9d1d9 - High contrast against dark backgrounds.
     */
    readonly property color textPrimary: "#c9d1d9"

    /**
     * @property textSecondary
     * @brief Subdued text color for labels and supporting content.
     * @details Hex: #8b949e - Medium contrast for secondary information.
     */
    readonly property color textSecondary: "#8b949e"

    /**
     * @property textMuted
     * @brief Low-emphasis text for hints and disabled states.
     * @details Hex: #484f58 - Low contrast, used sparingly.
     */
    readonly property color textMuted: "#484f58"

    /* ========================================================================
     * ACCENT COLORS
     * ======================================================================== */

    /**
     * @property accentBlue
     * @brief Primary accent color for links, focus states, and neutral actions.
     * @details Hex: #58a6ff - Used for language status, navigation hints.
     */
    readonly property color accentBlue: "#58a6ff"

    /**
     * @property accentGreen
     * @brief Success accent color for positive states and primary actions.
     * @details Hex: #3fb950 - Used for passed levels, correct input, start button.
     */
    readonly property color accentGreen: "#3fb950"

    /**
     * @property accentYellow
     * @brief Warning accent color for caution states and secondary actions.
     * @details Hex: #d29922 - Used for reset buttons, custom options.
     */
    readonly property color accentYellow: "#d29922"

    /**
     * @property accentRed
     * @brief Danger accent color for errors and destructive actions.
     * @details Hex: #f85149 - Used for quit button, failed levels, typing errors.
     */
    readonly property color accentRed: "#f85149"

    /* ========================================================================
     * STATUS BACKGROUND COLORS (10% opacity tints)
     * ======================================================================== */

    /**
     * @property successBg
     * @brief Semi-transparent green background for success messages.
     * @details RGBA: (63, 185, 80, 0.1) - 10% opacity green tint.
     */
    readonly property color successBg: Qt.rgba(0.247, 0.725, 0.314, 0.1)

    /**
     * @property warningBg
     * @brief Semi-transparent yellow background for warning messages.
     * @details RGBA: (210, 153, 34, 0.1) - 10% opacity yellow tint.
     */
    readonly property color warningBg: Qt.rgba(0.824, 0.600, 0.133, 0.1)

    /**
     * @property dangerBg
     * @brief Semi-transparent red background for danger/error states.
     * @details RGBA: (248, 81, 73, 0.1) - 10% opacity red tint.
     */
    readonly property color dangerBg: Qt.rgba(0.973, 0.318, 0.286, 0.1)

    /**
     * @property infoBg
     * @brief Semi-transparent blue background for informational states.
     * @details RGBA: (88, 166, 255, 0.1) - 10% opacity blue tint.
     */
    readonly property color infoBg: Qt.rgba(0.345, 0.651, 1.0, 0.1)

    /* ========================================================================
     * FONT SIZES (in pixels)
     * ======================================================================== */

    /** @property fontSizeS @brief Smallest text size (11px) - table headers, hints */
    readonly property int fontSizeS: 11

    /** @property fontSizeSM @brief Small-medium text (12px) - subtitles, captions */
    readonly property int fontSizeSM: 12

    /** @property fontSizeM @brief Medium/default text (13px) - body text, labels */
    readonly property int fontSizeM: 13

    /** @property fontSizeL @brief Large text (14px) - emphasized labels */
    readonly property int fontSizeL: 14

    /** @property fontSizeXL @brief Extra large text (15px) - menu item labels */
    readonly property int fontSizeXL: 15

    /** @property fontSizeXXL @brief Double extra large (18px) - section headers */
    readonly property int fontSizeXXL: 18

    /** @property fontSizeDisplay @brief Display size (24px) - page titles */
    readonly property int fontSizeDisplay: 24

    /** @property fontSizeLogo @brief Logo text size (64px) - main menu "RAPID" */
    readonly property int fontSizeLogo: 64

    /** @property fontSizeLogoSubtitle @brief Logo subtitle (12px) - main menu "TEXTER" */
    readonly property int fontSizeLogoSubtitle: 12

    /* ========================================================================
     * SPACING (in pixels)
     * ======================================================================== */

    /** @property spacingS @brief Small spacing (6px) - icon-text gaps */
    readonly property int spacingS: 6

    /** @property spacingSM @brief Small-medium spacing (8px) - menu item gaps */
    readonly property int spacingSM: 8

    /** @property spacingM @brief Medium spacing (12px) - section gaps */
    readonly property int spacingM: 12

    /** @property spacingL @brief Large spacing (16px) - component gaps */
    readonly property int spacingL: 16

    /** @property spacingXL @brief Extra large spacing (20px) - major section gaps */
    readonly property int spacingXL: 20

    /** @property spacingXXL @brief Double extra large (24px) - page margins */
    readonly property int spacingXXL: 24

    /** @property spacingHuge @brief Huge spacing (32px) - page content margins */
    readonly property int spacingHuge: 32

    /** @property spacingLogo @brief Logo bottom margin (50px) - main menu layout */
    readonly property int spacingLogo: 50

    /* ========================================================================
     * PADDING (in pixels)
     * ======================================================================== */

    /** @property paddingS @brief Small padding (6px) */
    readonly property int paddingS: 6

    /** @property paddingM @brief Medium padding (10px) */
    readonly property int paddingM: 10

    /** @property paddingL @brief Large padding (14px) */
    readonly property int paddingL: 14

    /** @property paddingXL @brief Extra large padding (18px) - button horizontal */
    readonly property int paddingXL: 18

    /** @property paddingXXL @brief Double extra large (24px) - content areas */
    readonly property int paddingXXL: 24

    /** @property paddingHuge @brief Huge padding (28px) - page margins */
    readonly property int paddingHuge: 28

    /* ========================================================================
     * COMPONENT SIZES
     * ======================================================================== */

    /**
     * @property menuKeyMinWidth
     * @brief Minimum width for keyboard shortcut badges in menus (40px).
     * @details Ensures [1], [2], etc. badges have consistent sizing.
     */
    readonly property int menuKeyMinWidth: 40

    /**
     * @property statusBarHeight
     * @brief Height of the top status bar (40px).
     * @details Contains language, time, mode indicators and SFX toggle.
     */
    readonly property int statusBarHeight: 40

    /**
     * @property maxContentWidth
     * @brief Maximum width for centered content containers (800px).
     * @details Prevents content from stretching too wide on large screens.
     */
    readonly property int maxContentWidth: 800

    /* ========================================================================
     * ANIMATION
     * ======================================================================== */

    /**
     * @property animationDuration
     * @brief Default animation duration in milliseconds (150ms).
     * @details Used for hover transitions, color changes, translations.
     */
    readonly property int animationDuration: 150

    /* ========================================================================
     * BORDER RADIUS
     * ======================================================================== */

    /** @property radiusS @brief Small radius (4px) - buttons, badges */
    readonly property int radiusS: 4

    /** @property radiusM @brief Medium radius (8px) - cards, inputs */
    readonly property int radiusM: 8

    /** @property radiusL @brief Large radius (12px) - modals, panels */
    readonly property int radiusL: 12
}
