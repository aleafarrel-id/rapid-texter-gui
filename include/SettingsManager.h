/**
 * @file SettingsManager.h
 * @brief Settings Manager untuk Rapid Texter
 * @author Alea Farrel & Team
 * @date 2025
 *
 * Mengelola penyimpanan dan pemuatan pengaturan user dalam format JSON.
 * Settings disimpan di direktori data aplikasi:
 * - Windows: %APPDATA%\RapidTexter\settings.json
 * - Linux: ~/.local/share/RapidTexter/settings.json
 */

#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <string>

/**
 * @class SettingsManager
 * @brief Static class untuk mengelola pengaturan user yang persisten
 *
 * SettingsManager menyediakan:
 * - Load/save settings dari/ke file JSON
 * - Getter/setter untuk setiap setting
 * - Auto-create file jika tidak ada
 *
 * Settings yang disimpan:
 * - sfx_enabled: Status SFX (true/false)
 * - default_duration: Durasi default dalam detik (-1 untuk unlimited)
 * - history_sort_by: Field untuk sorting history ("date" atau "wpm")
 * - history_sort_ascending: Arah sorting (true = ascending, false = descending)
 */
class SettingsManager {
public:
  /**
   * @brief Memuat settings dari file JSON
   *
   * Jika file tidak ada, akan menggunakan nilai default:
   * - sfx_enabled: true
   * - default_duration: 30
   *
   * @return true jika berhasil load dari file
   * @return false jika file tidak ada (menggunakan default)
   */
  static bool load();

  /**
   * @brief Menyimpan settings ke file JSON
   *
   * @return true jika berhasil menyimpan
   * @return false jika gagal membuka file
   */
  static bool save();

  /**
   * @brief Mendapatkan status SFX
   * @return true jika SFX enabled
   */
  static bool getSfxEnabled();

  /**
   * @brief Mengatur status SFX dan langsung menyimpan ke file
   * @param enabled Status SFX yang baru
   */
  static void setSfxEnabled(bool enabled);

  /**
   * @brief Mendapatkan durasi default
   * @return Durasi dalam detik (-1 untuk unlimited)
   */
  static int getDefaultDuration();

  /**
   * @brief Mengatur durasi default dan langsung menyimpan ke file
   * @param duration Durasi dalam detik (-1 untuk unlimited)
   */
  static void setDefaultDuration(int duration);

  /**
   * @brief Mendapatkan field sorting history
   * @return "date" atau "wpm"
   */
  static std::string getHistorySortBy();

  /**
   * @brief Mengatur field sorting history dan menyimpan ke file
   * @param sortBy Field untuk sorting ("date" atau "wpm")
   */
  static void setHistorySortBy(const std::string &sortBy);

  /**
   * @brief Mendapatkan arah sorting history
   * @return true untuk ascending, false untuk descending
   */
  static bool getHistorySortAscending();

  /**
   * @brief Mengatur arah sorting history dan menyimpan ke file
   * @param ascending true untuk ascending, false untuk descending
   */
  static void setHistorySortAscending(bool ascending);

  /**
   * @brief Mendapatkan nama pemain
   * @return String nama pemain
   */
  static std::string getPlayerName();

  /**
   * @brief Mengatur nama pemain dan menyimpan ke file
   * @param name Nama pemain baru
   */
  static void setPlayerName(const std::string &name);

private:
  static bool sfxEnabled;           ///< Status SFX (default: true)
  static int defaultDuration;       ///< Durasi default (default: 30)
  static std::string historySortBy; ///< Field sort history (default: "date")
  static bool historySortAscending; ///< Arah sort (default: false = descending)
  static std::string playerName;    ///< Nama pemain (default: "")
  static bool isLoaded;             ///< Flag: settings sudah di-load
  static std::string filename;      ///< Path ke file settings.json

  /**
   * @brief Mendapatkan path direktori data aplikasi
   * @return Path dengan trailing separator
   */
  static std::string getDataDirectory();
};

#endif // SETTINGSMANAGER_H
