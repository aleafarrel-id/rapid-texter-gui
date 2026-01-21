/**
 * @file GameplayPage.qml
 * @brief Halaman utama permainan mengetik dengan pelacakan karakter real-time.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details Komponen ini menyediakan pengalaman mengetik utama dengan fitur:
 * - Pelacakan input karakter per karakter secara real-time
 * - Feedback visual untuk karakter benar/salah
 * - Animasi kursor berkedip
 * - Countdown timer atau mode infinity
 * - Dukungan backspace dengan logika skip
 * - Peringatan CAPS LOCK aktif
 *
 * @par Arsitektur:
 * Menggunakan TextInput tersembunyi untuk menangkap keyboard dan
 * Flow/Repeater untuk rendering karakter dengan styling per karakter.
 * Setiap karakter di-render sebagai Text element terpisah untuk
 * kontrol warna yang presisi.
 *
 * @par Metrik Performa:
 * - WPM: Words Per Minute = (correctChars / 5) / (time in minutes)
 * - Accuracy: (correctChars / totalKeystrokes) * 100%
 *
 * @section shortcuts Pintasan Keyboard
 * | Tombol | Aksi |
 * |--------|------|
 * | TAB | Reset permainan |
 * | Escape | Keluar dari permainan |
 * | Backspace | Hapus karakter (dengan batasan) |
 *
 * @see ResultsPage Halaman hasil setelah permainan selesai
 * @see GameBackend Backend untuk logika permainan dan audio
 * @see TextProvider Penyedia teks berdasarkan bahasa
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import rapid_texter
import "../components"

/**
 * @brief Komponen halaman gameplay utama dengan mekanik mengetik.
 * @inherits FocusScope
 *
 * @details FocusScope ini berfungsi sebagai container utama untuk permainan.
 * Menggunakan FocusScope untuk menangani delegate fokus ke TextInput tersembunyi.
 *
 * @par Alur Permainan:
 * 1. Halaman dimuat dengan targetText dari parent
 * 2. User mulai mengetik (gameStarted = true, timer dimulai)
 * 3. Setiap karakter dicek benar/salah dengan feedback visual
 * 4. Game selesai saat: semua karakter diketik ATAU waktu habis
 * 5. Signal gameCompleted di-emit dengan statistik
 */
