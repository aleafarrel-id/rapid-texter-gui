/**
 * @file SplashScreen.qml
 * @brief Splash screen profesional dengan animasi pulse logo dan status loading.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Menampilkan splash screen animasi saat aplikasi dimuat.
 * Menampilkan animasi logo pulsing dan teks loading dinamis.
 *
 * @section animation Animasi
 * - Animasi pulse pada logo RAPID/TEXTER
 * - Animasi bounce bertahap pada loading dots
 * - Animasi fade-out saat aplikasi siap
 */
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * @brief Komponen overlay splash screen.
 * @inherits Rectangle
 *
 * @property bool applicationReady - Set ke true saat aplikasi siap untuk menutup splash
 * @signal finished() - Dikirim saat animasi fade-out splash screen selesai
 */
Rectangle {
    id: splashRoot

    color: Theme.bgPrimary
    opacity: 1.0

    // Properti publik
    property bool applicationReady: false
    property int minimumDisplayTime: 2000  // Waktu minimum menampilkan splash (ms)

    // State internal
    property bool canDismiss: false
    property int loadingStep: 0

    // Signal saat splash selesai
    signal finished

    // Pesan loading
    readonly property var loadingMessages: ["Menginisialisasi...", "Memuat resources...", "Menyiapkan antarmuka...", "Hampir siap..."]

    // Timer tampilan minimum
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

    // Timer animasi langkah loading
    Timer {
        id: loadingStepTimer
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            splashRoot.loadingStep = (splashRoot.loadingStep + 1) % splashRoot.loadingMessages.length;
        }
    }

    // Pantau aplikasi siap
    onApplicationReadyChanged: {
        if (applicationReady && canDismiss) {
            fadeOutAnimation.start();
        }
    }

    // Animasi fade out
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

    // Kontainer konten utama
    Item {
        id: logoContainer
        anchors.centerIn: parent
        width: logoColumn.width
        height: logoColumn.height

        // Animasi pulse
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

            // Teks RAPID
            Text {
                id: rapidText
                anchors.horizontalCenter: parent.horizontalCenter
                text: "RAPID"
                color: Theme.accentBlue
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLogo
                font.bold: true
                font.letterSpacing: -3

                // Efek glow halus
                layer.enabled: true
                layer.effect: Glow {
                    radius: 20
                    samples: 41
                    color: Qt.rgba(Theme.accentBlue.r, Theme.accentBlue.g, Theme.accentBlue.b, 0.3)
                    spread: 0.2
                }
            }

            // Teks TEXTER
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

    // Bagian indikator loading
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: Theme.spacingL

        // Animasi loading dots
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

                    // Animasi bounce bertahap
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

        // Teks status loading
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
