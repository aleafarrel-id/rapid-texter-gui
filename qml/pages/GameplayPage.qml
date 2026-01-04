import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

Rectangle {
    id: gameplayPage
    color: Theme.bgPrimary
    focus: true

    // ========================================================================
    // PROPERTIES - Game State
    // ========================================================================

    // Target text to type (will be set by parent)
    property string targetText: "darah salah tidak mulut ada di situ berbunyi melihat sekali"

    // User's typed text
    property string typedText: ""

    // Current cursor position
    property int cursorPosition: 0

    // Time remaining (seconds), -1 for unlimited
    property int timeRemaining: 15

    // Time limit (for display)
    property int timeLimit: 15

    // Is game started?
    property bool gameStarted: false

    // Is caps lock on?
    property bool capsLockOn: false

    // Game statistics
    property int correctChars: 0
    property int incorrectChars: 0
    property int totalKeystrokes: 0  // Every keystroke (not backspace)
    property real startTime: 0  // Timestamp when game started

    // ========================================================================
    // SIGNALS
    // ========================================================================

    signal gameCompleted(int wpm, real accuracy, int errors, real timeElapsed)
    signal resetClicked
    signal exitClicked

    // ========================================================================
    // FUNCTIONS
    // ========================================================================

    // Split target text into words for proper wrapping
    property var words: targetText.split(" ")

    // Build word info array with start/end indices
    function buildWordInfo() {
        var result = [];
        var currentIndex = 0;
        for (var i = 0; i < words.length; i++) {
            result.push({
                word: words[i],
                startIndex: currentIndex,
                endIndex: currentIndex + words[i].length - 1
            });
            currentIndex += words[i].length + 1; // +1 for space
        }
        return result;
    }

    property var wordInfo: buildWordInfo()

    function getCharState(index) {
        if (index < cursorPosition) {
            // Already typed
            if (index < typedText.length && typedText[index] === targetText[index]) {
                return "correct";
            } else {
                return "incorrect";
            }
        } else if (index === cursorPosition) {
            return "current";
        } else {
            return "pending";
        }
    }

    // Find the start of the current word being typed
    function findCurrentWordStart() {
        for (var i = 0; i < wordInfo.length; i++) {
            if (cursorPosition >= wordInfo[i].startIndex && cursorPosition <= wordInfo[i].endIndex + 1) {
                return wordInfo[i].startIndex;
            }
        }
        return cursorPosition;
    }

    // Check if we can delete (can't delete previous correctly completed words)
    function canDeleteAtPosition() {
        if (cursorPosition <= 0)
            return false;

        var prevIndex = cursorPosition - 1;
        var prevChar = targetText[prevIndex];

        // If previous char was a space and it was typed correctly, check if the word before was all correct
        if (prevChar === " " && typedText[prevIndex] === " ") {
            // Find the word that just ended
            for (var i = 0; i < wordInfo.length; i++) {
                if (wordInfo[i].endIndex === prevIndex - 1) {
                    // Check if this word was typed correctly
                    var allCorrect = true;
                    for (var j = wordInfo[i].startIndex; j <= wordInfo[i].endIndex; j++) {
                        if (typedText[j] !== targetText[j]) {
                            allCorrect = false;
                            break;
                        }
                    }
                    if (allCorrect)
                        return false; // Can't delete into a correctly completed word
                    break;
                }
            }
        }
        return true;
    }

    // Calculate game results (matching original TUI logic from Stats.h)
    function calculateResults() {
        var elapsedSeconds = (Date.now() - startTime) / 1000;
        if (elapsedSeconds <= 0)
            elapsedSeconds = 1;  // Avoid division by zero

        // WPM = (correctKeystrokes / 5) / (time in minutes)
        // Standard: 5 characters = 1 word
        var wpm = (correctChars / 5) / (elapsedSeconds / 60);

        // Accuracy = correctKeystrokes / totalKeystrokes * 100 (per original Stats.h)
        var accuracy = totalKeystrokes > 0 ? (correctChars / totalKeystrokes) * 100 : 0;

        return {
            wpm: Math.round(wpm),
            accuracy: accuracy,
            timeElapsed: elapsedSeconds
        };
    }

    function processKey(key, text) {
        if (!gameStarted && text.length > 0) {
            gameStarted = true;
            startTime = Date.now();  // Record start time
        }

        if (text.length > 0 && cursorPosition < targetText.length) {
            typedText += text;
            totalKeystrokes++;  // Count every keystroke (per original logic)

            if (text === targetText[cursorPosition]) {
                correctChars++;
                // No sound on correct keystroke (per user request)
            } else {
                incorrectChars++;  // Errors - only increases, never decreases
                GameBackend.playErrorSound();    // Play SFX for incorrect keystroke
            }
            cursorPosition++;

            // Check if completed
            if (cursorPosition >= targetText.length) {
                var results = calculateResults();
                gameCompleted(results.wpm, results.accuracy, incorrectChars, results.timeElapsed);
            }
        }
    }

    function resetGame() {
        typedText = "";
        cursorPosition = 0;
        correctChars = 0;
        incorrectChars = 0;
        totalKeystrokes = 0;
        gameStarted = false;
        startTime = 0;
        timeRemaining = timeLimit;
    }

    // ========================================================================
    // KEY HANDLING
    // ========================================================================

    // ========================================================================
    // KEY HANDLING
    // ========================================================================

    // Hidden input to capture text and trigger virtual keyboard
    TextInput {
        id: inputHandler
        visible: false // Hidden but active
        focus: true    // Auto-focus handled by Page
        enabled: true
        activeFocusOnTab: false // Avoid tab stealing focus accidentally

        // Keep focus
        onFocusChanged: {
            if (!focus && gameplayPage.visible) {
                forceActiveFocus();
            }
        }

        // Handle special keys
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Tab) {
                resetGame();
                resetClicked();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                exitClicked();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                if (canDeleteAtPosition()) {
                    typedText = typedText.slice(0, -1);
                    cursorPosition--;
                }
                event.accepted = true;
            }
        // Let normal text flow to onTextEdited
        }

        onTextEdited: {
            // Processing input character by character
            // We only care about the last character typed if it's an addition
            // But since we clear it immediately, 'text' is the new char

            if (text.length > 0) {
                // Iterate over all chars (in case of fast typing/paste)
                for (var i = 0; i < text.length; i++) {
                    var charCode = text[i];
                    if (charCode !== '\r' && charCode !== '\n') { // Ignore newlines
                        processKey(0, charCode);
                    }
                }
                // Clear input to keep it ready for next char
                text = "";
            }
        }
    }

    // Auto-focus when page becomes visible
    onVisibleChanged: {
        if (visible) {
            inputHandler.forceActiveFocus();
        }
    }

    // Also try to focus on click
    MouseArea {
        anchors.fill: parent
        z: -10 // Background click
        onClicked: {
            inputHandler.forceActiveFocus();
        }
    }

    // ========================================================================
    // TIMER
    // ========================================================================

    Timer {
        id: gameTimer
        interval: 1000
        running: gameplayPage.gameStarted && gameplayPage.timeRemaining > 0
        repeat: true
        onTriggered: {
            if (gameplayPage.timeRemaining > 0) {
                gameplayPage.timeRemaining--;
                if (gameplayPage.timeRemaining === 0) {
                    // Time's up!
                    var results = gameplayPage.calculateResults();
                    gameplayPage.gameCompleted(results.wpm, results.accuracy, gameplayPage.incorrectChars, results.timeElapsed);
                }
            }
        }
    }

    // ========================================================================
    // UI LAYOUT
    // ========================================================================

    // Timer to poll CAPS LOCK state
    Timer {
        id: capsLockTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: capsLockOn = GameBackend.isCapsLockOn()
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 1000)
        height: gameCol.implicitHeight

        ColumnLayout {
            id: gameCol
            anchors.fill: parent
            spacing: 0

            // Timer and CAPS LOCK warning row
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 10
                spacing: Theme.spacingL

                // Timer Display
                Text {
                    Layout.leftMargin: 48
                    text: gameplayPage.timeRemaining >= 0 ? gameplayPage.timeRemaining : "∞"
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                }

                // CAPS LOCK Warning (matches original TUI)
                Rectangle {
                    visible: capsLockOn
                    color: "#3D2800"
                    border.color: Theme.accentYellow
                    border.width: 1
                    radius: 4
                    width: capsLockText.implicitWidth + 20
                    height: capsLockText.implicitHeight + 8

                    Text {
                        id: capsLockText
                        anchors.centerIn: parent
                        text: "CAPS LOCK ON"
                        color: Theme.accentYellow
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        font.bold: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                }  // Spacer
            }

            // Text Display
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: textFlow.implicitHeight + 96
                color: "transparent"
                border.width: 1
                border.color: Theme.borderPrimary

                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.borderSecondary
                }

                Flow {
                    id: textFlow
                    anchors.fill: parent
                    anchors.margins: 48
                    spacing: 12 // Space between words

                    Repeater {
                        model: gameplayPage.wordInfo.length

                        // Each word is a Row that won't be broken
                        Row {
                            id: wordRow
                            spacing: 0

                            property int wordIndex: index
                            property var wordData: gameplayPage.wordInfo[index]

                            Repeater {
                                model: wordData.word.length

                                Text {
                                    id: charText

                                    property int globalIndex: wordData.startIndex + index
                                    property string charState: gameplayPage.getCharState(globalIndex)
                                    property string character: wordData.word[index]

                                    text: character
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
                                        case "pending":
                                        default:
                                            return Theme.textMuted;
                                        }
                                    }

                                    // Background for incorrect chars - fixed height
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: charText.font.pixelSize + 8
                                        color: charText.charState === "incorrect" ? Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15) : "transparent"
                                        z: -1
                                    }

                                    // Caret cursor (vertical bar)
                                    Rectangle {
                                        visible: charText.charState === "current"
                                        anchors.left: parent.left
                                        anchors.leftMargin: -1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 2
                                        height: charText.font.pixelSize + 6
                                        color: Theme.accentBlue

                                        SequentialAnimation on opacity {
                                            running: charText.charState === "current" && !gameplayPage.gameStarted
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
            }

            // CAPS LOCK Warning using SVG
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: capsLockOn ? 44 : 0
                Layout.topMargin: capsLockOn ? 20 : 0
                visible: gameplayPage.capsLockOn
                color: Theme.warningBg
                border.width: 1
                border.color: Theme.accentYellow

                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.accentYellow
                }

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    Item {
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: capsLockIcon
                            source: "qrc:/qt/qml/rapid_texter/assets/icons/warning.svg"
                            anchors.fill: parent
                            sourceSize: Qt.size(14, 14)
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: capsLockIcon
                            source: capsLockIcon
                            color: Theme.accentYellow
                        }
                    }

                    Text {
                        text: "CAPS LOCK ON"
                        color: Theme.accentYellow
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            // Statistics Row (optional - shows during gameplay)
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                spacing: Theme.spacingXL
                visible: gameplayPage.gameStarted

                Row {
                    spacing: Theme.spacingS
                    Text {
                        text: "Correct:"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                    }
                    Text {
                        text: gameplayPage.correctChars
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
                        text: gameplayPage.incorrectChars
                        color: Theme.accentRed
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeM
                        font.bold: true
                    }
                }
            }

            // Navigation Buttons
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                spacing: Theme.spacingM

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    labelText: "Reset (TAB)"
                    variant: "yellow"
                    onClicked: {
                        gameplayPage.resetGame();
                        gameplayPage.resetClicked();
                    }
                }

                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                    labelText: "Exit (ESC)"
                    onClicked: gameplayPage.exitClicked()
                }
            }

            // Instruction hint
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                text: gameplayPage.gameStarted ? "Keep typing..." : "Start typing to begin!"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSM
            }
        }
    }
}