FocusScope {
    id: gameplayPage
    focus: true

    /**
     * @brief Background rectangle untuk konsistensi tema.
     * @details Menggunakan z-index rendah agar konten tampil di atasnya.
     */
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        z: -100
    }

    /* ========================================================================
     * PROPERTI - State Permainan
     * ======================================================================== */

    /**
     * @property targetText
     * @brief Teks target yang harus diketik user.
     * @type string
     *
     * @details Teks ini di-set oleh parent component dari TextProvider.
     * Panjang teks menentukan durasi dan kesulitan permainan.
     */
    property string targetText: "darah salah tidak mulut ada di situ berbunyi melihat sekali"

    /**
     * @property typedChars
     * @brief Array karakter yang sudah diketik untuk reaktivitas.
     * @type var (Array)
     *
     * @details Menggunakan array (bukan string) untuk memastikan
     * QML mendeteksi perubahan dan memperbarui UI.
     * cursorPosition dihitung dari length array ini.
     */
    property var typedChars: []

    /**
     * @property typedText
     * @brief String gabungan untuk backward compatibility.
     * @type string
     *
     * @details Dihitung dari typedChars.join("").
     */
    property string typedText: typedChars.join("")

    /**
     * @property cursorPosition
     * @brief Posisi kursor saat ini.
     * @type int
     *
     * @details SELALU sama dengan typedChars.length untuk mencegah desync.
     * Properti ini computed, bukan di-set manual.
     */
    property int cursorPosition: typedChars.length

    /**
     * @property timeRemaining
     * @brief Waktu tersisa dalam detik, -1 untuk unlimited.
     * @type int
     * @default 15
     */
    property int timeRemaining: 15

    /**
     * @property timeLimit
     * @brief Batas waktu untuk tampilan dan logika timer.
     * @type int
     * @default 15
     *
     * @details Jika <= 0, mode infinity aktif (waktu tidak terbatas).
     */
    property int timeLimit: 15

    /**
     * @property gameStarted
     * @brief Menandakan apakah permainan sudah dimulai.
     * @type bool
     * @default false
     *
     * @details Menjadi true saat user mengetik karakter pertama.
     */
    property bool gameStarted: false

    /**
     * @property capsLockOn
     * @brief Menandakan apakah CAPS LOCK aktif.
     * @type bool
     * @default false
     *
     * @details Di-poll setiap 200ms dari GameBackend.
     */
    property bool capsLockOn: false

    /* ========================================================================
     * PROPERTI - Statistik Permainan
     * ======================================================================== */

    /**
     * @property correctChars
     * @brief Jumlah karakter yang diketik dengan benar.
     * @type int
     * @default 0
     */
    property int correctChars: 0

    /**
     * @property incorrectChars
     * @brief Jumlah karakter yang diketik dengan salah.
     * @type int
     * @default 0
     */
    property int incorrectChars: 0

    /**
     * @property totalKeystrokes
     * @brief Total keystroke (tidak termasuk backspace).
     * @type int
     * @default 0
     */
    property int totalKeystrokes: 0

    /**
     * @property startTime
     * @brief Timestamp saat permainan dimulai.
     * @type real
     * @default 0
     */
    property real startTime: 0

    /**
     * @property gameEnded
     * @brief Mencegah double signal gameCompleted.
     * @type bool
     * @default false
     */
    property bool gameEnded: false

    /**
     * @property elapsedTime
     * @brief Waktu yang berlalu dalam detik (untuk mode infinity).
     * @type int
     * @default 0
     */
    property int elapsedTime: 0

    /**
     * @property correctPositions
     * @brief Tracking posisi yang sudah dihitung benar (standar MonkeyType).
     * @type var (Object)
     *
     * @details Mencegah double counting saat: ketik benar → backspace → ketik benar lagi.
     */
    property var correctPositions: ({})

    /**
     * @property errorPositions
     * @brief Tracking posisi yang sudah dihitung error.
     * @type var (Object)
     *
     * @details Mencegah double counting saat: ketik salah → backspace → ketik salah lagi.
     */
    property var errorPositions: ({})

    /* ========================================================================
     * SIGNAL
     * ======================================================================== */

    /**
     * @signal gameCompleted
     * @brief Dipancarkan ketika permainan selesai.
     * @param wpm int Words per minute
     * @param accuracy real Persentase akurasi
     * @param errors int Jumlah kesalahan
     * @param timeElapsed real Waktu yang dihabiskan dalam detik
     *
     * @details Signal ini di-emit ketika:
     * - Semua karakter berhasil diketik
     * - Waktu habis (mode countdown)
     */
    signal gameCompleted(int wpm, real accuracy, int errors, real timeElapsed)

    /**
     * @signal resetClicked
     * @brief Dipancarkan ketika user menekan TAB untuk reset.
     */
    signal resetClicked

    /**
     * @signal exitClicked
     * @brief Dipancarkan ketika user menekan ESC untuk keluar.
     */
    signal exitClicked

    /* ========================================================================
     * FUNGSI HELPER
     * ======================================================================== */

    /**
     * @property words
     * @brief Array kata-kata dari targetText yang di-split.
     * @type var (Array)
     *
     * @details Digunakan untuk membangun wordInfo untuk rendering
     * kata per kata sehingga word-wrap berfungsi dengan benar.
     */
    property var words: targetText.split(" ")

    /**
     * @brief Membangun array info kata dengan indeks start/end.
     * @return Array objek dengan properti: word, startIndex, endIndex
     *
     * @details Setiap objek dalam array berisi:
     * - word: string kata itu sendiri
     * - startIndex: posisi karakter pertama dalam targetText
     * - endIndex: posisi karakter terakhir dalam targetText
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
            currentIndex += words[i].length + 1; // +1 for space
        }
        return result;
    }

    /**
     * @property wordInfo
     * @brief Array hasil dari buildWordInfo().
     * @type var (Array)
     */
    property var wordInfo: buildWordInfo()

    /**
     * @brief Mendapatkan state karakter pada posisi tertentu.
     * @param index int Posisi karakter dalam targetText.
     * @return string State: "correct", "incorrect", "current", atau "pending"
     *
     * @details State menentukan warna dan styling karakter:
     * - correct: Sudah diketik dengan benar (warna primer)
     * - incorrect: Sudah diketik tapi salah (warna merah)
     * - current: Posisi kursor saat ini (muted + caret)
     * - pending: Belum diketik (muted)
     */
    function getCharState(index) {
        if (index < cursorPosition) {
            if (index < typedChars.length) {
                var typedChar = typedChars[index];
                var targetChar = targetText.charAt(index);
                if (typedChar === targetChar) {
                    return "correct";
                } else {
                    return "incorrect";
                }
            } else {
                return "pending";
            }
        } else if (index === cursorPosition) {
            return "current";
        } else {
            return "pending";
        }
    }

    /**
     * @brief Mencari posisi awal kata yang sedang diketik.
     * @return int Posisi karakter awal dari kata saat ini.
     *
     * @details Digunakan untuk menentukan batas backspace.
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
     * @return bool True jika boleh hapus, false jika tidak.
     *
     * @details Logika penghapusan (matching GameEngine.cpp TUI):
     * - Tidak bisa menghapus jika kursor di posisi 0
     * - Tidak bisa menghapus kata yang sudah benar sepenuhnya
     * - Checkpoint dibuat di setiap spasi yang benar
     */
    function canDeleteAtPosition() {
        if (cursorPosition <= 0)
            return false;

        var lockedLimit = 0;

        for (var i = cursorPosition - 1; i >= 0; i--) {
            if (i < targetText.length && targetText.charAt(i) === " ") {
                var allCorrect = true;
                if (i < typedChars.length) {
                    for (var k = 0; k <= i; k++) {
                        if (k >= typedChars.length || typedChars[k] !== targetText.charAt(k)) {
                            allCorrect = false;
                            break;
                        }
                    }
                    if (allCorrect) {
                        lockedLimit = i + 1;
                        break;
                    }
                }
            }
        }

        return cursorPosition > lockedLimit;
    }

    /**
     * @brief Menghitung hasil permainan (WPM, akurasi, waktu).
     * @return Object dengan properti: wpm, accuracy, timeElapsed
     *
     * @details Formula perhitungan (sesuai Stats.h original):
     * - WPM = (correctChars / 5) / (time in minutes)
     * - Accuracy = (correctChars / totalKeystrokes) * 100
     * - 5 karakter = 1 kata (standar industri)
     */
    function calculateResults() {
        var elapsedSeconds = (Date.now() - startTime) / 1000;
        if (elapsedSeconds <= 0)
            elapsedSeconds = 1;

        var wpm = (correctChars / 5) / (elapsedSeconds / 60);
        var accuracy = totalKeystrokes > 0 ? (correctChars / totalKeystrokes) * 100 : 0;

        return {
            wpm: Math.round(wpm),
            accuracy: accuracy,
            timeElapsed: elapsedSeconds
        };
    }

    /**
     * @brief Memproses keystroke dari user.
     * @param key int Kode key (tidak digunakan, untuk compatibility).
     * @param text string Karakter yang diketik.
     *
     * @details Alur pemrosesan:
     * 1. Jika game belum mulai, mulai timer dan catat startTime
     * 2. Tambahkan karakter ke typedChars
     * 3. Cek apakah karakter benar atau salah
     * 4. Update statistik (dengan mencegah double counting)
     * 5. Play error sound jika salah
     * 6. Cek apakah game selesai
     */
    function processKey(key, text) {
        if (!gameStarted && text.length > 0) {
            gameStarted = true;
            startTime = Date.now();
        }

        var positionBeforePush = cursorPosition;

        if (text.length > 0 && positionBeforePush < targetText.length) {
            var newTypedChars = typedChars.slice();
            newTypedChars.push(text);
            typedChars = newTypedChars;

            totalKeystrokes++;

            if (text === targetText.charAt(positionBeforePush)) {
                if (!correctPositions[positionBeforePush]) {
                    correctPositions[positionBeforePush] = true;
                    correctChars++;
                }
            } else {
                if (!errorPositions[positionBeforePush]) {
                    errorPositions[positionBeforePush] = true;
                    incorrectChars++;
                }
                GameBackend.playErrorSound();
            }

            if (cursorPosition >= targetText.length && !gameEnded) {
                gameEnded = true;
                var results = calculateResults();
                gameCompleted(results.wpm, results.accuracy, incorrectChars, results.timeElapsed);
            }
        }
    }

    /**
     * @brief Mereset game ke state awal.
     *
     * @details Reset semua state:
     * - typedChars menjadi array kosong
     * - Semua counter statistik menjadi 0
     * - Timer direset
     * - Game flags direset
     */
    function resetGame() {
        typedChars = [];
        correctChars = 0;
        incorrectChars = 0;
        totalKeystrokes = 0;
        correctPositions = {};
        errorPositions = {};
        gameStarted = false;
        gameEnded = false;
        startTime = 0;
        timeRemaining = timeLimit;
        elapsedTime = 0;
    }

    /* ========================================================================
     * PENANGANAN INPUT
     * ======================================================================== */

    /**
     * @brief TextInput tersembunyi untuk menangkap keyboard.
     *
     * @details Komponen ini berfungsi sebagai "keyboard trap":
     * - Visible tapi opacity 0 (harus visible untuk menerima focus)
     * - Ukuran 0x0 untuk minimize footprint
     * - Menangkap semua keystroke dan forward ke processKey()
     * - Menangani tombol khusus (Tab, Escape, Backspace)
     *
     * @note Pada mobile, ini juga trigger virtual keyboard.
     */
    TextInput {
        id: inputHandler
        visible: true
        opacity: 0
        width: 0
        height: 0
        focus: true
        enabled: true
        activeFocusOnTab: false

        /// @brief Paksa focus kembali jika hilang saat halaman aktif
        onFocusChanged: {
            if (!focus && StackView.status === StackView.Active) {
                forceActiveFocus();
            }
        }

        /**
         * @brief Handler untuk tombol khusus.
         *
         * @details Menangani:
         * - Tab: Reset game dan emit signal
         * - Escape: Exit game
         * - Backspace: Hapus karakter (dengan validasi)
         */
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
                    var newTypedChars = typedChars.slice(0, -1);
                    typedChars = newTypedChars;
                }
                event.accepted = true;
            }
        }

        /// @brief Handler saat teks diedit (karakter biasa)
        onTextEdited: {
            if (text.length > 0) {
                for (var i = 0; i < text.length; i++) {
                    var charCode = text[i];
                    if (charCode !== '\r' && charCode !== '\n') {
                        processKey(0, charCode);
                    }
                }
                text = "";
            }
        }
    }

    /**
     * @brief MouseArea untuk menangkap klik dan focus input.
     *
     * @details Klik di mana saja pada halaman akan memaksa
     * fokus ke inputHandler untuk memulai mengetik.
     */
    MouseArea {
        anchors.fill: parent
        z: -10
        onClicked: {
            inputHandler.forceActiveFocus();
        }
    }

    /* ========================================================================
     * TIMER
     * ======================================================================== */

    /**
     * @brief Timer countdown untuk mode waktu terbatas.
     *
     * @details Timer ini aktif saat:
     * - gameStarted = true
     * - timeRemaining > 0
     *
     * Saat waktu habis, gameCompleted signal di-emit.
     */
    Timer {
        id: gameTimer
        interval: 1000
        running: gameplayPage.gameStarted && gameplayPage.timeRemaining > 0
        repeat: true
        onTriggered: {
            if (gameplayPage.timeRemaining > 0) {
                gameplayPage.timeRemaining--;
                if (gameplayPage.timeRemaining === 0 && !gameplayPage.gameEnded) {
                    gameplayPage.gameEnded = true;
                    var results = gameplayPage.calculateResults();
                    gameplayPage.gameCompleted(results.wpm, results.accuracy, gameplayPage.incorrectChars, results.timeElapsed);
                }
            }
        }
    }

    /**
     * @brief Timer elapsed untuk mode infinity (waktu tidak terbatas).
     *
     * @details Timer ini hitung naik saat timeLimit <= 0.
     * Digunakan untuk menampilkan berapa lama user sudah mengetik.
     */
    Timer {
        id: elapsedTimer
        interval: 1000
        running: gameplayPage.gameStarted && gameplayPage.timeLimit <= 0 && !gameplayPage.gameEnded
        repeat: true
        onTriggered: {
            gameplayPage.elapsedTime++;
        }
    }

    /* ========================================================================
     * UI LAYOUT
     * ======================================================================== */

    /**
     * @brief Timer untuk polling state CAPS LOCK.
     *
     * @details Memeriksa status CAPS LOCK setiap 200ms.
     * Jika aktif, warning box akan ditampilkan.
     */
    Timer {
        id: capsLockTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: capsLockOn = GameBackend.isCapsLockOn()
    }

    /**
     * @brief Container utama untuk konten permainan.
     *
     * @details Item ini centered di parent dan berisi:
     * - Timer display
     * - Text display area
     * - CAPS LOCK warning
     * - Statistics row
     * - Navigation buttons
     * - Instruction hint
     */
    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingHuge * 2, 1000)
        height: gameCol.implicitHeight

        /// @brief Layout kolom utama
        ColumnLayout {
            id: gameCol
            anchors.fill: parent
            spacing: 0

            /**
             * @brief Baris tampilan timer.
             *
             * @details Menampilkan:
             * - Mode countdown: Waktu tersisa (biru)
             * - Mode infinity: Ikon infinity atau waktu elapsed (hijau)
             */
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 10
                spacing: Theme.spacingL

                /// @brief Waktu tersisa (mode countdown)
                Text {
                    Layout.leftMargin: 48
                    visible: gameplayPage.timeLimit > 0
                    text: gameplayPage.timeRemaining
                    color: Theme.accentBlue
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                }

                /// @brief Ikon infinity (mode infinity, elapsed = 0)
                Item {
                    Layout.leftMargin: 48
                    visible: gameplayPage.timeLimit <= 0 && gameplayPage.elapsedTime === 0
                    width: 32
                    height: 32

                    Image {
                        id: infinityIcon
                        source: "qrc:/qt/qml/rapid_texter/assets/icons/infinity.svg"
                        anchors.fill: parent
                        sourceSize: Qt.size(32, 32)
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: infinityIcon
                        source: infinityIcon
                        color: Theme.accentGreen
                    }
                }

                /// @brief Waktu elapsed (mode infinity, > 0)
                Text {
                    Layout.leftMargin: 48
                    visible: gameplayPage.timeLimit <= 0 && gameplayPage.elapsedTime > 0
                    text: gameplayPage.elapsedTime
                    color: Theme.accentGreen
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.weight: Font.DemiBold
                }

                /**
                 * @brief Warning box saat CAPS LOCK aktif.
                 * @details Menampilkan box kuning dengan teks "CAPS LOCK ON".
                 */
                Rectangle {
                    id: capsLockBox
                    visible: gameplayPage.capsLockOn
                    color: "#3D2800"
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

                /// @brief Spacer
                Item {
                    Layout.fillWidth: true
                }
            }

            /**
             * @brief Area tampilan teks target.
             *
             * @details Menampilkan teks yang harus diketik dengan:
             * - Warna berbeda untuk correct/incorrect/pending
             * - Kursor berkedip pada posisi saat ini
             * - Background merah untuk karakter salah
             * - Word-wrap yang tepat (tidak memotong kata)
             */
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: textFlow.implicitHeight + 96
                color: "transparent"

                /**
                 * @brief Flow container untuk kata-kata.
                 *
                 * @details Menggunakan Flow + Repeater untuk word-wrap:
                 * - Setiap kata adalah Row yang tidak dipotong
                 * - Spasi ditampilkan secara eksplisit antar kata
                 */
                Flow {
                    id: textFlow
                    anchors.fill: parent
                    anchors.margins: 48
                    spacing: 0

                    Repeater {
                        model: gameplayPage.wordInfo.length

                        /// @brief Row untuk setiap kata (tidak dipotong)
                        Row {
                            id: wordRow
                            spacing: 0
                            height: 48

                            property int wordIndex: index
                            property var wordData: gameplayPage.wordInfo[index]
                            property int spaceIndex: wordData.endIndex + 1

                            /// @brief Repeater untuk setiap karakter dalam kata
                            Repeater {
                                model: wordData.word.length

                                /// @brief Elemen teks untuk satu karakter
                                Text {
                                    id: charText

                                    property int globalIndex: wordData.startIndex + index
                                    property string character: wordData.word[index]
                                    // Optimized inline charState - avoids O(n) re-evaluation
                                    property string charState: {
                                        var typedLen = gameplayPage.typedChars.length;
                                        if (globalIndex < typedLen) {
                                            return gameplayPage.typedChars[globalIndex] === character ? "correct" : "incorrect";
                                        } else if (globalIndex === typedLen) {
                                            return "current";
                                        }
                                        return "pending";
                                    }

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

                                    /// @brief Background merah untuk karakter salah
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: charText.font.pixelSize + 8
                                        color: charText.charState === "incorrect" ? Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15) : "transparent"
                                        z: -1
                                    }

                                    /// @brief Kursor caret (garis vertikal biru)
                                    Rectangle {
                                        visible: charText.charState === "current"
                                        anchors.left: parent.left
                                        anchors.leftMargin: -1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 2
                                        height: charText.font.pixelSize + 6
                                        color: Theme.accentBlue
                                    }
                                }
                            }

                            /**
                             * @brief Karakter spasi setelah kata.
                             *
                             * @details Spasi ditampilkan eksplisit:
                             * - Jika salah, tampilkan karakter yang diketik (merah)
                             * - Memiliki kursor jika pada posisi saat ini
                             */
                            Text {
                                id: spaceText
                                visible: wordRow.wordIndex < gameplayPage.wordInfo.length - 1

                                property int globalIndex: wordRow.spaceIndex
                                // Optimized inline charState for space character
                                property string charState: {
                                    var typedLen = gameplayPage.typedChars.length;
                                    if (globalIndex < typedLen) {
                                        return gameplayPage.typedChars[globalIndex] === " " ? "correct" : "incorrect";
                                    } else if (globalIndex === typedLen) {
                                        return "current";
                                    }
                                    return "pending";
                                }
                                property string typedChar: globalIndex < gameplayPage.typedChars.length ? gameplayPage.typedChars[globalIndex] : ""
                                property string displayChar: charState === "incorrect" && typedChar.length > 0 ? typedChar : " "

                                text: displayChar
                                font.family: Theme.fontFamily
                                font.pixelSize: 28
                                font.letterSpacing: 0.5

                                color: charState === "incorrect" ? Theme.accentRed : Theme.textMuted

                                /// @brief Background merah untuk spasi salah
                                Rectangle {
                                    visible: spaceText.charState === "incorrect"
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 28 + 8
                                    color: Qt.rgba(248 / 255, 81 / 255, 73 / 255, 0.15)
                                    z: -1
                                }

                                /// @brief Kursor pada posisi spasi
                                Rectangle {
                                    visible: spaceText.charState === "current"
                                    anchors.left: parent.left
                                    anchors.leftMargin: -1
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2
                                    height: 28 + 6
                                    color: Theme.accentBlue
                                }
                            }
                        }
                    }
                }
            }

            /**
             * @brief Baris statistik real-time.
             *
             * @details Menampilkan counter correct dan errors
             * saat permainan sedang berlangsung.
             * Hidden sebelum game dimulai.
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                spacing: Theme.spacingXL
                visible: gameplayPage.gameStarted

                /// @brief Counter karakter benar (hijau)
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

                /// @brief Counter kesalahan (merah)
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

            /**
             * @brief Baris tombol navigasi.
             *
             * @details Berisi dua tombol:
             * - Reset (TAB): Reset game dan minta teks baru
             * - Exit (ESC): Keluar dari permainan
             */
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 40
                spacing: Theme.spacingM

                /// @brief Tombol Reset
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/refresh.svg"
                    labelText: "Reset (TAB)"
                    variant: "yellow"
                    onClicked: {
                        gameplayPage.resetGame();
                        gameplayPage.resetClicked();
                    }
                }

                /// @brief Tombol Exit
                NavBtn {
                    iconSource: "qrc:/qt/qml/rapid_texter/assets/icons/close.svg"
                    labelText: "Exit (ESC)"
                    onClicked: gameplayPage.exitClicked()
                }
            }

            /// @brief Teks petunjuk di bawah tombol
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
