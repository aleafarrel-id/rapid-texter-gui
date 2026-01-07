/**
 * @file GameBackend.cpp
 * @brief Implementation of GameBackend QObject bridge
 * @author Alea Farrel & Team
 * @date 2025
 */

#include "GameBackend.h"
#include <QSoundEffect>
#include <QStandardPaths>
#include <QDir>
#include <QQmlEngine>
#include <QJSEngine>
#include <QTimer>
#include <algorithm>

#ifdef _WIN32
#include <windows.h>
#endif

// Static instance
GameBackend* GameBackend::s_instance = nullptr;

// ============================================================================
// CONSTRUCTOR & SINGLETON
// ============================================================================

GameBackend::GameBackend(QObject *parent)
    : QObject(parent)
    , m_correctSound(nullptr)
    , m_errorSound(nullptr)
    , m_audioKeepAliveTimer(nullptr)
    , m_sfxEnabled(true)
    , m_defaultDuration(30)
{
    // Load settings from file
    loadSettings();
    
    // Initialize SFX
    initializeSfx();
    
    // Start timers for rate limiting and audio keepalive
    m_errorSoundTimer.start();
    m_lastSoundPlayedTimer.start();
    
    // Setup audio keepalive timer - prevent Windows audio device sleep
    m_audioKeepAliveTimer = new QTimer(this);
    connect(m_audioKeepAliveTimer, &QTimer::timeout, this, &GameBackend::onAudioKeepAlive);
    m_audioKeepAliveTimer->start(AUDIO_KEEPALIVE_MS);
    
    // Load word banks
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    
    // Load from Qt resources (Qt 6 QML module path format)
    m_textProvider.loadWords("id", ":/qt/qml/rapid_texter/assets/id.txt");
    m_textProvider.loadWords("en", ":/qt/qml/rapid_texter/assets/en.txt");
    m_textProvider.loadWords("prog", ":/qt/qml/rapid_texter/assets/prog.txt");
}

GameBackend::~GameBackend()
{
    if (m_audioKeepAliveTimer) {
        m_audioKeepAliveTimer->stop();
        delete m_audioKeepAliveTimer;
    }
    delete m_correctSound;
    delete m_errorSound;
}

GameBackend* GameBackend::instance()
{
    if (!s_instance) {
        s_instance = new GameBackend();
    }
    return s_instance;
}

GameBackend* GameBackend::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine);
    
    // The instance has to exist before it is used. We cannot replace it.
    Q_ASSERT(s_instance);
    
    // The engine has to have the same thread affinity as the singleton.
    Q_ASSERT(qmlEngine->thread() == s_instance->thread());
    
    // QJSEngine::ObjectOwnership::CppOwnership prevents garbage collection
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

// ============================================================================
// TEXT PROVIDER INTERFACE
// ============================================================================

QString GameBackend::getRandomText(const QString& language, const QString& difficulty, int wordCount)
{
    Difficulty diff = stringToDifficulty(difficulty);
    std::vector<std::string> words = m_textProvider.getWords(
        language.toStdString(), diff, wordCount);
    
    QString result;
    for (size_t i = 0; i < words.size(); ++i) {
        if (i > 0) result += " ";
        result += QString::fromStdString(words[i]);
    }
    return result;
}

// ============================================================================
// SFX INTERFACE
// ============================================================================

