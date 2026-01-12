/**
 * @file MenuItemC.qml
 * @brief Rich menu item component with keyboard badges, icons, and status indicators.
 * @author RapidTexter Team
 * @date 2026
 *
 * MenuItemC provides a consistent menu item appearance throughout the application,
 * featuring keyboard shortcut badges, customizable icons, accent colors, and
 * support for various status states (locked, passed, certified).
 *
 * @section variants Accent Types
 * - "default": Blue accent for neutral items
 * - "green": Green accent for success/passed items
 * - "yellow": Yellow accent for warnings/custom options
 * - "red": Red accent for danger/destructive items
 *
 * @section statuses Status Types
 * - "passed": Green for completed levels
 * - "locked": Gray for unavailable items
 * - "certified": Blue for special achievements
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * @brief Interactive menu item with rich visual feedback.
 * @inherits Rectangle
 */
Rectangle {
    id: menuItem

    /* ========================================================================
     * PUBLIC PROPERTIES
     * ======================================================================== */

    /** @property keyText @brief Keyboard shortcut badge text (e.g., "[1]", "[ESC]"). */
    property string keyText: "[1]"

    /** @property iconSource @brief Path to SVG icon (qrc:/ format), rendered at 18x18px. */
    property string iconSource: ""

    /** @property labelText @brief Main menu item text label. */
    property string labelText: "Menu Item"

    /** @property accentType @brief Color accent variant: "default", "green", "yellow", "red". */
    property string accentType: "default"  // "default", "green", "yellow", "red"

    /** @property locked @brief Whether the menu item is disabled/locked. */
    property bool locked: false

    /** @property statusText @brief Status badge text (e.g., "[PASSED]", "[LOCKED]"). */
    property string statusText: ""  // e.g. "[PASSED]", "[LOCKED]", "[AVAILABLE]"

    /** @property statusType @brief Status badge type: "passed", "locked", "certified". */
    property string statusType: ""  // "passed", "locked", "certified"

    /** @property reqText @brief Requirement description text (e.g., "Min: 40 WPM, 80% Acc"). */
    property string reqText: ""     // e.g. "Min: 40 WPM, 80% Acc"

    /** @property busy @brief Whether the item is in a processing state (spinning icon). */
    property bool busy: false

    /** @signal clicked @brief Emitted when the menu item is clicked (only if not locked). */
    signal clicked

    /* ========================================================================
     * COMPUTED PROPERTIES
     * ======================================================================== */

    /**
     * @property hoverColor
     * @brief Computed accent color based on accentType and locked state.
     * @readonly
     */
    readonly property color hoverColor: {
        if (locked)
            return Theme.borderSecondary;
        switch (accentType) {
        case "green":
            return Theme.accentGreen;
        case "yellow":
            return Theme.accentYellow;
        case "red":
            return Theme.accentRed;
        default:
            return Theme.accentBlue;
        }
    }
    readonly property bool isHovered: itemMouse.containsMouse && !locked && !busy

    // Layout
    Layout.fillWidth: true
    height: 70
    color: isHovered ? Theme.bgSecondary : "transparent"
    opacity: (locked || busy) ? 0.5 : 1.0
    border.width: 1
    border.color: Theme.borderPrimary

    // Left accent bar
    Rectangle {
        width: 3
        height: parent.height
        color: menuItem.isHovered ? menuItem.hoverColor : Theme.borderSecondary
    }

    // Hover animation
    transform: Translate {
        x: menuItem.isHovered ? 4 : 0
        Behavior on x {
            NumberAnimation {
                duration: 150
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingXXL
        anchors.rightMargin: Theme.paddingXXL
        spacing: Theme.spacingL

        // Key badge
        Rectangle {
            Layout.preferredWidth: Math.max(Theme.menuKeyMinWidth, keyLbl.implicitWidth + Theme.paddingL * 2)
            Layout.preferredHeight: 26
            color: menuItem.isHovered ? Theme.borderSecondary : Theme.bgTertiary
            border.width: 1
            border.color: Theme.borderSecondary

            Text {
                id: keyLbl
                anchors.centerIn: parent
                text: menuItem.keyText
                color: menuItem.isHovered ? Theme.textPrimary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
                font.bold: true
            }
        }

        // Icon and label
        Row {
            Layout.fillWidth: true
            spacing: Theme.spacingM

            Item {
                width: menuItem.iconSource !== "" ? 18 : 0
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: menuIcon
                    source: menuItem.iconSource
                    anchors.fill: parent
                    sourceSize: Qt.size(18, 18)
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: menuIcon
                    source: menuIcon
                    color: menuItem.hoverColor
                    visible: menuItem.iconSource !== ""
                    opacity: menuItem.isHovered ? 1.0 : 0.7
                }
            }

            Text {
                text: menuItem.labelText
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXL
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Status badge and requirement info (for campaign levels)
        Column {
            visible: menuItem.statusText !== "" || menuItem.reqText !== ""
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                visible: menuItem.statusText !== ""
                anchors.right: parent.right
                width: statusLabel.implicitWidth + Theme.paddingM * 2
                height: 22
                color: {
                    switch (menuItem.statusType) {
                    case "passed":
                        return Qt.rgba(0.247, 0.725, 0.314, 0.1);
                    case "locked":
                        return Qt.rgba(0.973, 0.318, 0.286, 0.1);
                    case "certified":
                        return Qt.rgba(0.345, 0.651, 1.0, 0.1);
                    default:
                        return "transparent";
                    }
                }
                border.width: 1
                border.color: {
                    switch (menuItem.statusType) {
                    case "passed":
                        return Theme.accentGreen;
                    case "locked":
                        return Theme.accentRed;
                    case "certified":
                        return Theme.accentBlue;
                    default:
                        return Theme.borderSecondary;
                    }
                }

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: menuItem.statusText
                    color: {
                        switch (menuItem.statusType) {
                        case "passed":
                            return Theme.accentGreen;
                        case "locked":
                            return Theme.accentRed;
                        case "certified":
                            return Theme.accentBlue;
                        default:
                            return Theme.textSecondary;
                        }
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeS
                    font.bold: true
                    font.letterSpacing: 0.5
                }
            }

            Text {
                visible: menuItem.reqText !== ""
                anchors.right: parent.right
                text: menuItem.reqText
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    MouseArea {
        id: itemMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: locked ? Qt.ForbiddenCursor : Qt.PointingHandCursor
        onClicked: if (!menuItem.locked)
            menuItem.clicked()
    }
}
