/**
 * @file SplashScreen.qml
 * @brief Professional splash screen with logo pulse animation and loading status.
 * @author RapidTexter Team
 * @date 2026
 *
 * Displays an animated splash screen while the application loads.
 * Features a pulsing logo animation and dynamic loading text.
 */
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * @brief Splash screen overlay component.
 * @inherits Rectangle
 *
 * @property bool applicationReady - Set to true when app is ready to dismiss splash
 * @signal finished() - Emitted when splash screen fade-out is complete
 */
Rectangle {
    id: splashRoot

    color: Theme.bgPrimary
    opacity: 1.0

    // Public properties
    property bool applicationReady: false
    property int minimumDisplayTime: 2000  // Minimum time to show splash (ms)

    // Internal state
    property bool canDismiss: false
    property int loadingStep: 0

    // Signal when splash is done
    signal finished

    // Loading messages
    readonly property var loadingMessages: ["Initializing...", "Loading resources...", "Preparing interface...", "Almost ready..."]

    // Minimum display timer
    Timer {
        id: minimumTimer
        interval: splashRoot.minimumDisplayTime
        running: true
        onTriggered: {
            splashRoot.canDismiss = true;
            if (splashRoot.applicationReady) {
                fadeOutAnimation.start();
            }
        }
    }

    // Loading step animation timer
    Timer {
        id: loadingStepTimer
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            splashRoot.loadingStep = (splashRoot.loadingStep + 1) % splashRoot.loadingMessages.length;
        }
    }

    // Watch for application ready
    onApplicationReadyChanged: {
        if (applicationReady && canDismiss) {
            fadeOutAnimation.start();
        }
    }

    // Fade out animation
    SequentialAnimation {
        id: fadeOutAnimation

        PauseAnimation {
            duration: 300
        }

        ParallelAnimation {
            NumberAnimation {
                target: splashRoot
                property: "opacity"
                to: 0
                duration: 400
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: logoContainer
                property: "scale"
                to: 1.1
                duration: 400
                easing.type: Easing.OutQuad
            }
        }

        ScriptAction {
            script: {
                loadingStepTimer.stop();
                splashRoot.finished();
            }
        }
    }

    // Main content container
    Item {
        id: logoContainer
        anchors.centerIn: parent
        width: logoColumn.width
        height: logoColumn.height

        // Pulse animation
        SequentialAnimation on scale {
            running: splashRoot.opacity > 0
            loops: Animation.Infinite
            NumberAnimation {
                from: 1.0
                to: 1.03
                duration: 1200
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 1.03
                to: 1.0
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }

        Column {
            id: logoColumn
            spacing: Theme.spacingM

            // RAPID text
            Text {
                id: rapidText
                anchors.horizontalCenter: parent.horizontalCenter
                text: "RAPID"
                color: Theme.accentBlue
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLogo
                font.bold: true
                font.letterSpacing: -3

                // Subtle glow effect
                layer.enabled: true
                layer.effect: Glow {
                    radius: 20
                    samples: 41
                    color: Qt.rgba(Theme.accentBlue.r, Theme.accentBlue.g, Theme.accentBlue.b, 0.3)
                    spread: 0.2
                }
            }

            // TEXTER text
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "TEXTER"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLogoSubtitle
                font.bold: true
                font.letterSpacing: 5
                opacity: 0.7
            }
        }
    }

    // Loading indicator section
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: Theme.spacingL

        // Loading dots animation
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: 3

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.accentBlue

                    // Staggered bounce animation
                    SequentialAnimation on opacity {
                        running: splashRoot.opacity > 0
                        loops: Animation.Infinite
                        PauseAnimation {
                            duration: index * 200
                        }
                        NumberAnimation {
                            from: 0.3
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 1.0
                            to: 0.3
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                        PauseAnimation {
                            duration: (2 - index) * 200
                        }
                    }

                    SequentialAnimation on y {
                        running: splashRoot.opacity > 0
                        loops: Animation.Infinite
                        PauseAnimation {
                            duration: index * 200
                        }
                        NumberAnimation {
                            from: 0
                            to: -6
                            duration: 300
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            from: -6
                            to: 0
                            duration: 300
                            easing.type: Easing.InQuad
                        }
                        PauseAnimation {
                            duration: (2 - index) * 200
                        }
                    }
                }
            }
        }

        // Loading status text
        Text {
            id: loadingText
            anchors.horizontalCenter: parent.horizontalCenter
            text: splashRoot.loadingMessages[splashRoot.loadingStep]
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSM

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation {
                        target: loadingText
                        property: "opacity"
                        to: 0
                        duration: 150
                    }
                    PropertyAction {}
                    NumberAnimation {
                        target: loadingText
                        property: "opacity"
                        to: 1
                        duration: 150
                    }
                }
            }
        }
    }
}