void GameBackend::initializeSfx()
{
    m_correctSound = new QSoundEffect(this);
    m_correctSound->setSource(QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/true.wav"));
    m_correctSound->setVolume(0.5);
    
    m_errorSound = new QSoundEffect(this);
    m_errorSound->setSource(QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/false.wav"));
    m_errorSound->setVolume(0.5);
}

// Reinitialize audio - recreate both QSoundEffect instances
// Call this proactively to keep Windows audio device awake
void GameBackend::reinitializeAudio()
{
    // Save current volumes
    qreal correctVol = m_correctSound ? m_correctSound->volume() : 0.5;
    qreal errorVol = m_errorSound ? m_errorSound->volume() : 0.5;
    
    // Delete old instances
    delete m_correctSound;
    delete m_errorSound;
    
    // Create new instances
    m_correctSound = new QSoundEffect(this);
    m_correctSound->setSource(QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/true.wav"));
    m_correctSound->setVolume(correctVol);
    
    m_errorSound = new QSoundEffect(this);
    m_errorSound->setSource(QUrl("qrc:/qt/qml/rapid_texter/assets/sfx/false.wav"));
    m_errorSound->setVolume(errorVol);
}

// Called periodically by timer to keep audio device awake
void GameBackend::onAudioKeepAlive()
{
    // Only reinitialize if audio hasn't been used recently
    // This prevents Windows audio device from going to sleep
    if (m_lastSoundPlayedTimer.elapsed() >= AUDIO_KEEPALIVE_MS) {
        reinitializeAudio();
        m_lastSoundPlayedTimer.restart();
    }
}

void GameBackend::playCorrectSound()
{
    if (m_sfxEnabled && m_correctSound) {
        if (m_correctSound->status() == QSoundEffect::Ready) {
            m_correctSound->play();
            m_lastSoundPlayedTimer.restart();  // Mark audio as active
        } else if (m_correctSound->status() == QSoundEffect::Error) {
            reinitializeAudio();
        }
    }
}

void GameBackend::playErrorSound()
{
    if (m_sfxEnabled && m_errorSound) {
        // Rate limiting
        if (m_errorSoundTimer.elapsed() >= SOUND_COOLDOWN_MS) {
            if (m_errorSound->status() == QSoundEffect::Ready) {
                m_errorSound->play();
                m_lastSoundPlayedTimer.restart();  // Mark audio as active
            } else if (m_errorSound->status() == QSoundEffect::Error) {
                reinitializeAudio();
            }
            m_errorSoundTimer.restart();
        }
    }
}

void GameBackend::toggleSfx()
{
    setSfxEnabled(!m_sfxEnabled);
}

bool GameBackend::isCapsLockOn() const
{
#ifdef _WIN32
    // GetKeyState returns toggle state in low-order bit (same as Terminal.cpp)
    return (GetKeyState(VK_CAPITAL) & 0x0001) != 0;
#else
    // Linux: Could implement via X11 or return false
    return false;
#endif
}

bool GameBackend::sfxEnabled() const
{
    return m_sfxEnabled;
}

void GameBackend::setSfxEnabled(bool enabled)
{
    if (m_sfxEnabled != enabled) {
        m_sfxEnabled = enabled;
        SettingsManager::setSfxEnabled(enabled);
        emit sfxEnabledChanged();
    }
}

// ============================================================================
// HISTORY INTERFACE
// ============================================================================

void GameBackend::saveGameResult(double wpm, double accuracy, int errors,
                                  int targetWPM, const QString& difficulty,
                                  const QString& language, const QString& mode,
                                  double timeElapsed)
{
    HistoryEntry entry;
    entry.wpm = wpm;
    entry.accuracy = accuracy;
    entry.errors = errors;
    entry.targetWPM = targetWPM;
    entry.timeElapsed = timeElapsed;
    // Capitalize difficulty for display (e.g., "easy" -> "Easy")
    QString capitalizedDiff = difficulty;
    if (!capitalizedDiff.isEmpty()) {
        capitalizedDiff[0] = capitalizedDiff[0].toUpper();
    }
    entry.difficulty = capitalizedDiff.toStdString();
    entry.language = language.toUpper().toStdString();
    entry.mode = mode.toStdString();
    // timestamp is set automatically by HistoryManager
    
    m_historyManager.saveEntry(entry);
    emit historyUpdated();
}

QVariantList GameBackend::getHistoryPage(int pageNumber, int pageSize)
{
    QVariantList result;
    std::vector<HistoryEntry> entries = m_historyManager.getPage(pageNumber, pageSize);
    
    for (const auto& entry : entries) {
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

QVariantList GameBackend::getHistoryPageSorted(int pageNumber, int pageSize, const QString& sortBy, bool ascending, const QString& modeFilter, const QString& languageFilter, const QString& difficultyFilter)
{
    // Get all entries first, then filter, sort, then paginate
    int totalEntries = m_historyManager.getTotalEntries();
    if (totalEntries == 0) {
        return QVariantList();
    }
    
    // Get all entries (use a large page to get all)
    int allPageSize = totalEntries;
    std::vector<HistoryEntry> allEntries = m_historyManager.getPage(1, allPageSize);
    
    // Filter by mode, language, and difficulty
    std::vector<HistoryEntry> filteredEntries;
    for (const auto& entry : allEntries) {
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
    
    // Sort based on sortBy and ascending
    if (sortBy == "wpm") {
        std::sort(filteredEntries.begin(), filteredEntries.end(),
            [ascending](const HistoryEntry& a, const HistoryEntry& b) {
                return ascending ? (a.wpm < b.wpm) : (a.wpm > b.wpm);
            });
    } else if (sortBy == "accuracy") {
        std::sort(filteredEntries.begin(), filteredEntries.end(),
            [ascending](const HistoryEntry& a, const HistoryEntry& b) {
                return ascending ? (a.accuracy < b.accuracy) : (a.accuracy > b.accuracy);
            });
    } else if (sortBy == "time") {
        std::sort(filteredEntries.begin(), filteredEntries.end(),
            [ascending](const HistoryEntry& a, const HistoryEntry& b) {
                return ascending ? (a.timeElapsed < b.timeElapsed) : (a.timeElapsed > b.timeElapsed);
            });
    } else {
        // Sort by date (timestamp) - default
        // Timestamp format: DD/MM/YYYY HH:MM:SS
        // For proper date comparison, we need to parse it
        std::sort(filteredEntries.begin(), filteredEntries.end(),
            [ascending](const HistoryEntry& a, const HistoryEntry& b) {
                // Parse timestamps for comparison
                // Format: DD/MM/YYYY HH:MM:SS
                auto parseTimestamp = [](const std::string& ts) -> long long {
                    if (ts.length() < 19) return 0;
                    int day = std::stoi(ts.substr(0, 2));
                    int month = std::stoi(ts.substr(3, 2));
                    int year = std::stoi(ts.substr(6, 4));
                    int hour = std::stoi(ts.substr(11, 2));
                    int minute = std::stoi(ts.substr(14, 2));
                    int second = std::stoi(ts.substr(17, 2));
                    // Convert to comparable number (YYYYMMDDHHmmss)
                    return (long long)year * 10000000000LL + 
                           (long long)month * 100000000LL + 
                           (long long)day * 1000000LL + 
                           (long long)hour * 10000LL + 
                           (long long)minute * 100LL + 
                           (long long)second;
                };
                long long timeA = parseTimestamp(a.timestamp);
                long long timeB = parseTimestamp(b.timestamp);
                return ascending ? (timeA < timeB) : (timeA > timeB);
            });
    }
    
    // Paginate
    int startIdx = (pageNumber - 1) * pageSize;
    int endIdx = std::min(startIdx + pageSize, (int)filteredEntries.size());
    
    QVariantList result;
    for (int i = startIdx; i < endIdx; ++i) {
        const auto& entry = filteredEntries[i];
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

int GameBackend::getHistoryTotalPages(int pageSize)
{
    return m_historyManager.getTotalPages(pageSize);
}

int GameBackend::getHistoryTotalEntries()
{
    return m_historyManager.getTotalEntries();
}

void GameBackend::clearHistory()
{
    m_historyManager.clearHistory();
    emit historyUpdated();
}

// ============================================================================
// PROGRESS INTERFACE
// ============================================================================

bool GameBackend::isLevelUnlocked(const QString& language, const QString& difficulty)
{
    return m_progressManager.isUnlocked(language.toLower().toStdString(), 
                                         stringToDifficulty(difficulty));
}

bool GameBackend::isLevelCompleted(const QString& language, const QString& difficulty)
{
    return m_progressManager.isCompleted(language.toLower().toStdString(),
                                          stringToDifficulty(difficulty));
}

bool GameBackend::completeLevel(const QString& language, const QString& difficulty,
                                 double wpm, double accuracy)
{
    std::string lang = language.toLower().toStdString();
    Difficulty diff = stringToDifficulty(difficulty);
    
    // Check if player passed the requirements
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

void GameBackend::resetProgress()
{
    m_progressManager.resetProgress();
    emit progressUpdated();
}

bool GameBackend::wasHardCompletedBefore(const QString& language)
{
    return m_progressManager.wasHardCompletedBefore(language.toLower().toStdString());
}

// ============================================================================
// SETTINGS INTERFACE
// ============================================================================

int GameBackend::defaultDuration() const
{
    return m_defaultDuration;
}

void GameBackend::setDefaultDuration(int duration)
{
    if (m_defaultDuration != duration) {
        m_defaultDuration = duration;
        SettingsManager::setDefaultDuration(duration);
        emit defaultDurationChanged();
    }
}

QString GameBackend::historySortBy() const
{
    return QString::fromStdString(SettingsManager::getHistorySortBy());
}

void GameBackend::setHistorySortBy(const QString& sortBy)
{
    QString current = QString::fromStdString(SettingsManager::getHistorySortBy());
    if (current != sortBy) {
        SettingsManager::setHistorySortBy(sortBy.toStdString());
        emit historySortByChanged();
    }
}

bool GameBackend::historySortAscending() const
{
    return SettingsManager::getHistorySortAscending();
}

void GameBackend::setHistorySortAscending(bool ascending)
{
    if (SettingsManager::getHistorySortAscending() != ascending) {
        SettingsManager::setHistorySortAscending(ascending);
        emit historySortAscendingChanged();
    }
}

void GameBackend::loadSettings()
{
    SettingsManager::load();
    m_sfxEnabled = SettingsManager::getSfxEnabled();
    m_defaultDuration = SettingsManager::getDefaultDuration();
}

// ============================================================================
// HELPER METHODS
// ============================================================================

Difficulty GameBackend::stringToDifficulty(const QString& diff)
{
    QString lower = diff.toLower();
    if (lower == "easy") return Difficulty::EASY;
    if (lower == "medium") return Difficulty::MEDIUM;
    if (lower == "hard") return Difficulty::HARD;
    if (lower == "programmer") return Difficulty::PROGRAMMER;
    return Difficulty::EASY; // default
}
