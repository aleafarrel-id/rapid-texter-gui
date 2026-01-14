/**
 * @file GameBackend.h
 * @brief Qt QObject bridge untuk game logic Rapid Texter.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details GameBackend menyediakan interface antara QML dan C++ game logic.
 * Semua fungsi yang diperlukan QML diekspos melalui Q_INVOKABLE.
 * Kelas ini bertindak sebagai fasad yang mengintegrasikan berbagai manager:
 * - TextProvider: Menghasilkan teks random untuk gameplay
 * - HistoryManager: Menyimpan hasil permainan
 * - ProgressManager: Melacak progress campaign
 * - SettingsManager: Mengelola pengaturan user
 *
 * @section sfx Sound Effects
 * GameBackend mengelola sound effects untuk feedback mengetik:
 * - Suara benar saat mengetik karakter yang tepat
 * - Suara salah saat mengetik karakter yang salah
 * - Rate limiting untuk mencegah audio overload
 */

#ifndef GAMEBACKEND_H
#define GAMEBACKEND_H

#include <QElapsedTimer>
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <memory>

#include "HistoryManager.h"
#include "ProgressManager.h"
#include "SettingsManager.h"
#include "TextProvider.h"

// Forward declarations
class QSoundEffect;
class QTimer;

/**
 * @class GameBackend
 * @brief Singleton QObject yang menjembatani QML dengan C++ game logic.
 *
 * @details GameBackend adalah komponen sentral yang menyediakan:
 * - Text provider untuk kata-kata acak berdasarkan bahasa dan difficulty
 * - Sound effects manager dengan rate limiting
 * - History manager untuk menyimpan hasil game ke disk
 * - Progress manager untuk melacak campaign completion
 * - Settings manager untuk pengaturan user seperti durasi default
 *
 * @par Contoh Penggunaan di QML:
 * @code{.qml}
 * // Mendapatkan teks random
 * var text = GameBackend.getRandomText("en", "medium", 20)
 *
 * // Menyimpan hasil game
 * GameBackend.saveGameResult(75, 95.5, 3, 60, "Medium", "EN", "Manual", 30.0)
 *
 * // Play sound effects
 * GameBackend.playCorrectSound()
 * GameBackend.playErrorSound()
 * @endcode
 */
class GameBackend : public QObject {
  Q_OBJECT

  /**
   * @property sfxEnabled
   * @brief Status apakah sound effects diaktifkan.
   */
  Q_PROPERTY(bool sfxEnabled READ sfxEnabled WRITE setSfxEnabled NOTIFY
                 sfxEnabledChanged)
  
  /**
   * @property defaultDuration
   * @brief Durasi default untuk mode manual (dalam detik).
   */
  Q_PROPERTY(int defaultDuration READ defaultDuration WRITE setDefaultDuration
                 NOTIFY defaultDurationChanged)
  
  /**
   * @property historySortBy
   * @brief Field sorting untuk history ("date", "wpm", "accuracy").
   */
  Q_PROPERTY(QString historySortBy READ historySortBy WRITE setHistorySortBy
                 NOTIFY historySortByChanged)
  
  /**
   * @property historySortAscending
   * @brief Arah sorting history (true = ascending).
   */
  Q_PROPERTY(bool historySortAscending READ historySortAscending WRITE
                 setHistorySortAscending NOTIFY historySortAscendingChanged)
  
  /**
   * @property playerName
   * @brief Nama pemain untuk multiplayer.
   */
  Q_PROPERTY(QString playerName READ playerName WRITE setPlayerName NOTIFY
                 playerNameChanged)

public:
  /**
   * @brief Mendapatkan singleton instance dari GameBackend.
   * @return Pointer ke instance GameBackend.
   */
  static GameBackend *instance();

  /**
   * @brief Factory method untuk QML singleton registration.
   * @param qmlEngine Pointer ke QQmlEngine.
   * @param jsEngine Pointer ke QJSEngine.
   * @return Pointer ke instance GameBackend.
   */
  static GameBackend *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

  // ========================================================================
  // TEXT PROVIDER INTERFACE
  // ========================================================================

  /**
   * @brief Mendapatkan teks acak untuk gameplay.
   * @param language Bahasa teks ("id" untuk Indonesia, "en" untuk English, "prog" untuk Programmer).
   * @param difficulty Level kesulitan ("easy", "medium", "hard", "programmer").
   * @param wordCount Jumlah kata yang diinginkan.
   * @return QString berisi teks yang akan diketik, dengan kata-kata dipisahkan spasi.
   *
   * @details Teks diambil secara random dari word bank yang sudah dimuat.
   * Difficulty mempengaruhi panjang dan kompleksitas kata.
   */
  Q_INVOKABLE QString getRandomText(const QString &language,
                                    const QString &difficulty, int wordCount);

  // ========================================================================
  // SFX INTERFACE
  // ========================================================================

  /**
   * @brief Memutar sound effect untuk keystroke benar.
   * @note Tidak ada rate limiting untuk suara benar.
   */
  Q_INVOKABLE void playCorrectSound();

