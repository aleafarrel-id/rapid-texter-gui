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
 * @details Rectangle layar penuh yang menampilkan logo animasi
 * dan indikator loading saat aplikasi diinisialisasi.
 */
Rectangle {
    id: splashRoot

    color: Theme.bgPrimary
    opacity: 1.0

    /* ========================================================================
     * PROPERTI PUBLIK
     * ======================================================================== */

    /**
     * @property applicationReady
     * @brief Set ke true saat aplikasi siap untuk menutup splash.
     * @type bool
     * @default false
     */
    property bool applicationReady: false

    /**
     * @property minimumDisplayTime
     * @brief Waktu minimum menampilkan splash dalam milidetik.
     * @type int
     * @default 2000
     */
    property int minimumDisplayTime: 2000

    /* ========================================================================
     * PROPERTI INTERNAL
     * ======================================================================== */

    /**
     * @property canDismiss
     * @brief Apakah splash sudah bisa ditutup (setelah minimumDisplayTime).
     * @type bool
     * @private
     */
    property bool canDismiss: false

    /**
     * @property loadingStep
     * @brief Index pesan loading yang sedang ditampilkan.
     * @type int
     * @private
     */
    property int loadingStep: 0

    /* ========================================================================
     * SIGNAL
     * ======================================================================== */

    /**
     * @signal finished
     * @brief Dipancarkan saat animasi fade-out splash screen selesai.
     */
    signal finished

    /**
     * @property loadingMessages
     * @brief Array pesan loading yang ditampilkan secara bergantian.
     * @readonly
     */
    readonly property var loadingMessages: ["Initializing...", "Loading resources...", "Preparing interface...", "Almost ready..."]

    /* ========================================================================
     * TIMER
     * ======================================================================== */

    /**
     * @brief Timer untuk memastikan splash ditampilkan minimum selama minimumDisplayTime.
     *
     * @details Setelah timer selesai, splash bisa ditutup jika applicationReady.
     */
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

    /**
     * @brief Timer untuk menganimasi pergantian pesan loading.
     *
     * @details Mengganti pesan loading setiap 600ms.
     */
    Timer {
        id: loadingStepTimer
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            splashRoot.loadingStep = (splashRoot.loadingStep + 1) % splashRoot.loadingMessages.length;
        }
    }

    /* ========================================================================
     * HANDLER
     * ======================================================================== */

    /// @brief Handler saat applicationReady berubah - menutup splash jika sudah bisa dismiss
    onApplicationReadyChanged: {
        if (applicationReady && canDismiss) {
            fadeOutAnimation.start();
        }
    }
    /* ========================================================================
     * ANIMASI
     * ======================================================================== */

    /**
     * @brief Animasi fade-out saat splash selesai.
     *
     * @details Urutan animasi:
     * 1. Pause sebentar (300ms)
     * 2. Fade opacity ke 0 + scale logo ke 1.1 bersamaan (400ms)
     * 3. Stop timer dan emit signal finished
     */
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

    /* ========================================================================
     * UI LAYOUT
     * ======================================================================== */

    /**
     * @brief Kontainer konten utama untuk logo dan animasi.
     *
     * @details Item centered yang berisi Column dengan teks RAPID dan TEXTER.
     */
    Item {
        id: logoContainer
        anchors.centerIn: parent
        width: logoColumn.width
        height: logoColumn.height

        /// @brief Animasi pulse untuk efek "nafas" pada logo
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

            /// @brief Teks "RAPID" dengan efek glow
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
