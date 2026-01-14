/**
 * @file MenuItemC.qml
 * @brief Komponen menu item yang kaya dengan badge keyboard, ikon, dan indikator status.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details MenuItemC menyediakan tampilan menu item yang konsisten di seluruh aplikasi,
 * menampilkan badge shortcut keyboard, ikon yang dapat dikustomisasi, warna aksen, dan
 * dukungan untuk berbagai state status (terkunci, lulus, bersertifikat).
 *
 * @section variants Tipe Aksen
 * - "default": Aksen biru untuk item netral
 * - "green": Aksen hijau untuk item sukses/lulus
 * - "yellow": Aksen kuning untuk peringatan/opsi kustom
 * - "red": Aksen merah untuk item destruktif/berbahaya
 *
 * @section statuses Tipe Status
 * - "passed": Hijau untuk level yang sudah selesai
 * - "locked": Abu-abu untuk item yang tidak tersedia
 * - "certified": Biru untuk pencapaian khusus
 */
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * @brief Menu item interaktif dengan feedback visual yang kaya.
 * @inherits Rectangle
 */
Rectangle {
    id: menuItem

    /* ========================================================================
     * PROPERTI PUBLIK
     * ======================================================================== */

    /** @property keyText @brief Teks badge shortcut keyboard (contoh: "[1]", "[ESC]"). */
    property string keyText: "[1]"

    /** @property iconSource @brief Path ke ikon SVG (format qrc:/), dirender pada 18x18px. */
    property string iconSource: ""

    /** @property labelText @brief Label teks utama menu item. */
    property string labelText: "Menu Item"

    /** @property accentType @brief Varian warna aksen: "default", "green", "yellow", "red". */
    property string accentType: "default"  // "default", "green", "yellow", "red"

    /** @property locked @brief Apakah menu item dinonaktifkan/dikunci. */
    property bool locked: false

    /** @property statusText @brief Teks badge status (contoh: "[PASSED]", "[LOCKED]"). */
    property string statusText: ""  // contoh: "[PASSED]", "[LOCKED]", "[AVAILABLE]"

    /** @property statusType @brief Tipe badge status: "passed", "locked", "certified". */
    property string statusType: ""  // "passed", "locked", "certified"

    /** @property reqText @brief Teks deskripsi persyaratan (contoh: "Min: 40 WPM, 80% Acc"). */
    property string reqText: ""     // contoh: "Min: 40 WPM, 80% Acc"

    /** @property busy @brief Apakah item dalam state proses (ikon berputar). */
    property bool busy: false

    /** @signal clicked @brief Dipancarkan saat menu item diklik (hanya jika tidak dikunci). */
    signal clicked

    /* ========================================================================
     * PROPERTI COMPUTED
     * ======================================================================== */

    /**
     * @property hoverColor
     * @brief Warna aksen computed berdasarkan accentType dan state locked.
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

    // Aksen bar kiri
    Rectangle {
        width: 3
        height: parent.height
        color: menuItem.isHovered ? menuItem.hoverColor : Theme.borderSecondary
    }

    // Animasi hover
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

        // Badge tombol
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

        // Ikon dan label
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

        // Badge status dan info persyaratan (untuk level campaign)
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
