/**
 * @file NavBtn.qml
 * @brief Reusable navigation button component with icon and label support.
 * @author RapidTexter Team
 * @date 2026
 *
 * NavBtn is a styled button used for navigation actions throughout the
 * application. It supports multiple visual variants for different action
 * types and includes optional SVG icons with color overlays.
 *
 * @section usage Usage Example
 * @code
 * NavBtn {
 *     iconSource: "qrc:/icons/arrow-left.svg"
 *     labelText: "Back (ESC)"
 *     variant: "default"
 *     onClicked: stackView.pop()
 * }
 * @endcode
 *
 * @section variants Visual Variants
 * - "default": Blue accent (neutral navigation)
 * - "primary": Green accent with filled background (main actions)
 * - "danger": Red accent (destructive actions)
 * - "reset"/"yellow": Yellow accent (reset/warning actions)
 */
import QtQuick
import Qt5Compat.GraphicalEffects

/**
 * @brief Styled navigation button with icon and text.
 * @inherits Rectangle
 *
 * Features:
 * - SVG icon support with automatic color overlay
 * - Five visual variants for different action types
 * - Hover state with smooth color transitions
 * - Consistent 36px height across all instances
 */
Rectangle {
    id: navBtn

    /* ========================================================================
     * PUBLIC PROPERTIES
     * ======================================================================== */

    /**
     * @property iconText
     * @brief Deprecated emoji fallback for icons.
     * @deprecated Use iconSource instead for SVG icons.
     */
    property string iconText: ""

    /**
     * @property iconSource
     * @brief Path to SVG icon file (qrc:/ format).
     * @details Icon is rendered at 14x14 pixels with color overlay matching variant.
     */
    property string iconSource: ""

    /**
     * @property labelText
     * @brief Button text displayed next to the icon.
     * @default "Button"
     */
    property string labelText: "Button"

    /**
     * @property variant
     * @brief Visual style variant affecting colors.
     * @details Valid values:
     *          - "default": Blue accent color
     *          - "primary": Green accent with success background
     *          - "danger": Red accent for destructive actions
     *          - "reset": Yellow accent (alias for "yellow")
     *          - "yellow": Yellow accent for warnings
     * @default "default"
     */
    property string variant: "default"

    /* ========================================================================
     * SIGNALS
     * ======================================================================== */

    /**
     * @property isLoading
     * @brief Whether the button is in a loading state.
     * @details When true, the icon rotates and the button should typically be disabled.
     */
    property bool isLoading: false

    /* ========================================================================
     * SIGNALS
     * ======================================================================== */

    /**
     * @signal clicked
     * @brief Emitted when the button is clicked.
     */
    signal clicked

    /* ========================================================================
     * COMPUTED PROPERTIES
     * ======================================================================== */

    /**
     * @property isHovered
     * @brief True when mouse is over the button.
     * @readonly
     */
    readonly property bool isHovered: navMouse.containsMouse

    /**
     * @property variantColor
     * @brief Computed accent color based on variant property.
     * @readonly
     * @details Maps variant string to Theme accent colors:
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
     * SIZING
     * ======================================================================== */

    /**
     * @brief Implicit width based on content plus horizontal padding.
     * @details Width = row content width + (paddingXL × 2) = content + 36px
     */
    implicitWidth: navRow.implicitWidth + Theme.paddingXL * 2

    /**
     * @brief Fixed height of 36 pixels for consistent button appearance.
     */
    implicitHeight: 36

    /* ========================================================================
     * STYLING
     * ======================================================================== */

    /**
     * @brief Background color changes on hover based on variant.
     * @details Default variant uses bgSecondary on hover.
     *          Other variants use 10% opacity tint of their accent color.
     *          Primary variant shows successBg even when not hovered.
     */
    color: isHovered ? (variant === "default" ? Theme.bgSecondary : Qt.rgba(variantColor.r, variantColor.g, variantColor.b, 0.1)) : (variant === "primary" ? Theme.successBg : "transparent")

    /** @brief 1-pixel border around the button */
    border.width: 1

    /**
     * @brief Border color based on hover state and variant.
     * @details Hovered or non-default variants show accent color.
     *          Default variant shows borderSecondary when not hovered.
     */
    border.color: isHovered ? variantColor : (variant !== "default" ? variantColor : Theme.borderSecondary)

    /* ========================================================================
     * CONTENT LAYOUT
     * ======================================================================== */

    /**
     * @brief Horizontal layout for icon and label.
     */
    Row {
        id: navRow
        anchors.centerIn: parent
        spacing: Theme.spacingSM  /* 8px gap between icon and text */

        /**
         * @brief Container for SVG icon with color overlay.
         * @details Width is 0 when no iconSource is set to collapse spacing.
         */
        Item {
            id: iconItem
            width: navBtn.iconSource !== "" ? 14 : 0  /* 14px icon or 0 if none */
            height: 14
            anchors.verticalCenter: parent.verticalCenter

            /**
             * @brief Spin animation for loading state
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
             * @brief SVG image source (hidden, used as overlay source).
             */
            Image {
                id: navIcon
                source: navBtn.iconSource
                anchors.fill: parent
                sourceSize: Qt.size(14, 14)
                visible: false  /* Hidden - ColorOverlay renders the visible icon */
            }

            /**
             * @brief Color overlay applying variant color to the icon.
             * @details Opacity increases from 0.7 to 1.0 on hover for subtle effect.
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
         * @brief Fallback emoji icon display (deprecated).
         */
        Text {
            text: navBtn.iconText
            font.pixelSize: Theme.fontSizeSM  /* 12px */
            visible: navBtn.iconText !== "" && navBtn.iconSource === ""
        }

        /**
         * @brief Button label text.
         * @details Color changes to accent on hover for non-default variants,
         *          or always shows accent color for non-default variants.
         */
        Text {
            text: navBtn.labelText
            color: navBtn.isHovered ? navBtn.variantColor : (navBtn.variant !== "default" ? navBtn.variantColor : Theme.textSecondary)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeM  /* 13px */
        }
    }

    /* ========================================================================
     * MOUSE INTERACTION
     * ======================================================================== */

    /**
     * @brief Mouse area for click and hover detection.
     */
    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor  /* Show pointer cursor on hover */
        onClicked: navBtn.clicked()
    }
}
