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
    , m_sfxEnabled(true)
    , m_defaultDuration(30)
{
    // Load settings from file
    loadSettings();
    
    // Initialize SFX
    initializeSfx();
    
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

void GameBackend::playCorrectSound()
{
    if (m_sfxEnabled && m_correctSound) {
        m_correctSound->play();
    }
}

void GameBackend::playErrorSound()
{
    if (m_sfxEnabled && m_errorSound) {
        m_errorSound->play();
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
                                  const QString& language, const QString& mode)
{
    HistoryEntry entry;
    entry.wpm = wpm;
    entry.accuracy = accuracy;
    entry.errors = errors;
    entry.targetWPM = targetWPM;
    entry.difficulty = difficulty.toStdString();
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
