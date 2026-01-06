import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "qml/components"
import "qml/pages"

ApplicationWindow {
    id: mainWindow

    width: 1024
    height: 768
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: "Rapid Texter"
    color: "#0d1117"

    // Font loader
    FontLoader {
        id: jetBrainsMono
        source: "assets/font/JetBrainsMono.ttf"
    }

    // Set theme font after font is loaded
    Component.onCompleted: {
        Theme.fontFamily = jetBrainsMono.name;
    }

    // Application state
    property string currentLanguage: "-"
    property string currentTime: "-"
    property string currentMode: "-"
    property string currentDifficulty: "easy"  // Default difficulty for TextProvider
    property int currentTargetWPM: 60          // Target WPM for manual mode
    property string originalLanguage: ""        // Stores original language for Programmer Mode restoration
    property bool sfxEnabled: GameBackend.sfxEnabled
    property bool isInGameplay: false            // Track if in gameplay for shortcut control
    property bool skipNavigationSound: false      // Flag to skip sound during multi-pop transition

    property int currentDuration: {
        if (currentTime === "∞")
            return -1;
        if (currentTime === "-" || currentTime === "Custom")
            return GameBackend.defaultDuration;
        return parseInt(currentTime) || GameBackend.defaultDuration;
    }

    // Reset status bar to default values (Time persists)
    function resetStatusBar() {
        currentLanguage = "-";
        currentMode = "-";
    }

    // Campaign progress
    property bool easyPassed: true
    property bool mediumPassed: false
    property bool hardPassed: false
    property bool programmerCertified: false

    // Last game results (for results page)
    property real lastWpm: 0
    property real lastAccuracy: 0
    property int lastErrors: 0
    property real lastTimeElapsed: 0
    property bool lastLevelPassed: false

    // Global SFX toggle shortcut (disabled during gameplay to avoid conflict)
    Shortcut {
        sequence: "S"
        enabled: !mainWindow.isInGameplay
        onActivated: {
            GameBackend.toggleSfx();
            if (GameBackend.sfxEnabled) {
                GameBackend.playErrorSound();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ====================================================================
        // STATUS BAR
        // ====================================================================
        StatusBar {
            Layout.fillWidth: true
            currentLanguage: mainWindow.currentLanguage
            currentTime: mainWindow.currentTime
            currentMode: mainWindow.currentMode
            sfxEnabled: GameBackend.sfxEnabled
            showShortcutHint: !mainWindow.isInGameplay
            onSfxToggled: {
                GameBackend.toggleSfx();
                // Play sound to confirm SFX is now ON
                if (GameBackend.sfxEnabled) {
                    GameBackend.playErrorSound();
                }
            }
        }

        // ====================================================================
        // MAIN CONTENT
        // ====================================================================
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            initialItem: mainMenuComponent

            onCurrentItemChanged: {
                // Play navigation sound when page changes
                // Skip sound if in multi-pop transition (e.g., returning from results)
                if (!mainWindow.skipNavigationSound) {
                    GameBackend.playCorrectSound();
                }
                mainWindow.skipNavigationSound = false;  // Reset flag

                // Reset status bar when returning to main menu
                if (stackView.depth === 1) {
                    mainWindow.resetStatusBar();
                }
            }

            // Smooth page transitions for polished UI/UX
            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
                    easing.type: Easing.InQuart
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutQuart
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
                    easing.type: Easing.InQuart
                }
            }
        }
    }

    // ========================================================================
    // MAIN MENU PAGE
    // ========================================================================
    Component {
        id: mainMenuComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            StackView.onActivating: forceActiveFocus()
            Component.onCompleted: forceActiveFocus()

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    stackView.push(languageMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    stackView.push(historyComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Q:
                    Qt.quit();
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: mainCol.implicitHeight

                ColumnLayout {
                    id: mainCol
                    anchors.fill: parent
                    spacing: 0

                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: Theme.spacingLogo
                        spacing: Theme.spacingM

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "RAPID"
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLogo
                            font.bold: true
                            font.letterSpacing: -3
                        }

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

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 30
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/play.svg"
                            labelText: "Start Game"
                            accentType: "green"
                            onClicked: stackView.push(languageMenuComponent)
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                            labelText: "Show History"
                            accentType: "yellow"
                            onClicked: stackView.push(historyComponent)
                        }
                        MenuItemC {
                            keyText: "(Q)"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                            labelText: "Quit"
                            accentType: "red"
                            onClicked: Qt.quit()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 30
                        text: "Press keys or click to navigate"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSM
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    // ========================================================================
    // LANGUAGE MENU PAGE
    // ========================================================================
    Component {
        id: languageMenuComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            StackView.onActivating: forceActiveFocus()

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    mainWindow.currentLanguage = "ID";
                    stackView.push(durationMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    mainWindow.currentLanguage = "EN";
                    stackView.push(durationMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    mainWindow.currentLanguage = "-";
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: langCol.implicitHeight

                ColumnLayout {
                    id: langCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "SELECT LANGUAGE"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                            labelText: "Indonesia (ID)"
                            onClicked: {
                                mainWindow.currentLanguage = "ID";
                                stackView.push(durationMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/globe.svg"
                            labelText: "English (EN)"
                            onClicked: {
                                mainWindow.currentLanguage = "EN";
                                stackView.push(durationMenuComponent);
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: {
                                mainWindow.currentLanguage = "-";
                                stackView.pop();
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // DURATION MENU PAGE
    // ========================================================================
    Component {
        id: durationMenuComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            StackView.onActivating: forceActiveFocus()

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    mainWindow.currentTime = "15s";
                    GameBackend.defaultDuration = 15;
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    mainWindow.currentTime = "30s";
                    GameBackend.defaultDuration = 30;
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_3:
                    mainWindow.currentTime = "60s";
                    GameBackend.defaultDuration = 60;
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_4:
                    mainWindow.currentTime = "Custom";
                    stackView.push(customDurationComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_5:
                    mainWindow.currentTime = "∞";
                    GameBackend.defaultDuration = -1;
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    if (mainWindow.currentTime === "" || mainWindow.currentTime === "-") {
                        mainWindow.currentTime = GameBackend.defaultDuration === -1 ? "∞" : GameBackend.defaultDuration + "s";
                    }
                    // Else use whatever was last set
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: durCol.implicitHeight

                ColumnLayout {
                    id: durCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "SELECT DURATION"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            labelText: "15 Seconds"
                            onClicked: {
                                mainWindow.currentTime = "15s";
                                GameBackend.defaultDuration = 15;
                                stackView.push(modeMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            labelText: "30 Seconds"
                            onClicked: {
                                mainWindow.currentTime = "30s";
                                GameBackend.defaultDuration = 30;
                                stackView.push(modeMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[3]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            labelText: "60 Seconds"
                            onClicked: {
                                mainWindow.currentTime = "60s";
                                GameBackend.defaultDuration = 60;
                                stackView.push(modeMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[4]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/sliders.svg"
                            labelText: "Custom"
                            accentType: "yellow"
                            onClicked: {
                                mainWindow.currentTime = "Custom";
                                stackView.push(customDurationComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[5]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/infinity.svg"
                            labelText: "Infinity (No Limit)"
                            onClicked: {
                                mainWindow.currentTime = "∞";
                                GameBackend.defaultDuration = -1;
                                stackView.push(modeMenuComponent);
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 15
                        text: "[Enter] Use Default (" + (GameBackend.defaultDuration === -1 ? "∞" : GameBackend.defaultDuration + "s") + ")"
                        color: Theme.accentGreen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: stackView.pop()
                        }
                    }
                }
            }
        }
    }

    // Custom Duration Input Component
    Component {
        id: customDurationComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            // Force focus on input AFTER page transition completes
            StackView.onActivated: {
                customDurInput.forceActiveFocus();
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var seconds = parseInt(customDurInput.text) || 30;
                    mainWindow.currentTime = seconds + "s";
                    GameBackend.defaultDuration = seconds;
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    stackView.pop();
                    event.accepted = true;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: customDurCol.implicitHeight

                ColumnLayout {
                    id: customDurCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "CUSTOM DURATION"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM

                        Text {
                            text: "Enter Duration (seconds):"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeL
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: Theme.bgPrimary
                            border.width: 1
                            border.color: customDurInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary

                            TextInput {
                                id: customDurInput
                                anchors.fill: parent
                                anchors.margins: Theme.paddingL
                                text: ""
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXXL
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator {
                                    bottom: 5
                                    top: 600
                                }
                                selectByMouse: true
                                Component.onCompleted: forceActiveFocus()

                                // Placeholder text
                                Text {
                                    anchors.centerIn: parent
                                    text: "Enter seconds..."
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXXL
                                    visible: customDurInput.text.length === 0 && !customDurInput.activeFocus
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.paddingL
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SEC"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                            }
                        }

                        Text {
                            text: "Valid range: 5 - 600 seconds"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: stackView.pop()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                            labelText: "Confirm (ENTER)"
                            variant: "primary"
                            onClicked: {
                                var seconds = parseInt(customDurInput.text) || 30;
                                mainWindow.currentTime = seconds + "s";
                                GameBackend.defaultDuration = seconds;
                                stackView.push(modeMenuComponent);
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // MODE MENU PAGE
    // ========================================================================
    Component {
        id: modeMenuComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            StackView.onActivating: forceActiveFocus()

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    mainWindow.currentMode = "Manual";
                    stackView.push(manualSetupComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    mainWindow.currentMode = "Campaign";
                    stackView.push(campaignMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    mainWindow.currentMode = "-";
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: modeCol.implicitHeight

                ColumnLayout {
                    id: modeCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "SELECT MODE"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/hand.svg"
                            labelText: "Manual Mode"
                            onClicked: {
                                mainWindow.currentMode = "Manual";
                                stackView.push(manualSetupComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trophy.svg"
                            labelText: "Campaign Mode"
                            onClicked: {
                                mainWindow.currentMode = "Campaign";
                                stackView.push(campaignMenuComponent);
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: {
                                mainWindow.currentMode = "-";
                                stackView.pop();
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // MANUAL SETUP PAGE
    // ========================================================================
    Component {
        id: manualSetupComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true
            property int targetWpm: 60

            // Force focus on input AFTER page transition completes
            StackView.onActivated: {
                wpmInput.forceActiveFocus();
            }

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    // Save WPM and difficulty to mainWindow before starting game
                    mainWindow.currentTargetWPM = parseInt(wpmInput.text) || 60;
                    mainWindow.currentDifficulty = "medium";  // Manual mode uses medium difficulty
                    stackView.push(gameplayComponent);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    stackView.pop();
                    event.accepted = true;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: setupCol.implicitHeight

                ColumnLayout {
                    id: setupCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "MANUAL SETUP"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM

                        Text {
                            text: "Enter Target WPM:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeL
                        }

                        Rectangle {
                            width: parent.width
                            height: 50
                            color: Theme.bgPrimary
                            border.width: 1
                            border.color: wpmInput.activeFocus ? Theme.accentBlue : Theme.borderSecondary

                            TextInput {
                                id: wpmInput
                                anchors.fill: parent
                                anchors.margins: Theme.paddingL
                                text: ""
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXXL
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                validator: IntValidator {
                                    bottom: 1
                                    top: 200
                                }
                                selectByMouse: true
                                Component.onCompleted: forceActiveFocus()

                                // Placeholder text
                                Text {
                                    anchors.centerIn: parent
                                    text: "Enter WPM..."
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXXL
                                    visible: wpmInput.text.length === 0 && !wpmInput.activeFocus
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.paddingL
                                anchors.verticalCenter: parent.verticalCenter
                                text: "WPM"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                            }
                        }

                        Text {
                            text: "Valid range: 1 - 200 WPM"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSM
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: stackView.pop()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                            labelText: "Confirm (ENTER)"
                            variant: "primary"
                            onClicked: {
                                // Save WPM and difficulty to mainWindow before starting game
                                mainWindow.currentTargetWPM = parseInt(wpmInput.text) || 60;
                                mainWindow.currentDifficulty = "medium";
                                stackView.push(gameplayComponent);
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // GAMEPLAY PAGE
    // ========================================================================
    Component {
        id: gameplayComponent

        GameplayPage {
            id: gameplayPageInstance

            // Set isInGameplay when entering gameplay
            StackView.onActivating: mainWindow.isInGameplay = true
            StackView.onDeactivating: mainWindow.isInGameplay = false

            // Get text from word bank using GameBackend
            // Convert language and difficulty to lowercase for backend
            // Initial text set via Component.onCompleted
            Component.onCompleted: {
                targetText = GameBackend.getRandomText(mainWindow.currentLanguage.toLowerCase(), mainWindow.currentDifficulty.toLowerCase(), 30  // Word count
                );
            }

            timeLimit: mainWindow.currentDuration
            timeRemaining: mainWindow.currentDuration

            onGameCompleted: function (wpm, accuracy, errors, timeElapsed) {
                // Store results for results page
                mainWindow.lastWpm = wpm;
                mainWindow.lastAccuracy = accuracy;
                mainWindow.lastErrors = errors;
                mainWindow.lastTimeElapsed = timeElapsed;

                // For Programmer Mode, use originalLanguage for progress/history
                var langForProgress = mainWindow.currentLanguage;
                if (mainWindow.currentDifficulty === "programmer" && mainWindow.originalLanguage !== "") {
                    langForProgress = mainWindow.originalLanguage;
                }

                // Save to history via GameBackend
                GameBackend.saveGameResult(wpm, accuracy, errors, mainWindow.currentTargetWPM, mainWindow.currentDifficulty, langForProgress, mainWindow.currentMode);

                // For Campaign mode, check if user passed and unlock next level
                if (mainWindow.currentMode === "Campaign") {
                    var passed = GameBackend.completeLevel(langForProgress, mainWindow.currentDifficulty, wpm, accuracy);
                    mainWindow.lastLevelPassed = passed;
                } else {
                    // For manual mode, just check if target WPM was met
                    mainWindow.lastLevelPassed = (wpm >= mainWindow.currentTargetWPM);
                }

                // Restore language after Programmer Mode
                if (mainWindow.currentDifficulty === "programmer" && mainWindow.originalLanguage !== "") {
                    mainWindow.currentLanguage = mainWindow.originalLanguage;
                    mainWindow.originalLanguage = "";
                }

                stackView.push(resultsComponent);
            }

            onResetClicked: {
                // CRITICAL FIX: Fetch NEW random text on reset!
                // This ensures pressing Tab generates different words
                gameplayPageInstance.targetText = GameBackend.getRandomText(mainWindow.currentLanguage.toLowerCase(), mainWindow.currentDifficulty.toLowerCase(), 30  // Word count
                );
            }

            onExitClicked: {
                // Restore language if exiting from Programmer Mode
                if (mainWindow.currentDifficulty === "programmer" && mainWindow.originalLanguage !== "") {
                    mainWindow.currentLanguage = mainWindow.originalLanguage;
                    mainWindow.originalLanguage = "";
                }
                stackView.pop();
            }
        }
    }

    // ========================================================================
    // CAMPAIGN MENU PAGE
    // ========================================================================
    Component {
        id: campaignMenuComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            // Refresh trigger - increment to force UI update
            property int refreshTrigger: 0

            // Reload level states when returning to this page
            StackView.onActivating: {
                refreshTrigger++;
            }

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    mainWindow.currentDifficulty = "easy";
                    mainWindow.currentTargetWPM = 40;
                    stackView.push(gameplayComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    if (GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium")) {
                        mainWindow.currentDifficulty = "medium";
                        mainWindow.currentTargetWPM = 60;
                        stackView.push(gameplayComponent);
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_3:
                    if (GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard")) {
                        mainWindow.currentDifficulty = "hard";
                        mainWindow.currentTargetWPM = 70;
                        stackView.push(gameplayComponent);
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_4:
                    // Programmer Mode: save original language and switch to prog
                    mainWindow.originalLanguage = mainWindow.currentLanguage;
                    mainWindow.currentLanguage = "prog";
                    mainWindow.currentDifficulty = "programmer";
                    mainWindow.currentTargetWPM = 50;
                    stackView.push(gameplayComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_C:
                    stackView.push(creditsComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_R:
                    stackView.push(resetProgressComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: campCol.implicitHeight

                ColumnLayout {
                    id: campCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "CAMPAIGN DIFFICULTY"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Congratulations banner for Hard completion
                    Rectangle {
                        id: congratsBanner
                        Layout.fillWidth: true
                        Layout.bottomMargin: 20
                        Layout.preferredHeight: 70
                        visible: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "hard"))

                        // Simple background matching blueprint design
                        color: Qt.rgba(0.247, 0.725, 0.314, 0.08)  // rgba(63, 185, 80, 0.08)
                        border.width: 1
                        border.color: Theme.accentGreen

                        // Left accent border (3px)
                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.accentGreen
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 12

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Text {
                                    text: "CONGRATULATIONS!"
                                    color: Theme.accentGreen
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeDisplayM  // Increased size
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                }

                                Row {
                                    spacing: Theme.spacingM
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    // Trophy icon aligned with subtitle
                                    Item {
                                        width: 20
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            id: trophyIcon
                                            source: "qrc:/qt/qml/rapid_texter/assets/icons/trophy.svg"
                                            anchors.fill: parent
                                            visible: false
                                        }
                                        ColorOverlay {
                                            anchors.fill: trophyIcon
                                            source: trophyIcon
                                            color: Theme.accentGreen
                                        }
                                    }

                                    Text {
                                        text: "You have completed all levels!"
                                        color: Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/leaf.svg"
                            labelText: "Easy"
                            accentType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "easy")) ? "green" : "default"
                            statusText: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "easy")) ? "[PASSED]" : ""
                            statusType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "easy")) ? "passed" : ""
                            reqText: "Min: 40 WPM, 80% Acc"
                            onClicked: {
                                mainWindow.currentDifficulty = "easy";
                                mainWindow.currentTargetWPM = 40;
                                stackView.push(gameplayComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trend-up.svg"
                            labelText: "Medium"
                            locked: (refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium"))
                            accentType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "medium")) ? "green" : "default"
                            statusText: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "medium")) ? "[PASSED]" : ((refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium")) ? "[LOCKED]" : "")
                            statusType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "medium")) ? "passed" : ((refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium")) ? "locked" : "")
                            reqText: (refreshTrigger, GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium")) ? "Min: 60 WPM, 90% Acc" : "Need: Easy passed"
                            onClicked: {
                                if (GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "medium")) {
                                    mainWindow.currentDifficulty = "medium";
                                    mainWindow.currentTargetWPM = 60;
                                    stackView.push(gameplayComponent);
                                }
                            }
                        }
                        MenuItemC {
                            keyText: "[3]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/fire.svg"
                            labelText: "Hard"
                            locked: (refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard"))
                            accentType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "hard")) ? "green" : "default"
                            statusText: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "hard")) ? "[PASSED]" : ((refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard")) ? "[LOCKED]" : "")
                            statusType: (refreshTrigger, GameBackend.isLevelCompleted(mainWindow.currentLanguage, "hard")) ? "passed" : ((refreshTrigger, !GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard")) ? "locked" : "")
                            reqText: (refreshTrigger, GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard")) ? "Min: 70 WPM, 90% Acc" : "Need: Medium passed"
                            onClicked: {
                                if (GameBackend.isLevelUnlocked(mainWindow.currentLanguage, "hard")) {
                                    mainWindow.currentDifficulty = "hard";
                                    mainWindow.currentTargetWPM = 70;
                                    stackView.push(gameplayComponent);
                                }
                            }
                        }
                        MenuItemC {
                            keyText: "[4]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/monitor.svg"
                            labelText: "Programmer Mode"
                            statusText: GameBackend.isLevelCompleted(mainWindow.currentLanguage, "programmer") ? "[CERTIFIED]" : "[AVAILABLE]"
                            statusType: "certified"
                            reqText: "50 WPM, 90% for Cert"
                            onClicked: {
                                // Programmer Mode: save original language and switch to prog
                                mainWindow.originalLanguage = mainWindow.currentLanguage;
                                mainWindow.currentLanguage = "prog";
                                mainWindow.currentDifficulty = "programmer";
                                mainWindow.currentTargetWPM = 50;
                                stackView.push(gameplayComponent);
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Back (ESC)"
                            onClicked: stackView.pop()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/users.svg"
                            labelText: "Credits (C)"
                            onClicked: stackView.push(creditsComponent)
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            labelText: "Reset (R)"
                            variant: "danger"
                            onClicked: stackView.push(resetProgressComponent)
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // RESULTS PAGE
    // ========================================================================
    Component {
        id: resultsComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            StackView.onActivating: forceActiveFocus()

            // Function to return to setup page (skip gameplay completely)
            function returnToSetup() {
                // Use popToIndex to directly navigate to setup page
                // Stack: [...] -> Setup (depth-3) -> Gameplay (depth-2) -> Results (depth-1)
                // popToIndex pops down TO (but not including) the specified index
                // So popToIndex(depth-3) leaves us at the setup page
                stackView.popToIndex(stackView.depth - 3);
            }

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    returnToSetup();
                    event.accepted = true;
                    break;
                case Qt.Key_H:
                    stackView.push(historyComponent);
                    event.accepted = true;
                    break;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: resCol.implicitHeight

                ColumnLayout {
                    id: resCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "RESULTS"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // WPM Display
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        color: mainWindow.lastLevelPassed ? Theme.successBg : Theme.dangerBg
                        border.width: 1
                        border.color: Theme.borderPrimary

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: mainWindow.lastLevelPassed ? Theme.accentGreen : Theme.accentRed
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(mainWindow.lastWpm) + " WPM"
                            color: mainWindow.lastLevelPassed ? Theme.accentGreen : Theme.accentRed
                            font.family: Theme.fontFamily
                            font.pixelSize: 48
                            font.bold: true
                        }
                    }

                    // Stats row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.spacingL
                        spacing: Theme.spacingL

                        Repeater {
                            model: [
                                {
                                    label: "ACCURACY",
                                    value: mainWindow.lastAccuracy.toFixed(1) + "%",
                                    color: Theme.textPrimary
                                },
                                {
                                    label: "TIME",
                                    value: mainWindow.lastTimeElapsed.toFixed(1) + "s",
                                    color: Theme.textPrimary
                                },
                                {
                                    label: "ERRORS",
                                    value: mainWindow.lastErrors.toString(),
                                    color: Theme.accentRed
                                }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                color: "transparent"
                                border.width: 1
                                border.color: Theme.borderPrimary

                                Rectangle {
                                    width: 3
                                    height: parent.height
                                    color: Theme.borderSecondary
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

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
                                        font.pixelSize: 32
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // Pass/Fail message
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        Layout.preferredHeight: passCol.implicitHeight + 30
                        color: mainWindow.lastLevelPassed ? Theme.successBg : Theme.dangerBg
                        border.width: 1
                        border.color: mainWindow.lastLevelPassed ? Theme.accentGreen : Theme.accentRed

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: mainWindow.lastLevelPassed ? Theme.accentGreen : Theme.accentRed
                        }

                        Column {
                            id: passCol
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (mainWindow.currentMode === "Campaign") {
                                        if (mainWindow.lastLevelPassed) {
                                            if (mainWindow.currentDifficulty === "hard") {
                                                return "HARD COMPLETED!";
                                            } else if (mainWindow.currentDifficulty === "programmer") {
                                                return "PROGRAMMER MODE COMPLETED!";
                                            } else {
                                                return "✓ LEVEL PASSED!";
                                            }
                                        } else {
                                            return "✗ LEVEL FAILED";
                                        }
                                    } else {
                                        return mainWindow.lastLevelPassed ? "✓ TARGET REACHED!" : "✗ TARGET NOT REACHED";
                                    }
                                }
                                color: mainWindow.lastLevelPassed ? Theme.accentGreen : Theme.accentRed
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXXL
                                font.bold: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (mainWindow.currentMode === "Campaign") {
                                        if (mainWindow.lastLevelPassed) {
                                            // Success messages based on difficulty
                                            if (mainWindow.currentDifficulty === "easy") {
                                                return "Medium level is now unlocked! Ready for a bigger challenge?";
                                            } else if (mainWindow.currentDifficulty === "medium") {
                                                return "Hard level is now unlocked! You're almost at the top!";
                                            } else if (mainWindow.currentDifficulty === "hard") {
                                                return "Congratulations! You've mastered the Campaign mode!";
                                            } else if (mainWindow.currentDifficulty === "programmer") {
                                                return "Amazing! You've conquered the Programmer Mode challenge!";
                                            }
                                            return "Great job! You've achieved the requirements.";
                                        } else {
                                            // Failure messages based on difficulty
                                            if (mainWindow.currentDifficulty === "easy") {
                                                return "You need 40 WPM with 80% accuracy to unlock Medium level.";
                                            } else if (mainWindow.currentDifficulty === "medium") {
                                                return "You need 60 WPM with 90% accuracy to unlock Hard level.";
                                            } else if (mainWindow.currentDifficulty === "hard") {
                                                return "You need 70 WPM with 95% accuracy to complete Hard level.";
                                            } else if (mainWindow.currentDifficulty === "programmer") {
                                                return "You need 50 WPM with 85% accuracy to complete Programmer Mode.";
                                            }
                                            return "Keep practicing to unlock the next level.";
                                        }
                                    } else {
                                        return mainWindow.lastLevelPassed ? "Great job! You've reached your target WPM." : "Keep practicing to reach your target WPM.";
                                    }
                                }
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                            labelText: "Continue (ENTER)"
                            variant: "primary"
                            onClicked: returnToSetup()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                            labelText: "History (H)"
                            variant: "yellow"
                            onClicked: stackView.push(historyComponent)
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // HISTORY PAGE
    // ========================================================================
    Component {
        id: historyComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            // History data from backend
            property var historyData: []
            property int currentPage: 1
            property int totalPages: 1
            property int totalEntries: 0

            // Sort settings (persisted via GameBackend)
            property string sortBy: GameBackend.historySortBy
            property bool sortAscending: GameBackend.historySortAscending

            // Mode filter (session-only, not persisted)
            property string modeFilter: "All"
            property bool showModeDropdown: false

            // Load history data from backend with sorting and filtering
            function loadHistory() {
                historyData = GameBackend.getHistoryPageSorted(currentPage, 10, sortBy, sortAscending, modeFilter);
                totalPages = GameBackend.getHistoryTotalPages(10);
                totalEntries = GameBackend.getHistoryTotalEntries();
            }

            // Toggle sort on column click
            function toggleSort(column) {
                if (sortBy === column) {
                    // Same column, toggle direction
                    sortAscending = !sortAscending;
                    GameBackend.historySortAscending = sortAscending;
                } else {
                    // New column, set default direction
                    sortBy = column;
                    GameBackend.historySortBy = column;
                    // Default: date = descending (newest first), wpm = descending (highest first)
                    sortAscending = false;
                    GameBackend.historySortAscending = false;
                }
                currentPage = 1; // Reset to first page
                loadHistory();
            }

            // Set mode filter
            function setModeFilter(mode) {
                modeFilter = mode;
                showModeDropdown = false;
                currentPage = 1; // Reset to first page
                loadHistory();
            }

            Component.onCompleted: {
                loadHistory();
            }

            // Reload data when returning to this page (e.g., after clearing history)
            StackView.onActivating: {
                forceActiveFocus();
                loadHistory();
            }

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Escape:
                    stackView.pop();
                    event.accepted = true;
                    break;
                case Qt.Key_C:
                    stackView.push(resetHistoryComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_1:  // Previous page (per original TUI)
                    if (currentPage > 1) {
                        currentPage--;
                        loadHistory();
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_2:  // Next page (per original TUI)
                    if (currentPage < totalPages) {
                        currentPage++;
                        loadHistory();
                    }
                    event.accepted = true;
                    break;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.paddingHuge
                spacing: 0

                // Header section
                Column {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    spacing: Theme.spacingM

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM
                        Item {
                            width: 28
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: historyTitleIcon
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                                anchors.fill: parent
                                sourceSize: Qt.size(28, 28)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: historyTitleIcon
                                source: historyTitleIcon
                                color: Theme.accentBlue
                            }
                        }
                        Text {
                            text: "GAME HISTORY"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeDisplay
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Page " + currentPage + " of " + Math.max(1, totalPages)
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: totalEntries + " total entries"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeS
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.borderPrimary

                    Column {
                        anchors.fill: parent

                        Rectangle {
                            width: parent.width
                            height: 40
                            color: Theme.bgSecondary

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.borderPrimary
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.paddingHuge
                                anchors.rightMargin: Theme.paddingHuge
                                spacing: 0

                                // WPM Header - Sortable
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 60
                                    height: parent.height

                                    property bool isHovered: wpmHeaderMouse.containsMouse

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "WPM"
                                            color: parent.parent.isHovered ? Theme.accentBlue : (sortBy === "wpm" ? Theme.accentBlue : Theme.textSecondary)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeS
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Sort indicator
                                        Item {
                                            width: 12
                                            height: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: sortBy === "wpm"

                                            Image {
                                                id: wpmSortIcon
                                                source: sortAscending ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                                                anchors.fill: parent
                                                sourceSize: Qt.size(12, 12)
                                                visible: false
                                            }
                                            ColorOverlay {
                                                anchors.fill: wpmSortIcon
                                                source: wpmSortIcon
                                                color: Theme.accentBlue
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: wpmHeaderMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: toggleSort("wpm")
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 80
                                    text: "ACCURACY"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 60
                                    text: "TARGET"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 60
                                    text: "ERRORS"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 80
                                    text: "DIFFICULTY"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 50
                                    text: "LANG"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                // MODE Header - Filterable
                                Item {
                                    id: modeHeaderItem
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 80
                                    height: parent.height

                                    property bool isHovered: modeHeaderMouse.containsMouse

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: modeFilter === "All" ? "MODE" : modeFilter.toUpperCase()
                                            color: modeHeaderItem.isHovered ? Theme.accentBlue : (modeFilter !== "All" ? Theme.accentBlue : Theme.textSecondary)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeS
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Dropdown indicator
                                        Item {
                                            width: 12
                                            height: 12
                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                id: modeDropdownIcon
                                                source: showModeDropdown ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                                                anchors.fill: parent
                                                sourceSize: Qt.size(12, 12)
                                                visible: false
                                            }
                                            ColorOverlay {
                                                anchors.fill: modeDropdownIcon
                                                source: modeDropdownIcon
                                                color: modeHeaderItem.isHovered ? Theme.accentBlue : (modeFilter !== "All" ? Theme.accentBlue : Theme.textSecondary)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: modeHeaderMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: showModeDropdown = !showModeDropdown
                                    }
                                }
                                // DATE/TIME Header - Sortable
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 130
                                    height: parent.height

                                    property bool isHovered: dateHeaderMouse.containsMouse

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: "DATE/TIME"
                                            color: parent.parent.isHovered ? Theme.accentBlue : (sortBy === "date" ? Theme.accentBlue : Theme.textSecondary)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeS
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Sort indicator
                                        Item {
                                            width: 12
                                            height: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: sortBy === "date"

                                            Image {
                                                id: dateSortIcon
                                                source: sortAscending ? "qrc:/qt/qml/rapid_texter/assets/icons/chevron-up.svg" : "qrc:/qt/qml/rapid_texter/assets/icons/chevron-down.svg"
                                                anchors.fill: parent
                                                sourceSize: Qt.size(12, 12)
                                                visible: false
                                            }
                                            ColorOverlay {
                                                anchors.fill: dateSortIcon
                                                source: dateSortIcon
                                                color: Theme.accentBlue
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: dateHeaderMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: toggleSort("date")
                                    }
                                }
                            }
                        }

                        ListView {
                            id: historyListView
                            width: parent.width
                            height: parent.height - 40
                            clip: true
                            model: historyData

                            // Empty state when no history
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                visible: historyData.length === 0

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingL

                                    Item {
                                        width: 48
                                        height: 48
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Image {
                                            id: emptyHistIcon
                                            source: "qrc:/qt/qml/rapid_texter/assets/icons/history.svg"
                                            anchors.fill: parent
                                            sourceSize: Qt.size(48, 48)
                                            visible: false
                                        }
                                        ColorOverlay {
                                            anchors.fill: emptyHistIcon
                                            source: emptyHistIcon
                                            color: Theme.textMuted
                                            opacity: 0.5
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "No game history yet"
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeL
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Play some games to see your results here!"
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        opacity: 0.7
                                    }
                                }
                            }

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 40
                                color: histMouse.containsMouse ? Theme.bgSecondary : "transparent"

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: Theme.borderPrimary
                                }
                                Rectangle {
                                    width: 2
                                    height: parent.height
                                    color: modelData.wpm >= modelData.targetWPM ? Theme.accentGreen : Theme.accentRed
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.paddingHuge
                                    anchors.rightMargin: Theme.paddingHuge
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 60
                                        text: modelData.wpm.toFixed(1)
                                        color: modelData.wpm >= modelData.targetWPM ? Theme.accentGreen : Theme.accentRed
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 80
                                        text: modelData.accuracy.toFixed(1) + "%"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 60
                                        text: modelData.targetWPM
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 60
                                        text: modelData.errors
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 80
                                        text: modelData.difficulty
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 50
                                        text: modelData.language
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 80
                                        text: modelData.mode
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 130
                                        text: modelData.timestamp
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeM
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    id: histMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }

                // Pagination navigation
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.spacingL
                    spacing: Theme.spacingM
                    visible: totalPages > 1

                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                        labelText: "Previous [1]"
                        enabled: currentPage > 1
                        opacity: enabled ? 1.0 : 0.4
                        onClicked: {
                            if (currentPage > 1) {
                                currentPage--;
                                loadHistory();
                            }
                        }
                    }
                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-right.svg"
                        labelText: "Next [2]"
                        enabled: currentPage < totalPages
                        opacity: enabled ? 1.0 : 0.4
                        onClicked: {
                            if (currentPage < totalPages) {
                                currentPage++;
                                loadHistory();
                            }
                        }
                    }
                }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    spacing: Theme.spacingM
                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                        labelText: "Back (ESC)"
                        onClicked: stackView.pop()
                    }
                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                        labelText: "Clear History (C)"
                        variant: "danger"
                        onClicked: stackView.push(resetHistoryComponent)
                    }
                }
            }

            // Background overlay to close dropdown when clicking outside
            MouseArea {
                id: dropdownBackgroundOverlay
                anchors.fill: parent
                visible: showModeDropdown
                z: 9998
                onClicked: showModeDropdown = false
            }

            // Mode Filter Dropdown Overlay - placed at Rectangle level for proper z-ordering
            Rectangle {
                id: modeDropdownMenu
                visible: dropdownOpacity > 0
                property real dropdownOpacity: showModeDropdown ? 1 : 0
                property real dropdownScale: showModeDropdown ? 1 : 0.95

                opacity: dropdownOpacity
                scale: dropdownScale
                transformOrigin: Item.Top

                Behavior on dropdownOpacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on dropdownScale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                x: {
                    // Get position relative to the Rectangle
                    var pos = modeHeaderItem.mapToItem(parent, 0, 0);
                    return pos.x + (modeHeaderItem.width - width) / 2;
                }
                y: {
                    var pos = modeHeaderItem.mapToItem(parent, 0, 0);
                    return pos.y + modeHeaderItem.height + 4;
                }
                width: 110
                height: modeDropdownCol2.implicitHeight + Theme.paddingM * 2
                color: Theme.bgSecondary
                border.width: 1
                border.color: Theme.borderPrimary
                radius: 6
                z: 9999

                Column {
                    id: modeDropdownCol2
                    anchors.fill: parent
                    anchors.margins: Theme.paddingM
                    spacing: 2

                    // All option
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: allOpt2Mouse.containsMouse ? Theme.bgHover : "transparent"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "All"
                            color: allOpt2Mouse.containsMouse ? Theme.accentBlue : (modeFilter === "All" ? Theme.accentBlue : Theme.textPrimary)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: modeFilter === "All"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: allOpt2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: setModeFilter("All")
                        }
                    }

                    // Manual option
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: manualOpt2Mouse.containsMouse ? Theme.bgHover : "transparent"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "Manual"
                            color: manualOpt2Mouse.containsMouse ? Theme.accentBlue : (modeFilter === "Manual" ? Theme.accentBlue : Theme.textPrimary)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: modeFilter === "Manual"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: manualOpt2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: setModeFilter("Manual")
                        }
                    }

                    // Campaign option
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: campaignOpt2Mouse.containsMouse ? Theme.bgHover : "transparent"
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "Campaign"
                            color: campaignOpt2Mouse.containsMouse ? Theme.accentBlue : (modeFilter === "Campaign" ? Theme.accentBlue : Theme.textPrimary)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeS
                            font.bold: modeFilter === "Campaign"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        MouseArea {
                            id: campaignOpt2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: setModeFilter("Campaign")
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // CREDITS PAGE
    // ========================================================================
    Component {
        id: creditsComponent

        Rectangle {
            color: Theme.bgPrimary
            focus: true

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Escape) {
                    stackView.pop();
                    event.accepted = true;
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: credCol.implicitHeight

                ColumnLayout {
                    id: credCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "CREDITS"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 20
                        text: "DEVELOPED BY:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeL
                        font.letterSpacing: 1
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.spacingL

                        Repeater {
                            model: ["Alea Farrel", "Hensa Katelu", "Yanuar Adi Candra", "Arif Wibowo P.", "Aria Mahendra U."]
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData
                                color: Theme.accentBlue
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXXL
                                font.bold: true
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                        spacing: Theme.spacingS
                        Item {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                id: heartIconCredit
                                source: "qrc:/qt/qml/rapid_texter/assets/icons/heart.svg"
                                anchors.fill: parent
                                sourceSize: Qt.size(16, 16)
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: heartIconCredit
                                source: heartIconCredit
                                color: Theme.accentGreen
                            }
                        }
                        Text {
                            text: "Thank you for playing!"
                            color: Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeL
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Return (ENTER)"
                            onClicked: stackView.pop()
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // RESET HISTORY PAGE
    // ========================================================================
    Component {
        id: resetHistoryComponent

        Rectangle {
            id: resetHistoryPage
            color: Theme.bgPrimary
            focus: true

            // State machine for loading animation
            property string pageState: "confirm" // "confirm", "processing", "success"

            // Timer for processing delay (500ms like TUI)
            Timer {
                id: rhProcessingTimer
                interval: 500
                repeat: false
                onTriggered: {
                    resetHistoryPage.pageState = "success";
                    rhSuccessTimer.start();
                }
            }

            // Timer for success display (1 second like TUI)
            Timer {
                id: rhSuccessTimer
                interval: 1000
                repeat: false
                onTriggered: {
                    stackView.pop();
                }
            }

            function startProcessing() {
                pageState = "processing";
                GameBackend.clearHistory();
                rhProcessingTimer.start();
            }

            Keys.onPressed: function (event) {
                // Disable keyboard input during processing/success
                if (pageState !== "confirm") {
                    event.accepted = true;
                    return;
                }

                switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    startProcessing();
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            // Confirmation UI (existing)
            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: rhCol.implicitHeight
                visible: resetHistoryPage.pageState === "confirm"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                ColumnLayout {
                    id: rhCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "CLEAR HISTORY"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rhConfirmCol.implicitHeight + 60
                        color: Theme.dangerBg
                        border.width: 1
                        border.color: Theme.accentRed

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.accentRed
                        }

                        Column {
                            id: rhConfirmCol
                            anchors.centerIn: parent
                            spacing: Theme.spacingL

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Are you sure?"
                                color: Theme.accentRed
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "This will permanently delete all your game history."
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeL
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.spacingS
                                Item {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    Image {
                                        id: warningIconHistory
                                        source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                                        anchors.fill: parent
                                        sourceSize: Qt.size(14, 14)
                                        visible: false
                                    }
                                    ColorOverlay {
                                        anchors.fill: warningIconHistory
                                        source: warningIconHistory
                                        color: Theme.accentYellow
                                    }
                                }
                                Text {
                                    text: "This action cannot be undone"
                                    color: Theme.accentYellow
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                }
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Cancel (ESC)"
                            onClicked: stackView.pop()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trash.svg"
                            labelText: "Confirm (ENTER)"
                            variant: "danger"
                            onClicked: resetHistoryPage.startProcessing()
                        }
                    }
                }
            }

            // Processing Overlay
            Item {
                anchors.centerIn: parent
                visible: resetHistoryPage.pageState === "processing"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXL

                    // Spinning loader
                    Item {
                        width: 48
                        height: 48
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: rhLoaderIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }
                        ColorOverlay {
                            id: rhLoaderOverlay
                            anchors.fill: rhLoaderIcon
                            source: rhLoaderIcon
                            color: Theme.accentYellow

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: resetHistoryPage.pageState === "processing"
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Clearing history..."
                        color: Theme.accentYellow
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXL
                        font.bold: true
                    }
                }
            }

            // Success Overlay
            Item {
                anchors.centerIn: parent
                visible: resetHistoryPage.pageState === "success"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXL

                    // Checkmark icon with glow
                    Item {
                        width: 48
                        height: 48
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Glow effect
                        Rectangle {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            radius: 32
                            color: Theme.accentGreen
                            opacity: 0.2

                            SequentialAnimation on scale {
                                running: resetHistoryPage.pageState === "success"
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 1.2
                                    duration: 500
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 500
                                    easing.type: Easing.InQuad
                                }
                            }
                        }

                        Image {
                            id: rhSuccessIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: rhSuccessIcon
                            source: rhSuccessIcon
                            color: Theme.accentGreen
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "History cleared successfully!"
                        color: Theme.accentGreen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXL
                        font.bold: true
                    }
                }
            }
        }
    }

    // ========================================================================
    // RESET PROGRESS PAGE
    // ========================================================================
    Component {
        id: resetProgressComponent

        Rectangle {
            id: resetProgressPage
            color: Theme.bgPrimary
            focus: true

            // State machine for loading animation
            property string pageState: "confirm" // "confirm", "processing", "success"

            // Timer for processing delay (500ms like TUI)
            Timer {
                id: rpProcessingTimer
                interval: 500
                repeat: false
                onTriggered: {
                    resetProgressPage.pageState = "success";
                    rpSuccessTimer.start();
                }
            }

            // Timer for success display (1 second like TUI)
            Timer {
                id: rpSuccessTimer
                interval: 1000
                repeat: false
                onTriggered: {
                    stackView.pop();
                }
            }

            function startProcessing() {
                pageState = "processing";
                GameBackend.resetProgress();
                rpProcessingTimer.start();
            }

            Keys.onPressed: function (event) {
                // Disable keyboard input during processing/success
                if (pageState !== "confirm") {
                    event.accepted = true;
                    return;
                }

                switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    startProcessing();
                    event.accepted = true;
                    break;
                case Qt.Key_Escape:
                    stackView.pop();
                    event.accepted = true;
                    break;
                }
            }

            // Confirmation UI (existing)
            Item {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.paddingHuge * 2, Theme.maxContentWidth)
                height: rpCol.implicitHeight
                visible: resetProgressPage.pageState === "confirm"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                ColumnLayout {
                    id: rpCol
                    anchors.fill: parent
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 30
                        text: "RESET PROGRESS"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rpConfirmCol.implicitHeight + 60
                        color: Theme.dangerBg
                        border.width: 1
                        border.color: Theme.accentRed

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.accentRed
                        }

                        Column {
                            id: rpConfirmCol
                            anchors.centerIn: parent
                            spacing: Theme.spacingL

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Are you sure?"
                                color: Theme.accentRed
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "This will reset all your campaign progress."
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeL
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "All unlocked levels will be locked again."
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeL
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: Theme.spacingS
                                Item {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    Image {
                                        id: warningIconProgress
                                        source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                                        anchors.fill: parent
                                        sourceSize: Qt.size(14, 14)
                                        visible: false
                                    }
                                    ColorOverlay {
                                        anchors.fill: warningIconProgress
                                        source: warningIconProgress
                                        color: Theme.accentYellow
                                    }
                                }
                                Text {
                                    text: "This action cannot be undone"
                                    color: Theme.accentYellow
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSM
                                }
                            }
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        spacing: Theme.spacingM
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/arrow-left.svg"
                            labelText: "Cancel (ESC)"
                            onClicked: stackView.pop()
                        }
                        NavBtn {
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            labelText: "Confirm (ENTER)"
                            variant: "danger"
                            onClicked: resetProgressPage.startProcessing()
                        }
                    }
                }
            }

            // Processing Overlay
            Item {
                anchors.centerIn: parent
                visible: resetProgressPage.pageState === "processing"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXL

                    // Spinning loader
                    Item {
                        width: 48
                        height: 48
                        anchors.horizontalCenter: parent.horizontalCenter

                        Image {
                            id: rpLoaderIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }
                        ColorOverlay {
                            id: rpLoaderOverlay
                            anchors.fill: rpLoaderIcon
                            source: rpLoaderIcon
                            color: Theme.accentYellow

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: resetProgressPage.pageState === "processing"
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Resetting progress..."
                        color: Theme.accentYellow
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXL
                        font.bold: true
                    }
                }
            }

            // Success Overlay
            Item {
                anchors.centerIn: parent
                visible: resetProgressPage.pageState === "success"
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingXL

                    // Checkmark icon with glow
                    Item {
                        width: 48
                        height: 48
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Glow effect
                        Rectangle {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            radius: 32
                            color: Theme.accentGreen
                            opacity: 0.2

                            SequentialAnimation on scale {
                                running: resetProgressPage.pageState === "success"
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 1.2
                                    duration: 500
                                    easing.type: Easing.OutQuad
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 500
                                    easing.type: Easing.InQuad
                                }
                            }
                        }

                        Image {
                            id: rpSuccessIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/check.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(48, 48)
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: rpSuccessIcon
                            source: rpSuccessIcon
                            color: Theme.accentGreen
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Progress reset successfully!"
                        color: Theme.accentGreen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXL
                        font.bold: true
                    }
                }
            }
        }
    }
}
