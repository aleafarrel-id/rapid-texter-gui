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
    property bool sfxEnabled: GameBackend.sfxEnabled

    property int currentDuration: {
        if (currentTime === "∞")
            return -1;
        if (currentTime === "-" || currentTime === "Custom")
            return 30;
        return parseInt(currentTime) || 30;
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
            sfxEnabled: mainWindow.sfxEnabled
            onSfxToggled: mainWindow.sfxEnabled = !mainWindow.sfxEnabled
        }

        // ====================================================================
        // MAIN CONTENT
        // ====================================================================
        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: mainMenuComponent

            onCurrentItemChanged: {
                // Play navigation sound when page changes
                GameBackend.playCorrectSound();

                // Reset status bar when returning to main menu
                if (stackView.depth === 1) {
                    mainWindow.resetStatusBar();
                }
            }

            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 150
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

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
                    mainWindow.currentTime = "15s";
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_2:
                    mainWindow.currentTime = "30s";
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_3:
                    mainWindow.currentTime = "60s";
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
                    stackView.push(modeMenuComponent);
                    event.accepted = true;
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    mainWindow.currentTime = "30s";
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
                                stackView.push(modeMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            labelText: "30 Seconds"
                            onClicked: {
                                mainWindow.currentTime = "30s";
                                stackView.push(modeMenuComponent);
                            }
                        }
                        MenuItemC {
                            keyText: "[3]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/clock.svg"
                            labelText: "60 Seconds"
                            onClicked: {
                                mainWindow.currentTime = "60s";
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
                                mainWindow.currentTime = "Infinity";
                                stackView.push(modeMenuComponent);
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 15
                        text: "[Enter] Use Default (30s)"
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

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var seconds = parseInt(customDurInput.text) || 30;
                    mainWindow.currentTime = seconds + "s";
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
                                text: "45"
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

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    // Save WPM and difficulty to mainWindow before starting game
                    mainWindow.currentTargetWPM = parseInt(wpmInput.text) || 60;
                    mainWindow.currentDifficulty = "easy";  // Manual mode uses easy difficulty
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
                                text: "60"
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
                                mainWindow.currentDifficulty = "easy";
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
            // Get text from word bank using GameBackend
            // Convert language and difficulty to lowercase for backend
            targetText: GameBackend.getRandomText(mainWindow.currentLanguage.toLowerCase(), mainWindow.currentDifficulty.toLowerCase(), 30  // Word count
            )
            timeLimit: mainWindow.currentDuration
            timeRemaining: mainWindow.currentDuration

            onGameCompleted: function (wpm, accuracy, errors, timeElapsed) {
                // Store results for results page
                mainWindow.lastWpm = wpm;
                mainWindow.lastAccuracy = accuracy;
                mainWindow.lastErrors = errors;
                mainWindow.lastTimeElapsed = timeElapsed;

                // Save to history via GameBackend
                GameBackend.saveGameResult(wpm, accuracy, errors, mainWindow.currentTargetWPM, mainWindow.currentDifficulty, mainWindow.currentLanguage, mainWindow.currentMode);
                stackView.push(resultsComponent);
            }

            onResetClicked: {
                // Reset is handled internally by GameplayPage
            }

            onExitClicked: {
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

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_1:
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSM

                        MenuItemC {
                            keyText: "[1]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/leaf.svg"
                            labelText: "Easy"
                            accentType: mainWindow.easyPassed ? "green" : "default"
                            statusText: mainWindow.easyPassed ? "[PASSED]" : ""
                            statusType: mainWindow.easyPassed ? "passed" : ""
                            reqText: "Min: 40 WPM, 80% Acc"
                            onClicked: stackView.push(gameplayComponent)
                        }
                        MenuItemC {
                            keyText: "[2]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/trend-up.svg"
                            labelText: "Medium"
                            locked: !mainWindow.easyPassed
                            accentType: mainWindow.mediumPassed ? "green" : "default"
                            statusText: mainWindow.mediumPassed ? "[PASSED]" : (mainWindow.easyPassed ? "" : "[LOCKED]")
                            statusType: mainWindow.mediumPassed ? "passed" : (mainWindow.easyPassed ? "" : "locked")
                            reqText: mainWindow.easyPassed ? "Min: 60 WPM, 90% Acc" : "Need: Easy passed"
                            onClicked: if (mainWindow.easyPassed)
                                stackView.push(gameplayComponent)
                        }
                        MenuItemC {
                            keyText: "[3]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/fire.svg"
                            labelText: "Hard"
                            locked: !mainWindow.mediumPassed
                            accentType: mainWindow.hardPassed ? "green" : "default"
                            statusText: mainWindow.hardPassed ? "[PASSED]" : (mainWindow.mediumPassed ? "" : "[LOCKED]")
                            statusType: mainWindow.hardPassed ? "passed" : (mainWindow.mediumPassed ? "" : "locked")
                            reqText: mainWindow.mediumPassed ? "Min: 70 WPM, 90% Acc" : "Need: Medium passed"
                            onClicked: if (mainWindow.mediumPassed)
                                stackView.push(gameplayComponent)
                        }
                        MenuItemC {
                            keyText: "[4]"
                            iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/monitor.svg"
                            labelText: "Programmer Mode"
                            statusText: mainWindow.programmerCertified ? "[CERTIFIED]" : "[AVAILABLE]"
                            statusType: "certified"
                            reqText: "50 WPM, 90% for Cert"
                            onClicked: stackView.push(gameplayComponent)
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

            // Function to return to setup page (skip gameplay)
            function returnToSetup() {
                // Pop twice: result -> gameplay -> setup page
                stackView.pop();  // Pop result page
                stackView.pop();  // Pop gameplay page
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
                case Qt.Key_Escape:
                    returnToSetup();
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
                        color: Theme.successBg
                        border.width: 1
                        border.color: Theme.borderPrimary

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.accentGreen
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Math.round(mainWindow.lastWpm) + " WPM"
                            color: Theme.accentGreen
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

                    // Pass message
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        Layout.preferredHeight: passCol.implicitHeight + 30
                        color: Theme.successBg
                        border.width: 1
                        border.color: Theme.accentGreen

                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Theme.accentGreen
                        }

                        Column {
                            id: passCol
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "✓ LEVEL PASSED!"
                                color: Theme.accentGreen
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXXL
                                font.bold: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Great job! You've achieved the requirements."
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeM
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

            // Load history data from backend
            function loadHistory() {
                historyData = GameBackend.getHistoryPage(currentPage, 10);
                totalPages = GameBackend.getHistoryTotalPages(10);
                totalEntries = GameBackend.getHistoryTotalEntries();
            }

            Component.onCompleted: {
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

                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 60
                                    text: "WPM"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
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
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 80
                                    text: "MODE"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 130
                                    text: "DATE/TIME"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeS
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        ListView {
                            width: parent.width
                            height: parent.height - 40
                            clip: true
                            model: historyData

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
            color: Theme.bgPrimary
            focus: true

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    console.log("History cleared");
                    stackView.pop();
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
                height: rhCol.implicitHeight

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
                            onClicked: {
                                console.log("History cleared");
                                stackView.pop();
                            }
                        }
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
            color: Theme.bgPrimary
            focus: true

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    mainWindow.easyPassed = false;
                    mainWindow.mediumPassed = false;
                    mainWindow.hardPassed = false;
                    stackView.pop();
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
                height: rpCol.implicitHeight

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
                            onClicked: {
                                mainWindow.easyPassed = false;
                                mainWindow.mediumPassed = false;
                                mainWindow.hardPassed = false;
                                stackView.pop();
                            }
                        }
                    }
                }
            }
        }
    }

    // Global ESC shortcut
    Shortcut {
        sequence: "Escape"
        onActivated: if (stackView.depth > 1)
            stackView.pop()
    }
}
