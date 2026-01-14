/**
 * @file main.cpp
 * @brief Entry point untuk aplikasi RapidTexter GUI typing test.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details File ini menginisialisasi aplikasi Qt dan memuat antarmuka QML utama.
 * Proses inisialisasi meliputi:
 * - Membuat instance QGuiApplication untuk event handling
 * - Mengatur metadata organisasi/aplikasi untuk QStandardPaths
 * - Membuat singleton GameBackend, NetworkManager, dan MultiplayerHistoryManager
 * - Mendaftarkan singleton-singleton tersebut ke QML engine
 * - Memuat modul QML utama dan memulai event loop
 *
 * @see GameBackend Backend C++ untuk game state, history, word generation, dan SFX.
 * @see NetworkManager Backend networking untuk fitur multiplayer.
 * @see MultiplayerHistoryManager Manager untuk menyimpan hasil permainan multiplayer.
 * @see Main.qml Jendela aplikasi QML utama dan komponen UI.
 */

#include "GameBackend.h"
#include "MultiplayerHistoryManager.h"
#include "NetworkManager.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

/**
 * @brief Entry point aplikasi.
 *
 * @details Menginisialisasi aplikasi Qt GUI dengan langkah-langkah berikut:
 * 1. Membuat instance QGuiApplication untuk event handling
 * 2. Mengatur nama organisasi/aplikasi untuk QStandardPaths (digunakan untuk
 *    penyimpanan persistent data history dan settings)
 * 3. Membuat singleton GameBackend sebelum QML dimuat (memastikan backend
 *    siap saat komponen QML memintanya)
 * 4. Mendaftarkan GameBackend sebagai singleton QML yang dapat diakses via
 *    "import rapid_texter 1.0"
 * 5. Memuat modul QML utama dan memulai event loop
 *
 * @param argc Jumlah argumen command-line
 * @param argv Nilai argumen command-line
 * @return Exit code (0 untuk sukses, -1 jika pembuatan objek QML gagal)
 */
int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  /*
   * Mengatur metadata aplikasi untuk QStandardPaths.
   * Ini menentukan di mana data persistent (history.json, progress.json)
   * disimpan pada sistem pengguna.
   */
  app.setOrganizationName("RapidTexter");
  app.setApplicationName("RapidTexter");

  /*
   * Membuat singleton instance GameBackend SEBELUM memuat QML.
   * Ini memastikan backend sudah terinisialisasi penuh saat komponen QML
   * mencoba mengaksesnya. Pola singleton menjamin hanya satu instance
   * yang ada sepanjang siklus hidup aplikasi.
   */
  GameBackend *backend = GameBackend::instance();

  /*
   * Membuat singleton NetworkManager untuk fungsionalitas multiplayer.
   * Menangani UDP discovery, WebSocket lobby, dan UDP multicast gameplay.
   */
  NetworkManager *networkManager = NetworkManager::instance();

  /*
   * Membuat singleton MultiplayerHistoryManager.
   * Mengelola penyimpanan hasil permainan multiplayer.
   */
  MultiplayerHistoryManager *mpHistoryManager =
      new MultiplayerHistoryManager(&app);

  /*
   * Menghubungkan NetworkManager ke MultiplayerHistoryManager.
   * Saat race selesai, hasil secara otomatis disimpan.
   */
  QObject::connect(networkManager, &NetworkManager::raceFinished,
                   mpHistoryManager,
                   &MultiplayerHistoryManager::onRaceFinished);

  QQmlApplicationEngine engine;

  /*
   * Mendaftarkan GameBackend sebagai singleton QML.
   * - Modul: "rapid_texter"
   * - Versi: 1.0
   * - Nama QML: "GameBackend"
   * Setelah ini, QML dapat mengaksesnya via: import rapid_texter 1.0
   */
  qmlRegisterSingletonInstance("rapid_texter", 1, 0, "GameBackend", backend);

  /*
   * Mendaftarkan NetworkManager sebagai singleton QML untuk multiplayer.
   */
  qmlRegisterSingletonInstance("rapid_texter", 1, 0, "NetworkManager",
                               networkManager);

  /*
   * Mendaftarkan MultiplayerHistoryManager sebagai singleton QML.
   */
  qmlRegisterSingletonInstance("rapid_texter", 1, 0,
                               "MultiplayerHistoryManager", mpHistoryManager);

  /*
   * Menghubungkan ke sinyal objectCreationFailed untuk menangani error loading QML.
   * Jika file QML utama gagal dimuat, keluar dengan kode error -1.
   * Qt::QueuedConnection memastikan exit terjadi setelah sinyal
   * sepenuhnya diproses.
   */
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

  /* Memuat modul QML utama - ini memicu pembuatan UI */
  engine.loadFromModule("rapid_texter", "Main");

  /* Memulai event loop Qt - memblokir sampai aplikasi di-quit */
  return app.exec();
}
