/**
 * @file HistoryDetailOverlay.qml
 * @brief Overlay modal yang menampilkan informasi detail record game.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen overlay premium yang menampilkan statistik game komprehensif
 * saat record history diklik. Desain terinspirasi dari MonkeyType
 * sambil menjaga konsistensi dengan design system RapidTexter.
 *
 * @section shortcuts Keyboard Shortcuts
 * - Key_Escape: Tutup overlay
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * @brief Overlay modal untuk menampilkan detail record history.
 * @inherits Rectangle
 */
Rectangle {
    id: overlay
    anchors.fill: parent
    color: Qt.rgba(0.05, 0.067, 0.09, 0.85)
    visible: false
    opacity: 0
    z: 10000

    /** @property recordData @brief Objek record history yang akan ditampilkan. */
    property var recordData: null

    /** @property passed @brief Apakah target WPM telah tercapai. */
    property bool passed: recordData ? recordData.wpm >= recordData.targetWPM : false

    /** @property showOverlay @brief Mengontrol visibilitas overlay dengan animasi */
    property bool showOverlay: false

    /** @signal close @brief Dipancarkan saat overlay harus ditutup. */
    signal close

    /** @function formatTime @brief Memformat detik menjadi waktu yang mudah dibaca (contoh: "15.3s" atau "1m 30.5s") */
    function formatTime(seconds) {
        if (seconds === undefined || seconds === null || seconds === 0)
            return "-";
        // Tampilkan 1 desimal untuk presisi lebih baik
        if (seconds < 60) {
            return seconds.toFixed(1) + "s";
        } else {
            var mins = Math.floor(seconds / 60);
            var remainingSecs = seconds % 60;
            return mins + "m " + remainingSecs.toFixed(1) + "s";
        }
    }

    // State machine untuk animasi buka/tutup yang halus
    states: [
        State {
            name: "hidden"
            when: !showOverlay
            PropertyChanges {
                target: overlay
                opacity: 0
            }
            PropertyChanges {
                target: contentCard
                scale: 0.95
                opacity: 0
            }
        },
        State {
            name: "visible"
            when: showOverlay
            PropertyChanges {
                target: overlay
                visible: true
                opacity: 1
            }
            PropertyChanges {
                target: contentCard
                scale: 1
                opacity: 1
            }
        }
    ]

    transitions: [
        // Animasi pembukaan
        Transition {
            from: "hidden"
            to: "visible"
            SequentialAnimation {
                PropertyAction {
                    target: overlay
                    property: "visible"
                    value: true
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: contentCard
                        properties: "scale,opacity"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        },
        // Animasi penutupan
        Transition {
            from: "visible"
            to: "hidden"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation {
                        target: overlay
                        property: "opacity"
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                    NumberAnimation {
                        target: contentCard
                        properties: "scale,opacity"
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                }
                PropertyAction {
                    target: overlay
                    property: "visible"
                    value: false
                }
            }
        }
    ]

    // Sinkronisasi showOverlay dengan binding eksternal hanya saat dibuka
    onShowOverlayChanged: {
        // Saat parent mengatur showOverlay ke true, pastikan kita siap
        // Saat parent mengaturnya ke false, state machine menangani animasi
    }

    // Penanganan fokus untuk keyboard
    focus: showOverlay
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            close();
            event.accepted = true;
        }
    }

    // Klik background untuk menutup
    MouseArea {
        anchors.fill: parent
        onClicked: overlay.close()
    }

    // Kartu konten
    Rectangle {
        id: contentCard
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 580)
        height: contentColumn.implicitHeight + Theme.paddingXXL * 2
        color: Theme.bgSecondary
        border.width: 1
        border.color: Theme.borderPrimary
        radius: 8
        opacity: 0
        scale: 0.95

        // Mencegah klik menutup overlay
        MouseArea {
            anchors.fill: parent
            onClicked: {} // Menyerap klik
        }

        // Aksen bar kiri
        Rectangle {
            width: 4
            height: parent.height
            color: overlay.passed ? Theme.accentGreen : Theme.accentRed
            radius: 8
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.paddingXXL
            anchors.leftMargin: Theme.paddingXXL + 8
            spacing: Theme.spacingXL

            // Header dengan judul dan tombol tutup
            RowLayout {
                Layout.fillWidth: true

                Row {
                    spacing: Theme.spacingS
                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            id: headerIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(20, 20)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: headerIcon
                            source: headerIcon
                            color: Theme.accentBlue
                        }
                    }
                    Text {
                        text: "GAME DETAILS"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                // Tombol tutup
                Rectangle {
                    width: 28
                    height: 28
                    radius: 4
                    color: closeBtn.containsMouse ? Theme.bgTertiary : "transparent"

                    Item {
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                        Image {
                            id: closeIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(16, 16)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: closeIcon
                            source: closeIcon
                            color: closeBtn.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: closeBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: overlay.close()
                    }
                }
            }

            // Tampilan WPM (bagian utama)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: overlay.passed ? Theme.successBg : Theme.dangerBg
                border.width: 1
                border.color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                radius: 6

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: overlay.recordData ? Math.round(overlay.recordData.wpm) : "0"
                        color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: 48
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "WORDS PER MINUTE"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        font.letterSpacing: 1
                    }
                }
            }

            // Baris statistik
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingM

                Repeater {
                    model: [
                        {
                            label: "ACCURACY",
                            value: overlay.recordData ? overlay.recordData.accuracy.toFixed(1) + "%" : "0%",
                            color: Theme.textPrimary
                        },
                        {
                            label: "TARGET",
                            value: overlay.recordData ? overlay.recordData.targetWPM + " WPM" : "0 WPM",
                            color: Theme.accentBlue
                        },
                        {
                            label: "ERRORS",
                            value: overlay.recordData ? overlay.recordData.errors.toString() : "0",
                            color: Theme.accentRed
                        },
                        {
                            label: "TIME",
                            value: overlay.recordData ? formatTime(overlay.recordData.timeElapsed) : "-",
                            color: Theme.accentYellow
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.borderPrimary
                        radius: 6

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeS
                                font.letterSpacing: 1
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                color: modelData.color
                                font.family: Theme.fontFamily
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // Bagian info sesi
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: sessionInfoCol.implicitHeight + Theme.paddingL * 2
                color: Theme.bgPrimary
                border.width: 1
                border.color: Theme.borderPrimary
                radius: 6

                Column {
                    id: sessionInfoCol
                    anchors.fill: parent
                    anchors.margins: Theme.paddingL
                    spacing: Theme.spacingSM

                    Text {
                        text: "SESSION INFO"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                        font.letterSpacing: 1
                    }

                    GridLayout {
                        width: parent.width
                        columns: 2
                        rowSpacing: Theme.spacingS
                        columnSpacing: Theme.spacingL

                        // Tingkat kesulitan
                        Text {
                            text: "Difficulty"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.difficulty : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Bahasa
                        Text {
                            text: "Language"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.language : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Mode permainan
                        Text {
                            text: "Mode"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.mode : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Tanggal/Waktu
                        Text {
                            text: "Date/Time"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? overlay.recordData.timestamp : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        // Waktu Bermain
                        Text {
                            text: "Time Played"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: overlay.recordData ? formatTime(overlay.recordData.timeElapsed) : "-"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Banner status lulus/gagal
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: overlay.passed ? Theme.successBg : Theme.dangerBg
                border.width: 1
                border.color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                radius: 6

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    Item {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        Image {
                            id: statusIcon
                            source: overlay.passed ? "qrc:/qt/qml/rapid_texter/assets/icons/check.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(18, 18)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: statusIcon
                            source: statusIcon
                            color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        }
                    }
                    Text {
                        text: overlay.passed ? "TARGET ACHIEVED" : "TARGET NOT MET"
                        color: overlay.passed ? Theme.accentGreen : Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXXL
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Petunjuk menutup
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Press ESC or click outside to close"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
            }
        }
    }
}
