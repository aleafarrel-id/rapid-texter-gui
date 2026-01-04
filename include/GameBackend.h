/**
 * @file GameBackend.h
 * @brief Qt QObject bridge untuk game logic Rapid Texter
 * @author Alea Farrel & Team
 * @date 2025
 *
 * GameBackend menyediakan interface antara QML dan C++ game logic.
 * Semua fungsi yang diperlukan QML diekspos melalui Q_INVOKABLE.
 */

#ifndef GAMEBACKEND_H
#define GAMEBACKEND_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QQmlEngine>
#include <QJSEngine>
#include <memory>

#include "TextProvider.h"
#include "HistoryManager.h"
#include "ProgressManager.h"
#include "SettingsManager.h"

// Forward declare for SFX
class QSoundEffect;

/**
 * @class GameBackend
 * @brief Singleton QObject yang menjembatani QML dengan C++ game logic
 *
 * GameBackend menyediakan:
 * - Text provider untuk kata-kata acak
 * - Sound effects manager
 * - History manager untuk menyimpan hasil game
 * - Progress manager untuk campaign
 * - Settings manager untuk pengaturan user
 */
class GameBackend : public QObject
{
    Q_OBJECT
    
    // Properties untuk QML binding
    Q_PROPERTY(bool sfxEnabled READ sfxEnabled WRITE setSfxEnabled NOTIFY sfxEnabledChanged)
    Q_PROPERTY(int defaultDuration READ defaultDuration WRITE setDefaultDuration NOTIFY defaultDurationChanged)

public:
    /**
     * @brief Get singleton instance
     */
    static GameBackend* instance();
    
    /**
     * @brief Create singleton instance dengan QML engine sebagai parent
     */
    static GameBackend* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    // ========================================================================
    // TEXT PROVIDER INTERFACE
    // ========================================================================

    /**
     * @brief Mendapatkan teks acak untuk gameplay
     * @param language Bahasa ("id", "en", "prog")
     * @param difficulty Difficulty ("easy", "medium", "hard", "programmer")
     * @param wordCount Jumlah kata yang diinginkan
     * @return String teks yang akan diketik
     */
    Q_INVOKABLE QString getRandomText(const QString& language, const QString& difficulty, int wordCount);

    // ========================================================================
    // SFX INTERFACE
    // ========================================================================

    /**
     * @brief Play sound untuk keystroke benar
     */
    Q_INVOKABLE void playCorrectSound();

    /**
     * @brief Play sound untuk keystroke salah
     */
    Q_INVOKABLE void playErrorSound();

    /**
     * @brief Toggle SFX on/off
     */
    Q_INVOKABLE void toggleSfx();

    /**
     * @brief Check if CAPS LOCK is currently active
     * @return true if CAPS LOCK is on, false otherwise
     */
    Q_INVOKABLE bool isCapsLockOn() const;

    /**
     * @brief Cek apakah SFX enabled
     */
    bool sfxEnabled() const;

    /**
     * @brief Set SFX enabled status
     */
    void setSfxEnabled(bool enabled);

    // ========================================================================
    // HISTORY INTERFACE
    // ========================================================================

    /**
     * @brief Simpan hasil game ke history
     * @param wpm Words per minute
     * @param accuracy Akurasi (0-100)
     * @param errors Jumlah error
     * @param targetWPM Target WPM
     * @param difficulty Difficulty level
     * @param language Bahasa yang digunakan
     * @param mode Mode permainan (Manual/Campaign)
     */
    Q_INVOKABLE void saveGameResult(double wpm, double accuracy, int errors,
                                     int targetWPM, const QString& difficulty,
                                     const QString& language, const QString& mode);

    /**
     * @brief Mendapatkan halaman history
     * @param pageNumber Nomor halaman (1-based)
     * @param pageSize Jumlah entry per halaman
     * @return List of history entries sebagai QVariantList
     */
    Q_INVOKABLE QVariantList getHistoryPage(int pageNumber, int pageSize = 5);

    /**
     * @brief Mendapatkan total halaman history
     */
    Q_INVOKABLE int getHistoryTotalPages(int pageSize = 5);

    /**
     * @brief Mendapatkan total jumlah entry history
     */
    Q_INVOKABLE int getHistoryTotalEntries();

    /**
     * @brief Menghapus semua history
     */
    Q_INVOKABLE void clearHistory();

    // ========================================================================
    // PROGRESS INTERFACE
    // ========================================================================

    /**
     * @brief Cek apakah level sudah unlocked
     * @param language Bahasa
     * @param difficulty Difficulty level
     * @return true jika unlocked
     */
    Q_INVOKABLE bool isLevelUnlocked(const QString& language, const QString& difficulty);

    /**
     * @brief Cek apakah level sudah completed
     * @param language Bahasa
     * @param difficulty Difficulty level
     * @return true jika completed
     */
    Q_INVOKABLE bool isLevelCompleted(const QString& language, const QString& difficulty);

    /**
     * @brief Update progress setelah menyelesaikan level
     * @param language Bahasa
     * @param difficulty Difficulty yang diselesaikan
     * @param wpm WPM yang dicapai
     * @param accuracy Accuracy yang dicapai
     * @return true jika berhasil pass level requirements
     */
    Q_INVOKABLE bool completeLevel(const QString& language, const QString& difficulty,
                                    double wpm, double accuracy);

    /**
     * @brief Reset semua progress
     */
    Q_INVOKABLE void resetProgress();

    // ========================================================================
    // SETTINGS INTERFACE
    // ========================================================================

    /**
     * @brief Get default duration
     */
    int defaultDuration() const;

    /**
     * @brief Set default duration
     */
    void setDefaultDuration(int duration);

signals:
    void sfxEnabledChanged();
    void defaultDurationChanged();
    void progressUpdated();
    void historyUpdated();

private:
    explicit GameBackend(QObject *parent = nullptr);
    ~GameBackend();

    // Singleton instance
    static GameBackend* s_instance;

    // Managers
    TextProvider m_textProvider;
    HistoryManager m_historyManager;
    ProgressManager m_progressManager;

    // SFX
    QSoundEffect* m_correctSound;
    QSoundEffect* m_errorSound;
    bool m_sfxEnabled;

    // Settings
    int m_defaultDuration;

    // Helper methods
    Difficulty stringToDifficulty(const QString& diff);
    void initializeSfx();
    void loadSettings();
};

#endif // GAMEBACKEND_H
