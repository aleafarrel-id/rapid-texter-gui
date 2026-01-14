/**
 * @file RaceGameplayPage.qml
 * @brief Halaman gameplay race multiplayer dengan visualisasi track balapan yang kompak.
 * @author Alea Farrel & Team
 * @date 2026
 *
 * @details RaceGameplayPage menggabungkan mekanik single-player GameplayPage dengan
 * tampilan race track untuk mode multiplayer. Layout mengikuti style single-player
 * dengan area teks yang di-center.
 *
 * @par Fitur Utama:
 * - Race track di bagian atas menampilkan progress semua pemain
 * - Area pengetikan dengan visualisasi karakter (correct/incorrect/current)
 * - Statistik real-time (WPM, akurasi, errors, waktu)
 * - Sinkronisasi start game dengan countdown dari NetworkManager
 * - CAPS LOCK warning indicator
 *
 * @par Mekanik Pengetikan:
 * - Karakter yang benar berwarna putih
 * - Karakter yang salah berwarna merah dengan background
 * - Caret cursor berkedip pada posisi saat ini
 * - Backspace hanya bisa menghapus dalam kata yang sama (word locking)
 *
 * @par Integrasi Network:
 * - Menerima signal gameStarted untuk sinkronisasi start
 * - Update progress ke NetworkManager setiap keystroke
 * - Memanggil finishRace saat selesai mengetik
 *
 * @see GameplayPage.qml
 * @see RaceTrack.qml
 * @see NetworkManager
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen utama halaman gameplay race multiplayer.
 *
 * @details FocusScope digunakan untuk menangani keyboard input
 * melalui hidden TextInput.
 */
