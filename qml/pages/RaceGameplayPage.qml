/**
 * @file RaceGameplayPage.qml
 * @brief Multiplayer race gameplay page with compact race track visualization.
 *
 * Combines the single-player GameplayPage mechanics with a race track display.
 * Layout matches single-player style with centered text area.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

FocusScope {
    id: raceGameplayPage
    focus: true

    // Game state
    property string targetText: NetworkManager.gameText
    property var typedChars: []
    property string typedText: typedChars.join("")
    property int cursorPosition: typedChars.length
    property bool gameStarted: false
    property bool gameEnded: false
    property int correctChars: 0
    property int incorrectChars: 0
    property int totalKeystrokes: 0
    property real startTime: 0
    property int elapsedTime: 0
    property var correctPositions: ({})
    property var errorPositions: ({})

    // Race state - use a simple counter to force rebinding
    property var players: NetworkManager.players
    property int playerUpdateCounter: 0
    property bool showCountdown: false
    property int trackHeight: 100

    // Reactive stats properties
    property int currentWpm: 0
    property real currentAccuracy: 100

    signal raceCompleted(int wpm, real accuracy, int errors)
    signal exitClicked

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    // Word processing
    property var words: targetText.split(" ")

    function buildWordInfo() {
        var result = [];
        var currentIndex = 0;
        for (var i = 0; i < words.length; i++) {
            result.push({
                word: words[i],
                startIndex: currentIndex,
                endIndex: currentIndex + words[i].length - 1
            });
            currentIndex += words[i].length + 1;
        }
        return result;
    }
    property var wordInfo: buildWordInfo()

    function getCharState(index) {
        if (index < cursorPosition) {
            if (index < typedChars.length) {
                var typedChar = typedChars[index];
                var targetChar = targetText.charAt(index);
                return typedChar === targetChar ? "correct" : "incorrect";
            }
            return "pending";
        } else if (index === cursorPosition) {
            return "current";
        }
        return "pending";
    }

    function findCurrentWordStart() {
        for (var i = 0; i < wordInfo.length; i++) {
            if (cursorPosition >= wordInfo[i].startIndex && cursorPosition <= wordInfo[i].endIndex + 1) {
                return wordInfo[i].startIndex;
            }
        }
        return cursorPosition;
    }

    function canDeleteAtPosition() {
        if (cursorPosition <= 0)
            return false;
        var lockedLimit = 0;
        for (var i = 0; i < wordInfo.length - 1; i++) {
            var wordEnd = wordInfo[i].endIndex;
            var spacePos = wordEnd + 1;
            if (spacePos < cursorPosition) {
                var wordAllCorrect = true;
                for (var j = wordInfo[i].startIndex; j <= wordEnd; j++) {
                    if (j >= typedChars.length || typedChars[j] !== targetText.charAt(j)) {
                        wordAllCorrect = false;
                        break;
                    }
                }
                if (wordAllCorrect && spacePos < typedChars.length && typedChars[spacePos] === " ") {
                    lockedLimit = spacePos + 1;
                }
            }
        }
        return cursorPosition > lockedLimit;
    }

    function updateStats() {
        if (!gameStarted || startTime <= 0) {
            currentWpm = 0;
            currentAccuracy = 100;
            return;
        }
        var elapsedSecs = (Date.now() - startTime) / 1000;
        if (elapsedSecs < 0.5) {
            currentWpm = 0;
            currentAccuracy = 100;
            return;
        }
        var minutes = elapsedSecs / 60;
        currentWpm = Math.round((correctChars / 5) / minutes);
        currentAccuracy = totalKeystrokes > 0 ? Math.round((correctChars / totalKeystrokes) * 1000) / 10 : 100;
    }

    function handleKeyPress(event) {
        if (gameEnded)
            return;

        if (gameEnded)
            return;

        // Note: Game start is now handled by onGameStarted signal from NetworkManager
        // This ensures all players start at the same time regardless of when they start typing

        if (event.key === Qt.Key_Backspace) {
            if (canDeleteAtPosition() && typedChars.length > 0) {
                var deletedPos = typedChars.length - 1;
                if (correctPositions[deletedPos])
                    delete correctPositions[deletedPos];
                if (errorPositions[deletedPos])
                    delete errorPositions[deletedPos];
                typedChars = typedChars.slice(0, -1);
                typedCharsChanged();
            }
        } else if (event.text.length === 1 && cursorPosition < targetText.length) {
            var inputChar = event.text;
            var expectedChar = targetText.charAt(cursorPosition);
            var isCorrect = (inputChar === expectedChar);

            // Save position BEFORE modifying array
            var typedPosition = cursorPosition;

            var newTypedChars = typedChars.slice();
            newTypedChars.push(inputChar);
            typedChars = newTypedChars;

            totalKeystrokes++;

            // Use saved position for correct tracking
            if (isCorrect && !correctPositions[typedPosition]) {
                correctChars++;
                correctPositions[typedPosition] = true;
                GameBackend.playCorrectSound();
            } else if (!isCorrect && !errorPositions[typedPosition]) {
                incorrectChars++;
                errorPositions[typedPosition] = true;
                GameBackend.playErrorSound();
            }

            // Update stats
            updateStats();

            // Update network progress
            NetworkManager.updateProgress(typedChars.length, targetText.length, currentWpm, currentAccuracy, incorrectChars);

            // Force refresh players list to update race track
            playerUpdateCounter++;
            players = NetworkManager.players;

            // Check completion
            if (typedChars.length >= targetText.length) {
                finishRace();
            }
        }
    }

    function finishRace() {
        if (gameEnded)
            return;
        gameEnded = true;
        elapsedTimer.stop();
        statsTimer.stop();
        updateStats();

        NetworkManager.finishRace(currentWpm, currentAccuracy, incorrectChars, elapsedTime);
    }

    function resetGame() {
        typedChars = [];
        correctPositions = {};
        errorPositions = {};
        correctChars = 0;
        incorrectChars = 0;
        totalKeystrokes = 0;
        gameStarted = false;
        gameEnded = false;
        startTime = 0;
        elapsedTime = 0;
        currentWpm = 0;
        currentAccuracy = 100;
        hiddenInput.clear();
        hiddenInput.forceActiveFocus();
    }

    // Timers
    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: elapsedTime++
    }

    Timer {
        id: statsTimer
        interval: 500
        repeat: true
        onTriggered: updateStats()
    }

    // Network event handlers
    Connections {
        target: NetworkManager

        function onGameStarted() {
            // Start game immediately when signal is received (synced with host/countdown)
            gameStarted = true;
            startTime = Date.now();
            elapsedTimer.start();
            statsTimer.start();
            hiddenInput.forceActiveFocus();
        }

        function onPlayerProgressUpdated(id, name, progress, wpm, finished, position) {
            players = NetworkManager.players;
        }

        function onRaceFinished(rankings) {
            raceGameplayPage.raceCompleted(currentWpm, currentAccuracy, incorrectChars);
        }
    }

    // Countdown overlay
    CountdownOverlay {
        id: countdownOverlay
        anchors.fill: parent

        onFinished: {
            hiddenInput.forceActiveFocus();
        }
    }

    // Compact Race Track (fixed at top)
    RaceTrack {
        id: raceTrackHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.paddingL
        height: trackHeight
        // Bind with counter to force updates
        players: playerUpdateCounter >= 0 ? raceGameplayPage.players : []
    }

    // Main centered content (like single-player)
    Item {
        anchors.top: raceTrackHeader.bottom
        anchors.topMargin: Theme.paddingL
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width - Theme.paddingHuge * 2, 800)
            height: gameCol.implicitHeight

            ColumnLayout {
                id: gameCol
                anchors.fill: parent
                spacing: 0

                // Timer display (like single-player)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    spacing: Theme.spacingL

                    Text {
                        Layout.leftMargin: 48
                        text: elapsedTime
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Text Display (borderless, clean like single-player)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: textFlow.implicitHeight + 96
                    color: "transparent"

                    Flow {
                        id: textFlow
                        anchors.fill: parent
                        anchors.margins: 48
                        spacing: 0

                        Repeater {
                            model: wordInfo.length

                            Row {
                                property int wordIndex: index
                                spacing: 0
                                height: 48

                                Repeater {
                                    model: wordInfo[wordIndex] ? wordInfo[wordIndex].word.length : 0

                                    Text {
                                        property int charIndex: wordInfo[parent.wordIndex].startIndex + index
                                        // Explicitly depend on cursorPosition for reactivity
                                        property string charState: cursorPosition >= 0 ? getCharState(charIndex) : "pending"

                                        text: targetText.charAt(charIndex)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 28
                                        font.letterSpacing: 0.5

                                        color: {
                                            switch (charState) {
                                            case "correct":
                                                return Theme.textPrimary;
                                            case "incorrect":
                                                return Theme.accentRed;
                                            case "current":
                                                return Theme.textMuted;
                                            default:
                                                return Theme.textMuted;
                                            }
                                        }

                                        // Background for incorrect chars
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: parent.font.pixelSize + 8
                                            color: parent.charState === "incorrect" ? Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15) : "transparent"
                                            z: -1
                                        }

                                        // Caret cursor
                                        Rectangle {
                                            visible: parent.charState === "current"
                                            anchors.left: parent.left
                                            anchors.leftMargin: -1
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 2
                                            height: parent.font.pixelSize + 6
                                            color: Theme.accentBlue

                                            SequentialAnimation on opacity {
                                                running: parent.charState === "current" && !gameStarted
                                                loops: Animation.Infinite
                                                NumberAnimation {
                                                    to: 0
                                                    duration: 500
                                                }
                                                NumberAnimation {
                                                    to: 1
                                                    duration: 500
                                                }
                                            }
                                        }
                                    }
                                }

                                // Space after word
                                Text {
                                    id: spaceText
                                    visible: wordIndex < wordInfo.length - 1
                                    property int spaceIndex: wordInfo[wordIndex].endIndex + 1
                                    // Explicitly depend on cursorPosition for reactivity
                                    property string charState: cursorPosition >= 0 ? getCharState(spaceIndex) : "pending"
                                    property string typedChar: spaceIndex < typedChars.length ? typedChars[spaceIndex] : ""
                                    property string displayChar: charState === "incorrect" && typedChar.length > 0 ? typedChar : " "

                                    text: displayChar
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 28
                                    font.letterSpacing: 0.5
                                    color: charState === "incorrect" ? Theme.accentRed : Theme.textMuted

                                    // Background for incorrect space
                                    Rectangle {
                                        visible: parent.charState === "incorrect"
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 36
                                        color: Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15)
                                        z: -1
                                    }

                                    // Caret cursor at space
                                    Rectangle {
                                        visible: parent.charState === "current"
                                        anchors.left: parent.left
                                        anchors.leftMargin: -1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 2
                                        height: 34
                                        color: Theme.accentBlue

                                        SequentialAnimation on opacity {
                                            running: parent.charState === "current" && !gameStarted
                                            loops: Animation.Infinite
                                            NumberAnimation {
                                                to: 0
                                                duration: 500
                                            }
                                            NumberAnimation {
                                                to: 1
                                                duration: 500
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Statistics Row (like single-player - shows during gameplay)
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    spacing: Theme.spacingXL
                    visible: gameStarted

                    Row {
                        spacing: Theme.spacingS
                        Text {
                            text: "WPM:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: currentWpm
                            color: Theme.accentBlue
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        Text {
                            text: "Correct:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: correctChars
                            color: Theme.accentGreen
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        Text {
                            text: "Errors:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: incorrectChars
                            color: Theme.accentRed
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                            font.bold: true
                        }
                    }

                    Row {
                        spacing: Theme.spacingS
                        Text {
                            text: "Time:"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                        Text {
                            text: elapsedTime + "s"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeM
                        }
                    }
                }

                // Navigation Buttons
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    spacing: Theme.spacingM

                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                        labelText: "Exit (ESC)"
                        onClicked: {
                            NetworkManager.leaveRoom();
                            raceGameplayPage.exitClicked();
                        }
                    }
                }

                // Instruction hint
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    text: gameStarted ? "Keep typing..." : "Start typing to begin!"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSM
                }
            }
        }
    }

    // Hidden input
    TextInput {
        id: hiddenInput
        width: 1
        height: 1
        opacity: 0
        focus: true

        Keys.onPressed: function (event) {
            // ESC key: leave race instead of processing as input
            if (event.key === Qt.Key_Escape) {
                NetworkManager.leaveRoom();
                raceGameplayPage.exitClicked();
                event.accepted = true;
                return;
            }
            handleKeyPress(event);
            event.accepted = true;
        }
    }

    // Focus handling
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: hiddenInput.forceActiveFocus()
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            NetworkManager.leaveRoom();
            raceGameplayPage.exitClicked();
            event.accepted = true;
        }
    }

    Component.onCompleted: {
        countdownOverlay.start();
    }
}
