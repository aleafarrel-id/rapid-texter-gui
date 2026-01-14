/**
 * @file GameBackend.cpp
 * @brief Implementasi GameBackend QObject bridge.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details File ini berisi implementasi dari semua method GameBackend
 * termasuk text generation, SFX, history, progress tracking, dan settings.
 */

#include "GameBackend.h"
#include <QDir>
#include <QFile>
#include <QJSEngine>
#include <QQmlEngine>
#include <QSoundEffect>
#include <QStandardPaths>
#include <QTimer>
#include <algorithm>

#ifdef _WIN32
#include <windows.h>
#endif

/// Singleton instance pointer
GameBackend *GameBackend::s_instance = nullptr;

// ============================================================================
// CONSTRUCTOR & SINGLETON
// ============================================================================

/**
 * @brief Constructor GameBackend.
 * @param parent Parent QObject.
 *
 * @details Inisialisasi meliputi:
 * 1. Load settings dari disk
 * 2. Inisialisasi SFX (correct dan error sounds)
 * 3. Setup timer untuk rate limiting dan audio keepalive
 * 4. Load word banks untuk semua bahasa dari Qt resources
 */
GameBackend::GameBackend(QObject *parent)
    : QObject(parent), m_correctSound(nullptr), m_errorSound(nullptr),
      m_audioKeepAliveTimer(nullptr), m_sfxEnabled(true), m_defaultDuration(30),
      m_playerName("") {
  // Load settings dari file
  loadSettings();

  // Inisialisasi SFX
  initializeSfx();

  // Start timer untuk rate limiting dan audio keepalive
  m_errorSoundTimer.start();
  m_lastSoundPlayedTimer.start();

  // Setup audio keepalive timer - mencegah Windows audio device sleep
  m_audioKeepAliveTimer = new QTimer(this);
  connect(m_audioKeepAliveTimer, &QTimer::timeout, this,
          &GameBackend::onAudioKeepAlive);
  m_audioKeepAliveTimer->start(AUDIO_KEEPALIVE_MS);

  // Load word banks dari Qt resources
  QString dataPath =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir().mkpath(dataPath);

  // Load dari Qt resources (format path Qt 6 QML module)
  m_textProvider.loadWords("id", ":/qt/qml/rapid_texter/assets/id.txt");
  m_textProvider.loadWords("en", ":/qt/qml/rapid_texter/assets/en.txt");
  m_textProvider.loadWords("prog", ":/qt/qml/rapid_texter/assets/prog.txt");
}

/**
 * @brief Destructor GameBackend.
 * @details Membersihkan timer dan sound effects.
 */
GameBackend::~GameBackend() {
  if (m_audioKeepAliveTimer) {
    m_audioKeepAliveTimer->stop();
    delete m_audioKeepAliveTimer;
  }
  delete m_correctSound;
  delete m_errorSound;
}

/**
 * @brief Mendapatkan singleton instance.
 * @return Pointer ke instance GameBackend.
 */
GameBackend *GameBackend::instance() {
  if (!s_instance) {
    s_instance = new GameBackend();
  }
  return s_instance;
}

/**
 * @brief Factory method untuk QML singleton.
 * @param qmlEngine Pointer ke QQmlEngine.
 * @param jsEngine Pointer ke QJSEngine.
 * @return Pointer ke instance GameBackend.
 *
 * @note Instance harus sudah ada sebelum dipanggil.
 * Mengatur CppOwnership untuk mencegah garbage collection.
 */
GameBackend *GameBackend::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
  Q_UNUSED(jsEngine);

  Q_ASSERT(s_instance);
  Q_ASSERT(qmlEngine->thread() == s_instance->thread());

  QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
  return s_instance;
}

// ============================================================================
// TEXT PROVIDER INTERFACE
// ============================================================================