FocusScope {
    id: raceGameplayPage
    focus: true

    //=========================================================================
    // GAME STATE PROPERTIES - Properti state permainan
    //=========================================================================

    /**
     * @property targetText
     * @brief Teks target yang harus diketik oleh pemain.
     * @details Diambil dari NetworkManager.gameText yang di-sync dari host.
     */
    property string targetText: NetworkManager.gameText

    /**
     * @property typedChars
     * @brief Array karakter yang sudah diketik oleh pemain.
     */
    property var typedChars: []

    /**
     * @property typedText
     * @brief String gabungan dari typedChars untuk kemudahan.
     */
    property string typedText: typedChars.join("")

    /**
     * @property cursorPosition
     * @brief Posisi cursor saat ini (sama dengan jumlah karakter yang diketik).
     */
    property int cursorPosition: typedChars.length

    /**
     * @property gameStarted
     * @brief Flag apakah game sudah dimulai.
     * @details Diset true oleh signal onGameStarted dari NetworkManager.
     */
    property bool gameStarted: false

    /**
     * @property gameEnded
     * @brief Flag apakah game sudah selesai.
     */
    property bool gameEnded: false

    /**
     * @property correctChars
     * @brief Jumlah karakter yang diketik dengan benar.
     */
    property int correctChars: 0

    /**
     * @property incorrectChars
     * @brief Jumlah karakter yang diketik dengan salah.
     */
    property int incorrectChars: 0

    /**
     * @property totalKeystrokes
     * @brief Total jumlah keystroke (untuk perhitungan akurasi).
     */
    property int totalKeystrokes: 0

    /**
     * @property startTime
     * @brief Timestamp saat game dimulai (dalam milliseconds).
     */
    property real startTime: 0

    /**
     * @property elapsedTime
     * @brief Waktu yang sudah berlalu dalam detik.
     */
    property int elapsedTime: 0

    /**
     * @property correctPositions
     * @brief Map posisi yang sudah diketik dengan benar (untuk tracking first-time correct).
     */
    property var correctPositions: ({})

    /**
     * @property errorPositions
     * @brief Map posisi yang sudah diketik dengan salah (untuk tracking first-time error).
     */
    property var errorPositions: ({})

    //=========================================================================
    // RACE STATE PROPERTIES - Properti state balapan
    //=========================================================================

    /**
     * @property players
     * @brief Daftar pemain dari NetworkManager untuk ditampilkan di race track.
     */
    property var players: NetworkManager.players

    /**
     * @property playerUpdateCounter
     * @brief Counter untuk memaksa rebinding UI saat players berubah.
     */
    property int playerUpdateCounter: 0

    /**
     * @property showCountdown
     * @brief Flag untuk menampilkan countdown overlay.
     */
    property bool showCountdown: false

    /**
     * @property trackHeight
     * @brief Tinggi komponen race track dalam pixel.
     */
    property int trackHeight: 100

    //=========================================================================
    // REACTIVE STATS PROPERTIES - Properti statistik real-time
    //=========================================================================

    /**
     * @property currentWpm
     * @brief Words per minute saat ini (dihitung dari correctChars).
     */
    property int currentWpm: 0

    /**
     * @property currentAccuracy
     * @brief Akurasi saat ini dalam persen.
     */
    property real currentAccuracy: 100

    /**
     * @property capsLockOn
     * @brief Flag apakah CAPS LOCK sedang aktif.
     */
    property bool capsLockOn: false

    //=========================================================================
    // SIGNALS - Sinyal untuk komunikasi dengan parent
    //=========================================================================

    /**
     * @brief Dipancarkan saat race selesai dengan hasil pemain.
     * @param wpm Words per minute yang dicapai
     * @param accuracy Akurasi dalam persen
     * @param errors Jumlah kesalahan
     */
    signal raceCompleted(int wpm, real accuracy, int errors)

    /**
     * @brief Dipancarkan saat user memilih untuk keluar dari race.
     */
    signal exitClicked

    //=========================================================================
    // BACKGROUND - Latar belakang halaman
    //=========================================================================

    /**
     * @brief Rectangle latar belakang.
     */
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    //=========================================================================
    // WORD PROCESSING - Pemrosesan kata-kata untuk tampilan
    //=========================================================================

    /**
     * @property words
     * @brief Array kata-kata dari targetText yang dipisah oleh spasi.
     */
    property var words: targetText.split(" ")

    /**
     * @brief Membangun informasi struktur kata untuk rendering.
     * @return Array objek dengan word, startIndex, dan endIndex.
     *
     * @details Setiap objek berisi:
     * - word: String kata
     * - startIndex: Indeks karakter pertama dalam targetText
     * - endIndex: Indeks karakter terakhir dalam targetText
     */
    function buildWordInfo() {
        var result = [];
        var currentIndex = 0;
        for (var i = 0; i < words.length; i++) {
            result.push({
                word: words[i],
                startIndex: currentIndex,
                endIndex: currentIndex + words[i].length - 1
            });
            currentIndex += words[i].length + 1;  // +1 untuk spasi
        }
        return result;
    }

    /**
     * @property wordInfo
     * @brief Struktur informasi kata hasil dari buildWordInfo().
     */
    property var wordInfo: buildWordInfo()

    /**
     * @brief Mendapatkan state karakter pada posisi tertentu.
     * @param index Indeks karakter dalam targetText
     * @return String state: "correct", "incorrect", "current", atau "pending"
     *
     * @details State menentukan warna dan style karakter:
     * - correct: Sudah diketik dengan benar
     * - incorrect: Sudah diketik dengan salah
     * - current: Posisi cursor saat ini
     * - pending: Belum diketik
     */
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

    /**
     * @brief Mencari indeks awal kata yang sedang diketik.
     * @return Indeks karakter pertama dari kata saat ini.
     */
    function findCurrentWordStart() {
        for (var i = 0; i < wordInfo.length; i++) {
            if (cursorPosition >= wordInfo[i].startIndex && cursorPosition <= wordInfo[i].endIndex + 1) {
                return wordInfo[i].startIndex;
            }
        }
        return cursorPosition;
    }

    /**
     * @brief Memeriksa apakah backspace diizinkan pada posisi saat ini.
     * @return true jika bisa menghapus, false jika tidak.
     *
     * @details Implementasi word-locking: user tidak bisa menghapus
     * kata yang sudah selesai dengan benar. Ini mencegah cheating
     * dengan menghapus kata yang sudah benar.
     */
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

    /**
     * @brief Memperbarui statistik WPM dan akurasi.
     *
     * @details Perhitungan:
     * - WPM = (correctChars / 5) / minutes
     * - Accuracy = (correctChars / totalKeystrokes) * 100
     *
     * Menunggu minimal 0.5 detik sebelum menghitung untuk menghindari
     * nilai yang tidak masuk akal.
     */
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

    /**
     * @brief Handler untuk setiap key press dari user.
     * @param event Event keyboard yang diterima
     *
     * @details Menangani:
     * - Backspace: Menghapus karakter terakhir (jika diizinkan)
     * - Karakter lain: Menambah ke typedChars dan update stats
     *
     * Setiap keystroke juga memperbarui NetworkManager dengan progress terbaru.
     */
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

    /**
     * @brief Menyelesaikan race dan mengirim hasil ke NetworkManager.
     *
     * @details Dipanggil saat user sudah mengetik semua karakter.
     * Menghentikan timer dan mengirim hasil final ke server.
     */
    function finishRace() {
        if (gameEnded)
            return;
        gameEnded = true;
        elapsedTimer.stop();
        statsTimer.stop();
        updateStats();

        NetworkManager.finishRace(currentWpm, currentAccuracy, incorrectChars, elapsedTime);
    }

    /**
     * @brief Mereset semua state game ke kondisi awal.
     *
     * @details Digunakan untuk memulai ulang game baru.
     */
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

    //=========================================================================
    // TIMERS - Timer untuk tracking waktu dan update stats
    //=========================================================================

    /**
     * @brief Timer untuk menghitung waktu yang berlalu (per detik).
     */
    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: elapsedTime++
    }

    /**
     * @brief Timer untuk memperbarui statistik (per 500ms).
     */
    Timer {
        id: statsTimer
        interval: 500
        repeat: true
        onTriggered: updateStats()
    }

    //=========================================================================
    // NETWORK EVENT HANDLERS - Handler untuk event dari NetworkManager
    //=========================================================================

    /**
     * @brief Connections untuk menangani signal dari NetworkManager.
     */
    Connections {
        target: NetworkManager

        /**
         * @brief Handler saat game dimulai (synced dari host/countdown).
         *
         * @details Memulai timer dan mengaktifkan input focus.
         * Signal ini dipancarkan bersamaan untuk semua pemain.
         */
        function onGameStarted() {
            gameStarted = true;
            startTime = Date.now();
            elapsedTimer.start();
            statsTimer.start();
            hiddenInput.forceActiveFocus();
        }

        /**
         * @brief Handler saat progress pemain lain diperbarui.
         * @param id ID pemain
         * @param name Nama pemain
         * @param progress Progress dalam persen
         * @param wpm WPM pemain
         * @param finished Apakah sudah selesai
         * @param position Posisi finish
         */
        function onPlayerProgressUpdated(id, name, progress, wpm, finished, position) {
            players = NetworkManager.players;
        }

        /**
         * @brief Handler saat race selesai (semua pemain finish atau timeout).
         * @param rankings Daftar ranking pemain
         */
        function onRaceFinished(rankings) {
            raceGameplayPage.raceCompleted(currentWpm, currentAccuracy, incorrectChars);
        }
    }

    //=========================================================================
    // COUNTDOWN OVERLAY - Overlay hitungan mundur
    //=========================================================================

    /**
     * @brief Overlay countdown sebelum race dimulai.
     *
     * @details Menampilkan hitungan mundur 3-2-1-GO!
     * Setelah selesai, mengaktifkan focus untuk input.
     */
    CountdownOverlay {
        id: countdownOverlay
        anchors.fill: parent

        onFinished: {
            hiddenInput.forceActiveFocus();
        }
    }

    //=========================================================================
    // RACE TRACK HEADER - Visualisasi track balapan
    //=========================================================================

    /**
     * @brief Komponen race track yang menampilkan progress semua pemain.
     *
     * @details Posisi di atas halaman dengan binding ke players list.
     * Counter digunakan untuk memaksa update UI.
     */
    RaceTrack {
        id: raceTrackHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.paddingL
        height: trackHeight
        players: playerUpdateCounter >= 0 ? raceGameplayPage.players : []  ///< Bind dengan counter untuk force updates
    }

    //=========================================================================
    // MAIN CONTENT - Konten utama yang di-center
    //=========================================================================

    /**
     * @brief Container untuk konten utama (seperti single-player GameplayPage).
     */
    Item {
        anchors.top: raceTrackHeader.bottom
        anchors.topMargin: Theme.paddingL
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        /**
         * @brief Item yang memusatkan konten dengan lebar maksimum 800px.
         */
        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width - Theme.paddingHuge * 2, 800)
            height: gameCol.implicitHeight

            /**
             * @brief ColumnLayout utama untuk konten game.
             */
            ColumnLayout {
                id: gameCol
                anchors.fill: parent
                spacing: 0

                //=============================================================
                // TIMER ROW - Baris timer dan CAPS LOCK warning
                //=============================================================

                /**
                 * @brief Row untuk menampilkan timer dan CAPS LOCK warning.
                 */
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    spacing: Theme.spacingL

                    /**
                     * @brief Teks timer menampilkan waktu dalam detik.
                     */
                    Text {
                        Layout.leftMargin: 48
                        text: elapsedTime
                        color: Theme.accentBlue
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.DemiBold
                    }

                    /**
                     * @brief Warning box saat CAPS LOCK aktif.
                     */
                    Rectangle {
                        id: capsLockBox
                        visible: raceGameplayPage.capsLockOn
                        color: "#3D2800"  ///< Background kuning gelap
                        border.color: Theme.accentYellow
                        border.width: 1
                        radius: 4
                        width: capsLockContent.implicitWidth + 20
                        height: capsLockContent.implicitHeight + 8
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            id: capsLockContent
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
                    }
                }

                //=============================================================
                // TEXT DISPLAY - Area tampilan teks target
                //=============================================================

                /**
                 * @brief Container untuk area tampilan teks (borderless, clean).
                 */
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: textFlow.implicitHeight + 96
                    color: "transparent"

                    /**
                     * @brief Flow layout untuk kata-kata yang di-wrap.
                     */
                    Flow {
                        id: textFlow
                        anchors.fill: parent
                        anchors.margins: 48
                        spacing: 0

                        /**
                         * @brief Repeater untuk setiap kata dalam teks.
                         */
                        Repeater {
                            model: wordInfo.length

                            /**
                             * @brief Row untuk satu kata dan spasi setelahnya.
                             */
                            Row {
                                property int wordIndex: index
                                spacing: 0
                                height: 48

                                /**
                                 * @brief Repeater untuk setiap karakter dalam kata.
                                 */
                                Repeater {
                                    model: wordInfo[wordIndex] ? wordInfo[wordIndex].word.length : 0

                                    /**
                                     * @brief Teks untuk satu karakter dengan styling dinamis.
                                     *
                                     * @details Warna berdasarkan state:
                                     * - correct: textPrimary (putih)
                                     * - incorrect: accentRed (merah)
                                     * - current/pending: textMuted (abu-abu)
                                     */
                                    Text {
                                        property int charIndex: wordInfo[parent.wordIndex].startIndex + index
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

                                        /**
                                         * @brief Background merah untuk karakter salah.
                                         */
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: parent.font.pixelSize + 8
                                            color: parent.charState === "incorrect" ? Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15) : "transparent"
                                            z: -1
                                        }

                                        /**
                                         * @brief Caret cursor berkedip pada posisi saat ini.
                                         */
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

                                /**
                                 * @brief Teks untuk spasi setelah kata.
                                 *
                                 * @details Menampilkan karakter yang diketik jika salah,
                                 * atau spasi normal jika benar/pending.
                                 */
                                Text {
                                    id: spaceText
                                    visible: wordIndex < wordInfo.length - 1
                                    property int spaceIndex: wordInfo[wordIndex].endIndex + 1
                                    property string charState: cursorPosition >= 0 ? getCharState(spaceIndex) : "pending"
                                    property string typedChar: spaceIndex < typedChars.length ? typedChars[spaceIndex] : ""
                                    property string displayChar: charState === "incorrect" && typedChar.length > 0 ? typedChar : " "

                                    text: displayChar
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 28
                                    font.letterSpacing: 0.5
                                    color: charState === "incorrect" ? Theme.accentRed : Theme.textMuted

                                    /**
                                     * @brief Background untuk spasi yang salah.
                                     */
                                    Rectangle {
                                        visible: parent.charState === "incorrect"
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 36
                                        color: Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15)
                                        z: -1
                                    }

                                    /**
                                     * @brief Caret cursor pada posisi spasi.
                                     */
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

                //=============================================================
                // STATISTICS ROW - Baris statistik real-time
                //=============================================================

                /**
                 * @brief Row untuk menampilkan statistik saat gameplay.
                 *
                 * @details Hanya terlihat setelah game dimulai.
                 * Menampilkan: WPM, Correct, Errors, Time.
                 */
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 20
                    spacing: Theme.spacingXL
                    visible: gameStarted

                    /**
                     * @brief Statistik WPM (Words Per Minute).
                     */
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

                    /**
                     * @brief Statistik karakter benar.
                     */
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

                    /**
                     * @brief Statistik jumlah error.
                     */
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

                    /**
                     * @brief Statistik waktu yang berlalu.
                     */
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

                //=============================================================
                // NAVIGATION BUTTONS - Tombol navigasi
                //=============================================================

                /**
                 * @brief Row untuk tombol navigasi.
                 */
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    spacing: Theme.spacingM

                    /**
                     * @brief Tombol Exit untuk keluar dari race.
                     *
                     * @details Memanggil NetworkManager.leaveRoom() sebelum keluar.
                     */
                    NavBtn {
                        iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                        labelText: "Exit (ESC)"
                        onClicked: {
                            NetworkManager.leaveRoom();
                            raceGameplayPage.exitClicked();
                        }
                    }
                }

                //=============================================================
                // INSTRUCTION HINT - Petunjuk untuk user
                //=============================================================

                /**
                 * @brief Teks petunjuk yang berubah berdasarkan state game.
                 */
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

    //=========================================================================
    // HIDDEN INPUT - Input tersembunyi untuk keyboard capture
    //=========================================================================

    /**
     * @brief TextInput tersembunyi untuk menangkap keyboard input.
     *
     * @details Diperlukan karena QML tidak memiliki low-level keyboard
     * event handling yang baik tanpa focused text input.
     */
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

    //=========================================================================
    // FOCUS HANDLING - Handling untuk focus management
    //=========================================================================

    /**
     * @brief MouseArea untuk me-refocus input saat user klik di mana saja.
     */
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: hiddenInput.forceActiveFocus()
    }

    /**
     * @brief Handler keyboard untuk ESC di level FocusScope.
     */
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Escape) {
            NetworkManager.leaveRoom();
            raceGameplayPage.exitClicked();
            event.accepted = true;
        }
    }

    //=========================================================================
    // COMPONENT LIFECYCLE - Lifecycle komponen
    //=========================================================================

    /**
     * @brief Handler saat komponen selesai dimuat.
     *
     * @details Memulai countdown overlay dan timer untuk CAPS LOCK detection.
     */
    Component.onCompleted: {
        countdownOverlay.start();
        capsLockTimer.start();
    }

    /**
     * @brief Timer untuk memeriksa status CAPS LOCK secara periodik.
     */
    Timer {
        id: capsLockTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: capsLockOn = GameBackend.isCapsLockOn()
    }
}
