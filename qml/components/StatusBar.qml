/**
 * @file StatusBar.qml
 * @brief Application-wide status bar displaying game state and settings.
 * @author RapidTexter Team
 * @date 2026
 *
 * The StatusBar component provides a persistent header showing the current
 * game configuration (language, duration, mode) and provides quick access
 * to toggle sound effects on/off.
 *
 * @section integration Integration
 * Used in Main.qml as a fixed header above the StackView navigation.
 * Reads properties from mainWindow: currentLanguage, currentTime, currentMode, sfxEnabled.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * @brief Status bar component showing game configuration.
 * @inherits Rectangle
 */
Rectangle {
    id: statusBar

    /* ========================================================================
     * PUBLIC PROPERTIES
     * ======================================================================== */

    /** @property currentLanguage @brief Currently selected language ("Indonesia", "English", "Prog"). */
    property string currentLanguage: "-"

    /** @property currentTime @brief Selected game duration (e.g., "60s", "∞"). */
    property string currentTime: "-"

    /** @property currentMode @brief Selected game mode ("Manual" or "Campaign"). */
    property string currentMode: "-"

    /** @property sfxEnabled @brief Whether sound effects are enabled. */
    property bool sfxEnabled: true

    /** @property showShortcutHint @brief Show [S] shortcut indicator for SFX toggle. */
    property bool showShortcutHint: true  // Show [S] shortcut indicator

    /** @property playerName @brief Name of the player to display. */
    property string playerName: ""

    /** @signal sfxToggled @brief Emitted when SFX toggle button is clicked. */
    signal sfxToggled

    /** @signal nameClicked @brief Emitted when the player name is clicked. */
    signal nameClicked

    /* ========================================================================
     * STYLING
     * ======================================================================== */

    /** @brief Fixed height of 40px (Theme.statusBarHeight). */
    height: Theme.statusBarHeight

    /** @brief Secondary background for elevation appearance. */
    color: Theme.bgSecondary

    /** @brief 1-pixel bottom border for visual separation. */
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderPrimary
    }

    // Debounce lock to prevent double clicks
    property bool _interactionLocked: false

    Timer {
        id: debounceTimer
        interval: 500
        repeat: false
        onTriggered: statusBar._interactionLocked = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.paddingHuge
        anchors.rightMargin: Theme.paddingHuge

        // Left side status items
        Row {
            spacing: Theme.spacingXL

            // Language
            Row {
                spacing: Theme.spacingS
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: langIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: langIcon
                        source: langIcon
                        color: Theme.accentBlue
                    }
                }
                Text {
                    text: "Lang:"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: statusBar.currentLanguage.toUpperCase()
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: "|"
                color: Theme.borderSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
            }

            // Time
            Row {
                spacing: Theme.spacingS
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: timerIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: timerIcon
                        source: timerIcon
                        color: Theme.accentBlue
                    }
                }
                Text {
                    text: "Time:"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: statusBar.currentTime
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                    visible: statusBar.currentTime !== "Infinity"
                }
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: statusBar.currentTime === "Infinity"
                    Image {
                        id: infStatusIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/infinity.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: infStatusIcon
                        source: infStatusIcon
                        color: Theme.textPrimary
                    }
                }
            }

            Text {
                text: "|"
                color: Theme.borderSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeM
            }

            // Mode
            Row {
                spacing: Theme.spacingS
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: modeIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/gamepad.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: modeIcon
                        source: modeIcon
                        color: Theme.accentBlue
                    }
                }
                Text {
                    text: "Mode:"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: statusBar.currentMode
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // SFX Toggle
        Rectangle {
            Layout.preferredWidth: sfxRow.implicitWidth + Theme.paddingL * 2
            Layout.preferredHeight: parent.height - Theme.spacingM
            color: sfxMouse.containsMouse ? Theme.bgTertiary : "transparent"
            radius: 4

            Row {
                id: sfxRow
                anchors.centerIn: parent
                spacing: Theme.spacingS
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: sfxIconOn
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/volume-on.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    Image {
                        id: sfxIconOff
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/volume-off.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: parent
                        source: statusBar.sfxEnabled ? sfxIconOn : sfxIconOff
                        color: statusBar.sfxEnabled ? Theme.accentBlue : Theme.accentRed
                    }
                }
                Text {
                    text: (statusBar.showShortcutHint ? "[S] " : "") + "SFX:"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: statusBar.sfxEnabled ? "On" : "Off"
                    color: statusBar.sfxEnabled ? Theme.textPrimary : Theme.accentRed
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: sfxMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: statusBar.sfxToggled()
            }
        }

        // Spacer
        Item {
            width: Theme.spacingL
        }

        // Player Name Display
        Rectangle {
            Layout.preferredWidth: nameRow.implicitWidth + Theme.paddingL * 2
            Layout.preferredHeight: parent.height - Theme.spacingM
            color: nameMouse.containsMouse ? Theme.bgTertiary : "transparent"
            radius: 4
            visible: statusBar.playerName !== ""

            Row {
                id: nameRow
                anchors.centerIn: parent
                spacing: Theme.spacingS
                Item {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: userIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/user.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(14, 14)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: userIcon
                        source: userIcon
                        color: Theme.accentGreen
                    }
                }
                Text {
                    text: statusBar.playerName
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeM
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: nameMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: statusBar.showShortcutHint  // Disable interaction during gameplay
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (statusBar._interactionLocked)
                        return;
                    statusBar._interactionLocked = true;
                    debounceTimer.start();
                    statusBar.nameClicked();
                }

                ToolTip.visible: containsMouse
                ToolTip.delay: 500
                ToolTip.text: "Click to change name"
            }
        }
    }
}