/**
 * @brief Mendapatkan teks acak untuk gameplay.
 * @param language Bahasa ("id", "en", "prog").
 * @param difficulty Kesulitan ("easy", "medium", "hard", "programmer").
 * @param wordCount Jumlah kata yang diinginkan.
 * @return QString berisi teks dengan kata-kata dipisahkan spasi.
 */
QString GameBackend::getRandomText(const QString &language,
                                   const QString &difficulty, int wordCount) {
  Difficulty diff = stringToDifficulty(difficulty);
  std::vector<std::string> words =
      m_textProvider.getWords(language.toStdString(), diff, wordCount);

  QString result;
  for (size_t i = 0; i < words.size(); ++i) {
    if (i > 0)
      result += " ";
    result += QString::fromStdString(words[i]);
  }
  return result;
}

// ============================================================================
// SFX INTERFACE
// ============================================================================

/**
 * @brief Inisialisasi sound effects.
 * @details Membuat QSoundEffect untuk suara benar dan salah
 * dengan volume 50%.
 */
void GameBackend::initializeSfx() {
  m_correctSound = new QSoundEffect(this);
  m_correctSound->setSource(
      QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/true.wav"));
  m_correctSound->setVolume(0.5);

  m_errorSound = new QSoundEffect(this);
  m_errorSound->setSource(
      QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/false.wav"));
  m_errorSound->setVolume(0.5);
}

/**
 * @brief Reinisialisasi audio.
 * @details Membuat ulang kedua QSoundEffect instances untuk
 * mencegah Windows audio device sleep issue.
 */
void GameBackend::reinitializeAudio() {
  qreal correctVol = m_correctSound ? m_correctSound->volume() : 0.5;
  qreal errorVol = m_errorSound ? m_errorSound->volume() : 0.5;

  delete m_correctSound;
  delete m_errorSound;

  m_correctSound = new QSoundEffect(this);
  m_correctSound->setSource(
      QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/true.wav"));
  m_correctSound->setVolume(correctVol);

  m_errorSound = new QSoundEffect(this);
  m_errorSound->setSource(
      QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/false.wav"));
  m_errorSound->setVolume(errorVol);
}

/**
 * @brief Handler timer keepalive audio.
 * @details Dipanggil periodik untuk reinisialisasi audio
 * jika belum digunakan dalam waktu tertentu.
 */
void GameBackend::onAudioKeepAlive() {
  if (m_lastSoundPlayedTimer.elapsed() >= AUDIO_KEEPALIVE_MS) {
    reinitializeAudio();
    m_lastSoundPlayedTimer.restart();
  }
}

/**
 * @brief Memutar sound effect untuk keystroke benar.
 */
void GameBackend::playCorrectSound() {
  if (m_sfxEnabled && m_correctSound) {
    if (m_correctSound->status() == QSoundEffect::Ready) {
      m_correctSound->play();
      m_lastSoundPlayedTimer.restart();
    } else if (m_correctSound->status() == QSoundEffect::Error) {
      reinitializeAudio();
    }
  }
}

/**
 * @brief Memutar sound effect untuk keystroke salah.
 * @details Memiliki rate limiting 80ms untuk mencegah overload.
 */
void GameBackend::playErrorSound() {
  if (m_sfxEnabled && m_errorSound) {
    if (m_errorSoundTimer.elapsed() >= SOUND_COOLDOWN_MS) {
      if (m_errorSound->status() == QSoundEffect::Ready) {
        m_errorSound->play();
        m_lastSoundPlayedTimer.restart();
      } else if (m_errorSound->status() == QSoundEffect::Error) {
        reinitializeAudio();
      }
      m_errorSoundTimer.restart();
    }
  }
}

/**
 * @brief Toggle SFX on/off.
 */
void GameBackend::toggleSfx() { setSfxEnabled(!m_sfxEnabled); }

/**
 * @brief Mengecek status CAPS LOCK.
 * @return true jika CAPS LOCK aktif.
 */
bool GameBackend::isCapsLockOn() const {
#ifdef _WIN32
  return (GetKeyState(VK_CAPITAL) & 0x0001) != 0;
#else
  // Linux: Cek /sys/class/leds/input*::capslock/brightness
  for (int i = 0; i <= 9; ++i) {
    QString path =
        QString("/sys/class/leds/input%1::capslock/brightness").arg(i);
    QFile file(path);
    if (file.exists() && file.open(QIODevice::ReadOnly | QIODevice::Text)) {
      QByteArray data = file.readAll().trimmed();
      file.close();
      return (data == "1");
    }
  }
  return false;
#endif
}

/**
 * @brief Mendapatkan status SFX.
 * @return true jika SFX enabled.
 */
bool GameBackend::sfxEnabled() const { return m_sfxEnabled; }

/**
 * @brief Mengatur status SFX.
 * @param enabled true untuk mengaktifkan SFX.
 */
void GameBackend::setSfxEnabled(bool enabled) {
  if (m_sfxEnabled != enabled) {
    m_sfxEnabled = enabled;
    SettingsManager::setSfxEnabled(enabled);
    emit sfxEnabledChanged();
  }
}

// ============================================================================
// HISTORY INTERFACE
// ============================================================================

/**
 * @brief Menyimpan hasil game ke history.
 * @param wpm Words per minute.
 * @param accuracy Akurasi (0-100).
 * @param errors Jumlah error.
 * @param targetWPM Target WPM.
 * @param difficulty Difficulty level.
 * @param language Bahasa.
 * @param mode Mode permainan.
 * @param timeElapsed Durasi permainan (detik).
 */
void GameBackend::saveGameResult(double wpm, double accuracy, int errors,
                                 int targetWPM, const QString &difficulty,
                                 const QString &language, const QString &mode,
                                 double timeElapsed) {
  HistoryEntry entry;
  entry.wpm = wpm;
  entry.accuracy = accuracy;
  entry.errors = errors;
  entry.targetWPM = targetWPM;
  entry.timeElapsed = timeElapsed;
  
  // Capitalize difficulty untuk display
  QString capitalizedDiff = difficulty;
  if (!capitalizedDiff.isEmpty()) {
    capitalizedDiff[0] = capitalizedDiff[0].toUpper();
  }
  entry.difficulty = capitalizedDiff.toStdString();
  entry.language = language.toUpper().toStdString();
  entry.mode = mode.toStdString();

  m_historyManager.saveEntry(entry);
  emit historyUpdated();
}

/**
 * @brief Mendapatkan halaman history.
 * @param pageNumber Nomor halaman (1-based).
 * @param pageSize Ukuran halaman.
 * @return QVariantList berisi entry history.
 */
QVariantList GameBackend::getHistoryPage(int pageNumber, int pageSize) {
  QVariantList result;
  std::vector<HistoryEntry> entries =
      m_historyManager.getPage(pageNumber, pageSize);

  for (const auto &entry : entries) {
    QVariantMap item;
    item["wpm"] = entry.wpm;
    item["accuracy"] = entry.accuracy;
    item["errors"] = entry.errors;
    item["targetWPM"] = entry.targetWPM;
    item["difficulty"] = QString::fromStdString(entry.difficulty);
    item["language"] = QString::fromStdString(entry.language);
    item["mode"] = QString::fromStdString(entry.mode);
    item["timestamp"] = QString::fromStdString(entry.timestamp);
    item["timeElapsed"] = entry.timeElapsed;
    result.append(item);
  }

  return result;
}

/**
 * @brief Mendapatkan halaman history dengan sorting dan filtering.
 * @param pageNumber Nomor halaman.
 * @param pageSize Ukuran halaman.
 * @param sortBy Field sorting.
 * @param ascending Arah sorting.
 * @param modeFilter Filter mode.
 * @param languageFilter Filter bahasa.
 * @param difficultyFilter Filter difficulty.
 * @return QVariantList berisi entry history yang sudah diproses.
 */
QVariantList GameBackend::getHistoryPageSorted(
    int pageNumber, int pageSize, const QString &sortBy, bool ascending,
    const QString &modeFilter, const QString &languageFilter,
    const QString &difficultyFilter) {
  int totalEntries = m_historyManager.getTotalEntries();
  if (totalEntries == 0) {
    return QVariantList();
  }

  // Ambil semua entries untuk filtering dan sorting
  int allPageSize = totalEntries;
  std::vector<HistoryEntry> allEntries =
      m_historyManager.getPage(1, allPageSize);

  // Apply filters
  std::vector<HistoryEntry> filteredEntries;
  for (const auto &entry : allEntries) {
    // Mode filter
    if (modeFilter != "All" && !modeFilter.isEmpty()) {
      if (entry.mode != modeFilter.toStdString()) {
        continue;
      }
    }

    // Language filter (case-insensitive)
    if (languageFilter != "All" && !languageFilter.isEmpty()) {
      QString entryLang = QString::fromStdString(entry.language).toUpper();
      if (entryLang != languageFilter.toUpper()) {
        continue;
      }
    }

    // Difficulty filter (case-insensitive)
    if (difficultyFilter != "All" && !difficultyFilter.isEmpty()) {
      QString entryDiff = QString::fromStdString(entry.difficulty).toLower();
      if (entryDiff != difficultyFilter.toLower()) {
        continue;
      }
    }

    filteredEntries.push_back(entry);
  }

  if (filteredEntries.empty()) {
    return QVariantList();
  }

  // Apply sorting
  if (sortBy == "wpm") {
    std::sort(filteredEntries.begin(), filteredEntries.end(),
              [ascending](const HistoryEntry &a, const HistoryEntry &b) {
                return ascending ? (a.wpm < b.wpm) : (a.wpm > b.wpm);
              });
  } else if (sortBy == "accuracy") {
    std::sort(filteredEntries.begin(), filteredEntries.end(),
              [ascending](const HistoryEntry &a, const HistoryEntry &b) {
                return ascending ? (a.accuracy < b.accuracy)
                                 : (a.accuracy > b.accuracy);
              });
  } else if (sortBy == "time") {
    std::sort(filteredEntries.begin(), filteredEntries.end(),
              [ascending](const HistoryEntry &a, const HistoryEntry &b) {
                return ascending ? (a.timeElapsed < b.timeElapsed)
                                 : (a.timeElapsed > b.timeElapsed);
              });
  } else {
    // Default: Sort by date (timestamp format: DD/MM/YYYY HH:MM:SS)
    std::sort(filteredEntries.begin(), filteredEntries.end(),
              [ascending](const HistoryEntry &a, const HistoryEntry &b) {
                auto parseTimestamp = [](const std::string &ts) -> long long {
                  if (ts.length() < 19)
                    return 0;
                  int day = std::stoi(ts.substr(0, 2));
                  int month = std::stoi(ts.substr(3, 2));
                  int year = std::stoi(ts.substr(6, 4));
                  int hour = std::stoi(ts.substr(11, 2));
                  int minute = std::stoi(ts.substr(14, 2));
                  int second = std::stoi(ts.substr(17, 2));
                  return (long long)year * 10000000000LL +
                         (long long)month * 100000000LL +
                         (long long)day * 1000000LL +
                         (long long)hour * 10000LL + (long long)minute * 100LL +
                         (long long)second;
                };
                long long timeA = parseTimestamp(a.timestamp);
                long long timeB = parseTimestamp(b.timestamp);
                return ascending ? (timeA < timeB) : (timeA > timeB);
              });
  }

  // Paginate hasil
  int startIdx = (pageNumber - 1) * pageSize;
  int endIdx = std::min(startIdx + pageSize, (int)filteredEntries.size());

  QVariantList result;
  for (int i = startIdx; i < endIdx; ++i) {
    const auto &entry = filteredEntries[i];
    QVariantMap item;
    item["wpm"] = entry.wpm;
    item["accuracy"] = entry.accuracy;
    item["errors"] = entry.errors;
    item["targetWPM"] = entry.targetWPM;
    item["difficulty"] = QString::fromStdString(entry.difficulty);
    item["language"] = QString::fromStdString(entry.language);
    item["mode"] = QString::fromStdString(entry.mode);
    item["timestamp"] = QString::fromStdString(entry.timestamp);
    item["timeElapsed"] = entry.timeElapsed;
    result.append(item);
  }

  return result;
}

/**
 * @brief Mendapatkan total halaman history.
 * @param pageSize Ukuran halaman.
 * @return Jumlah halaman.
 */
int GameBackend::getHistoryTotalPages(int pageSize) {
  return m_historyManager.getTotalPages(pageSize);
}

/**
 * @brief Mendapatkan total entry history.
 * @return Jumlah entry.
 */
int GameBackend::getHistoryTotalEntries() {
  return m_historyManager.getTotalEntries();
}

/**
 * @brief Menghapus semua history.
 */
void GameBackend::clearHistory() {
  m_historyManager.clearHistory();
  emit historyUpdated();
}

// ============================================================================
// PROGRESS INTERFACE
// ============================================================================

/**
 * @brief Mengecek apakah level unlocked.
 * @param language Bahasa.
 * @param difficulty Difficulty.
 * @return true jika unlocked.
 */
bool GameBackend::isLevelUnlocked(const QString &language,
                                  const QString &difficulty) {
  return m_progressManager.isUnlocked(language.toLower().toStdString(),
                                      stringToDifficulty(difficulty));
}

/**
 * @brief Mengecek apakah level completed.
 * @param language Bahasa.
 * @param difficulty Difficulty.
 * @return true jika completed.
 */
bool GameBackend::isLevelCompleted(const QString &language,
                                   const QString &difficulty) {
  return m_progressManager.isCompleted(language.toLower().toStdString(),
                                       stringToDifficulty(difficulty));
}

/**
 * @brief Menyelesaikan level dan update progress.
 * @param language Bahasa.
 * @param difficulty Difficulty.
 * @param wpm WPM yang dicapai.
 * @param accuracy Akurasi yang dicapai.
 * @return true jika memenuhi requirement.
 *
 * @details Requirements:
 * - Easy: WPM >= 40, Accuracy >= 80%
 * - Medium: WPM >= 60, Accuracy >= 90%
 * - Hard: WPM >= 70, Accuracy >= 90%
 * - Programmer: WPM >= 50, Accuracy >= 90%
 */
bool GameBackend::completeLevel(const QString &language,
                                const QString &difficulty, double wpm,
                                double accuracy) {
  std::string lang = language.toLower().toStdString();
  Difficulty diff = stringToDifficulty(difficulty);

  bool passed = false;
  int requiredWPM = 0;
  int requiredAccuracy = 0;

  switch (diff) {
  case Difficulty::EASY:
    requiredWPM = 40;
    requiredAccuracy = 80;
    break;
  case Difficulty::MEDIUM:
    requiredWPM = 60;
    requiredAccuracy = 90;
    break;
  case Difficulty::HARD:
    requiredWPM = 70;
    requiredAccuracy = 90;
    break;
  case Difficulty::PROGRAMMER:
    requiredWPM = 50;
    requiredAccuracy = 90;
    break;
  }

  if (wpm >= requiredWPM && accuracy >= requiredAccuracy) {
    passed = true;
    m_progressManager.setCompleted(lang, diff, true);

    // Unlock next level
    switch (diff) {
    case Difficulty::EASY:
      m_progressManager.setUnlocked(lang, Difficulty::MEDIUM, true);
      break;
    case Difficulty::MEDIUM:
      m_progressManager.setUnlocked(lang, Difficulty::HARD, true);
      break;
    case Difficulty::HARD:
      m_progressManager.markHardCompleted(lang);
      break;
    default:
      break;
    }

    m_progressManager.saveProgress();
    emit progressUpdated();
  }

  return passed;
}

/**
 * @brief Reset semua progress campaign.
 */
void GameBackend::resetProgress() {
  m_progressManager.resetProgress();
  emit progressUpdated();
}

/**
 * @brief Mengecek apakah Hard pernah diselesaikan sebelumnya.
 * @param language Bahasa.
 * @return true jika pernah completed.
 */
bool GameBackend::wasHardCompletedBefore(const QString &language) {
  return m_progressManager.wasHardCompletedBefore(
      language.toLower().toStdString());
}

// ============================================================================
// SETTINGS INTERFACE
// ============================================================================

/**
 * @brief Mendapatkan durasi default.
 * @return Durasi dalam detik.
 */
int GameBackend::defaultDuration() const { return m_defaultDuration; }

/**
 * @brief Mengatur durasi default.
 * @param duration Durasi dalam detik.
 */
void GameBackend::setDefaultDuration(int duration) {
  if (m_defaultDuration != duration) {
    m_defaultDuration = duration;
    SettingsManager::setDefaultDuration(duration);
    emit defaultDurationChanged();
  }
}

/**
 * @brief Mendapatkan field sorting history.
 * @return Field name.
 */
QString GameBackend::historySortBy() const {
  return QString::fromStdString(SettingsManager::getHistorySortBy());
}

/**
 * @brief Mengatur field sorting history.
 * @param sortBy Field name.
 */
void GameBackend::setHistorySortBy(const QString &sortBy) {
  QString current = QString::fromStdString(SettingsManager::getHistorySortBy());
  if (current != sortBy) {
    SettingsManager::setHistorySortBy(sortBy.toStdString());
    emit historySortByChanged();
  }
}

/**
 * @brief Mendapatkan arah sorting history.
 * @return true jika ascending.
 */
bool GameBackend::historySortAscending() const {
  return SettingsManager::getHistorySortAscending();
}

/**
 * @brief Mengatur arah sorting history.
 * @param ascending Arah sorting.
 */
void GameBackend::setHistorySortAscending(bool ascending) {
  if (SettingsManager::getHistorySortAscending() != ascending) {
    SettingsManager::setHistorySortAscending(ascending);
    emit historySortAscendingChanged();
  }
}

/**
 * @brief Mendapatkan nama pemain.
 * @return Nama pemain.
 */
QString GameBackend::playerName() const {
  return QString::fromStdString(SettingsManager::getPlayerName());
}

/**
 * @brief Mengatur nama pemain.
 * @param name Nama baru.
 */
void GameBackend::setPlayerName(const QString &name) {
  QString current = QString::fromStdString(SettingsManager::getPlayerName());
  if (current != name) {
    SettingsManager::setPlayerName(name.toStdString());
    m_playerName = name;
    emit playerNameChanged();
  }
}

/**
 * @brief Memuat settings dari disk.
 */
void GameBackend::loadSettings() {
  SettingsManager::load();
  m_sfxEnabled = SettingsManager::getSfxEnabled();
  m_defaultDuration = SettingsManager::getDefaultDuration();
  m_playerName = QString::fromStdString(SettingsManager::getPlayerName());
}

// ============================================================================
// HELPER METHODS
// ============================================================================

/**
 * @brief Mengkonversi string difficulty ke enum.
 * @param diff String difficulty.
 * @return Enum Difficulty.
 */
Difficulty GameBackend::stringToDifficulty(const QString &diff) {
  QString lower = diff.toLower();
  if (lower == "easy")
    return Difficulty::EASY;
  if (lower == "medium")
    return Difficulty::MEDIUM;
  if (lower == "hard")
    return Difficulty::HARD;
  if (lower == "programmer")
    return Difficulty::PROGRAMMER;
  return Difficulty::EASY;
}