  /**
   * @brief Memutar sound effect untuk keystroke salah.
   * @note Memiliki rate limiting 80ms untuk mencegah audio overload.
   */
  Q_INVOKABLE void playErrorSound();

  /**
   * @brief Toggle SFX on/off.
   */
  Q_INVOKABLE void toggleSfx();

  /**
   * @brief Mengecek apakah CAPS LOCK sedang aktif.
   * @return true jika CAPS LOCK menyala, false jika tidak.
   *
   * @details Pada Windows menggunakan GetKeyState(VK_CAPITAL).
   * Pada Linux membaca /sys/class/leds/inputN::capslock/brightness.
   */
  Q_INVOKABLE bool isCapsLockOn() const;

  /**
   * @brief Mendapatkan status SFX.
   * @return true jika SFX enabled.
   */
  bool sfxEnabled() const;

  /**
   * @brief Mengatur status SFX.
   * @param enabled true untuk mengaktifkan SFX.
   */
  void setSfxEnabled(bool enabled);

  // ========================================================================
  // HISTORY INTERFACE
  // ========================================================================

  /**
   * @brief Menyimpan hasil game ke history.
   * @param wpm Words per minute yang dicapai.
   * @param accuracy Akurasi mengetik (0-100).
   * @param errors Jumlah kesalahan.
   * @param targetWPM Target WPM (untuk campaign mode).
   * @param difficulty Level kesulitan ("Easy", "Medium", "Hard", "Programmer").
   * @param language Bahasa yang digunakan ("ID", "EN", "PROG").
   * @param mode Mode permainan ("Manual" atau "Campaign").
   * @param timeElapsed Waktu yang dihabiskan (dalam detik).
   */
  Q_INVOKABLE void saveGameResult(double wpm, double accuracy, int errors,
                                  int targetWPM, const QString &difficulty,
                                  const QString &language, const QString &mode,
                                  double timeElapsed);

  /**
   * @brief Mendapatkan halaman history dengan pagination.
   * @param pageNumber Nomor halaman (1-based).
   * @param pageSize Jumlah entry per halaman (default: 5).
   * @return QVariantList berisi entry history.
   */
  Q_INVOKABLE QVariantList getHistoryPage(int pageNumber, int pageSize = 5);

  /**
   * @brief Mendapatkan halaman history dengan sorting dan filtering.
   * @param pageNumber Nomor halaman (1-based).
   * @param pageSize Jumlah entry per halaman.
   * @param sortBy Field untuk sorting ("date", "wpm", "accuracy", "time").
   * @param ascending true untuk ascending, false untuk descending.
   * @param modeFilter Filter mode ("All", "Manual", "Campaign").
   * @param languageFilter Filter bahasa ("All", "ID", "EN", "PROG").
   * @param difficultyFilter Filter difficulty ("All", "Easy", "Medium", "Hard", "Programmer").
   * @return QVariantList berisi entry history yang sudah di-filter dan di-sort.
   */
  Q_INVOKABLE QVariantList getHistoryPageSorted(
      int pageNumber, int pageSize, const QString &sortBy, bool ascending,
      const QString &modeFilter = "All", const QString &languageFilter = "All",
      const QString &difficultyFilter = "All");

  /**
   * @brief Mendapatkan total halaman history.
   * @param pageSize Ukuran halaman (default: 5).
   * @return Jumlah halaman total.
   */
  Q_INVOKABLE int getHistoryTotalPages(int pageSize = 5);

  /**
   * @brief Mendapatkan total jumlah entry history.
   * @return Jumlah entry.
   */
  Q_INVOKABLE int getHistoryTotalEntries();

  /**
   * @brief Menghapus semua history.
   */
  Q_INVOKABLE void clearHistory();

  // ========================================================================
  // PROGRESS INTERFACE
  // ========================================================================

  /**
   * @brief Mengecek apakah level sudah unlocked.
   * @param language Bahasa ("id", "en").
   * @param difficulty Level difficulty ("easy", "medium", "hard").
   * @return true jika level sudah unlocked.
   */
  Q_INVOKABLE bool isLevelUnlocked(const QString &language,
                                   const QString &difficulty);

  /**
   * @brief Mengecek apakah level sudah completed.
   * @param language Bahasa ("id", "en").
   * @param difficulty Level difficulty ("easy", "medium", "hard").
   * @return true jika level sudah diselesaikan.
   */
  Q_INVOKABLE bool isLevelCompleted(const QString &language,
                                    const QString &difficulty);

  /**
   * @brief Menyelesaikan level dan update progress.
   * @param language Bahasa yang dimainkan.
   * @param difficulty Difficulty yang diselesaikan.
   * @param wpm WPM yang dicapai.
   * @param accuracy Akurasi yang dicapai.
   * @return true jika berhasil memenuhi requirement level.
   *
   * @details Requirements per difficulty:
   * - Easy: WPM >= 40, Accuracy >= 80%
   * - Medium: WPM >= 60, Accuracy >= 90%
   * - Hard: WPM >= 70, Accuracy >= 90%
   * - Programmer: WPM >= 50, Accuracy >= 90%
   */
  Q_INVOKABLE bool completeLevel(const QString &language,
                                 const QString &difficulty, double wpm,
                                 double accuracy);

