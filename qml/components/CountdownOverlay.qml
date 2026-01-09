/**
 * @file CountdownOverlay.qml
 * @brief Full-screen countdown overlay (3, 2, 1, GO!)
 *
 * Uses clean text design without emojis.
 */
import QtQuick
import "."

Rectangle {
    id: overlay
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.9)
    visible: false
    z: 1000

    property int countdown: 3
    property bool isActive: false

    signal finished

    function start() {
        countdown = 3;
        visible = true;
        isActive = true;
        countdownTimer.start();
    }

    function stop() {
        countdownTimer.stop();
        visible = false;
        isActive = false;
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            countdown--;
            if (countdown < 0) {
                stop();
                overlay.visible = false;
                overlay.isActive = false;
                overlay.finished();
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 16

        // Main countdown number/text
        Text {
            id: countdownText
            anchors.horizontalCenter: parent.horizontalCenter
            text: countdown > 0 ? countdown.toString() : "GO!"
            color: countdown > 0 ? Theme.textPrimary : Theme.accentGreen
            font.family: Theme.fontFamily
            font.pixelSize: 140
            font.bold: true

            // Scale animation
            transform: Scale {
                id: scaleTransform
                origin.x: countdownText.width / 2
                origin.y: countdownText.height / 2
                xScale: 1.0
                yScale: 1.0
            }

            SequentialAnimation {
                running: overlay.isActive
                loops: Animation.Infinite

                NumberAnimation {
                    target: scaleTransform
                    properties: "xScale,yScale"
                    to: 1.15
                    duration: 400
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: scaleTransform
                    properties: "xScale,yScale"
                    to: 1.0
                    duration: 400
                    easing.type: Easing.InQuad
                }
            }
        }

        // Subtitle
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: countdown > 0 ? "Get Ready!" : "Type!"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXL
        }

        // Progress dots
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: 3

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: (3 - countdown) > index ? Theme.accentGreen : Theme.bgTertiary
                    border.color: Theme.borderSecondary
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }
        }
    }

    // Click to skip (for testing)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Disabled in production
        }
    }
}