  /**
   * @brief Reset semua progress campaign.
   */
  Q_INVOKABLE void resetProgress();

  /**
   * @brief Mengecek apakah Hard mode pernah diselesaikan sebelumnya.
   * @param language Bahasa ("id", "en").
   * @return true jika Hard sudah pernah completed.
   *
   * @details Digunakan untuk menentukan apakah akan menampilkan Credits
   * setelah Results saat pertama kali menyelesaikan Hard mode.
   */
  Q_INVOKABLE bool wasHardCompletedBefore(const QString &language);

  // ========================================================================
  // SETTINGS INTERFACE
  // ========================================================================

  /**
   * @brief Mendapatkan durasi default untuk mode manual.
   * @return Durasi dalam detik.
   */
  int defaultDuration() const;

  /**
   * @brief Mengatur durasi default.
   * @param duration Durasi dalam detik.
   */
  void setDefaultDuration(int duration);

  /**
   * @brief Mendapatkan field sorting history.
   * @return Field name ("date", "wpm", "accuracy").
   */
  QString historySortBy() const;

  /**
   * @brief Mengatur field sorting history.
   * @param sortBy Field untuk sorting.
   */
  void setHistorySortBy(const QString &sortBy);

  /**
   * @brief Mendapatkan arah sorting history.
   * @return true jika ascending.
   */
  bool historySortAscending() const;

  /**
   * @brief Mengatur arah sorting history.
   * @param ascending true untuk ascending.
   */
  void setHistorySortAscending(bool ascending);

  /**
   * @brief Mendapatkan nama pemain.
   * @return Nama pemain untuk multiplayer.
   */
  QString playerName() const;
  
  /**
   * @brief Mengatur nama pemain.
   * @param name Nama baru.
   */
  void setPlayerName(const QString &name);

signals:
  /** @brief Dipancarkan saat status SFX berubah. */
  void sfxEnabledChanged();
  
  /** @brief Dipancarkan saat durasi default berubah. */
  void defaultDurationChanged();
  
  /** @brief Dipancarkan saat progress campaign berubah. */
  void progressUpdated();
  
  /** @brief Dipancarkan saat history berubah. */
  void historyUpdated();
  
  /** @brief Dipancarkan saat field sorting history berubah. */
  void historySortByChanged();
  
  /** @brief Dipancarkan saat arah sorting history berubah. */
  void historySortAscendingChanged();
  
  /** @brief Dipancarkan saat nama pemain berubah. */
  void playerNameChanged();

private:
  /**
   * @brief Constructor privat untuk singleton pattern.
   * @param parent Parent QObject.
   */
  explicit GameBackend(QObject *parent = nullptr);
  
  /** @brief Destructor. */
  ~GameBackend();

  static GameBackend *s_instance;  ///< Singleton instance

  // Managers
  TextProvider m_textProvider;      ///< Provider untuk teks random
  HistoryManager m_historyManager;  ///< Manager untuk history
  ProgressManager m_progressManager; ///< Manager untuk campaign progress

  // SFX
  QSoundEffect *m_correctSound;  ///< Sound effect untuk keystroke benar
  QSoundEffect *m_errorSound;    ///< Sound effect untuk keystroke salah
  bool m_sfxEnabled;             ///< Status SFX enabled
  QElapsedTimer m_errorSoundTimer;  ///< Timer untuk rate limiting error sound
  QElapsedTimer m_lastSoundPlayedTimer;  ///< Timer untuk audio keepalive
  QTimer *m_audioKeepAliveTimer;  ///< Timer periodik untuk menjaga audio device aktif
  
  static const int SOUND_COOLDOWN_MS = 80;  ///< Cooldown antar error sound (ms)
  static const int AUDIO_KEEPALIVE_MS = 3000;  ///< Interval reinisialisasi audio (ms)

  // Settings
  int m_defaultDuration;  ///< Durasi default untuk mode manual
  QString m_playerName;   ///< Nama pemain untuk multiplayer

  /**
   * @brief Mengkonversi string difficulty ke enum.
   * @param diff String difficulty ("easy", "medium", "hard", "programmer").
   * @return Enum Difficulty yang sesuai.
   */
  Difficulty stringToDifficulty(const QString &diff);
  
  /**
   * @brief Inisialisasi sound effects.
   */
  void initializeSfx();
  
  /**
   * @brief Memuat settings dari disk.
   */
  void loadSettings();
  
  /**
   * @brief Reinisialisasi audio (untuk mencegah Windows audio sleep).
   */
  void reinitializeAudio();

private slots:
  /**
   * @brief Slot untuk menjaga audio device tetap aktif.
   * @details Dipanggil periodik oleh timer untuk mencegah
   * Windows audio device dari masuk mode sleep.
   */
  void onAudioKeepAlive();
};

#endif // GAMEBACKEND_H
