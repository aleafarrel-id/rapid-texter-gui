/**
 * @file MultiplayerHistoryManager.cpp
 * @brief Implementasi MultiplayerHistoryManager untuk penyimpanan riwayat multiplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details File ini berisi implementasi dari semua method MultiplayerHistoryManager
 * termasuk load/save JSON, sorting, dan integrasi dengan QML.
 */

#include "MultiplayerHistoryManager.h"
#include "NetworkManager.h"
#include "SettingsManager.h"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <algorithm>

/// Singleton instance pointer
MultiplayerHistoryManager *MultiplayerHistoryManager::s_instance = nullptr;

/**
 * @brief Constructor MultiplayerHistoryManager.
 * @param parent Parent QObject.
 *
 * @details Constructor melakukan:
 * 1. Validasi singleton (hanya satu instance diizinkan)
 * 2. Menentukan path file riwayat dengan penanganan migrasi
 * 3. Memuat riwayat dari file
 *
 * @note Menangani kasus path ganda (RapidTexter/RapidTexter) yang mungkin
 * terjadi pada beberapa konfigurasi Qt.
 */
MultiplayerHistoryManager::MultiplayerHistoryManager(QObject *parent)
    : QObject(parent) {
  if (s_instance) {
    qWarning() << "[MultiplayerHistoryManager] Instance already exists!";
    return;
  }
  s_instance = this;

  // Fix untuk masalah folder ganda ("RapidTexter/RapidTexter")
  // Target path: %APPDATA%/RapidTexter/multiplayer_history.json
  QString standardPath =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir dir(standardPath);

  // Cek apakah berada dalam situasi folder ganda
  if (dir.dirName() == "RapidTexter" && dir.cdUp()) {
    if (dir.dirName() == "RapidTexter") {
      // Struktur .../RapidTexter/RapidTexter terdeteksi
      // cdUp membawa ke .../RapidTexter yang benar
    } else {
      // Struktur tidak sesuai, kembali ke path standar
      dir.setPath(standardPath);
    }
  }

  // Konstruksi path yang bersih secara eksplisit
  QString cleanPathStr = standardPath;
  if (cleanPathStr.endsWith("/RapidTexter/RapidTexter")) {
      cleanPathStr.chop(12); // Hapus "/RapidTexter" terakhir
  }
  QDir cleanDir(cleanPathStr);
  if (!cleanDir.exists()) {
      cleanDir.mkpath(".");
  }
  QString goodPath = cleanDir.filePath("multiplayer_history.json");

  // Migrasi: Pindahkan file lama ke lokasi baru jika diperlukan
  QString badPath = standardPath + "/multiplayer_history.json";
  QFile badFile(badPath);
  QFile goodFile(goodPath);
  
  if (badFile.exists() && !goodFile.exists()) {
      qDebug() << "[MultiplayerHistoryManager] Migrating history from" << badPath << "to" << goodPath;
      if (!badFile.rename(goodPath)) {
           qWarning() << "[MultiplayerHistoryManager] Migration failed!";
      }
  }

  m_filename = goodPath.toStdString();
  qDebug() << "[MultiplayerHistoryManager] Using history file:" << goodPath;

  loadHistory();
}

/**
 * @brief Mendapatkan singleton instance.
 * @return Pointer ke instance, atau nullptr jika belum diinisialisasi.
 */
MultiplayerHistoryManager *MultiplayerHistoryManager::instance() {
  return s_instance;
}

/**
 * @brief Memuat riwayat dari file JSON.
 * @return true jika berhasil, false jika file tidak ada atau format salah.
 *
 * @details Proses loading:
 * 1. Buka file JSON
 * 2. Parse JSON menjadi objek
 * 3. Iterasi array entries dan populasi m_entries
 * 4. Terapkan sorting berdasarkan pengaturan tersimpan
 */
bool MultiplayerHistoryManager::loadHistory() {
  QFile file(QString::fromStdString(m_filename));
  if (!file.open(QIODevice::ReadOnly)) {
    return false;
  }

  QByteArray data = file.readAll();
  file.close();

  QJsonDocument doc = QJsonDocument::fromJson(data);
  if (!doc.isObject())
    return false;

  QJsonObject root = doc.object();
  QJsonArray entriesArr = root["entries"].toArray();

  m_entries.clear();

  for (const QJsonValue &val : entriesArr) {
    QJsonObject obj = val.toObject();
    MultiplayerHistoryEntry entry;
    entry.timestamp = obj["timestamp"].toString();
    entry.hostName = obj["hostName"].toString();
    entry.language = obj["language"].toString("en");  // Default "en" untuk backward compatibility

    QJsonArray playersArr = obj["players"].toArray();
    for (const QJsonValue &pVal : playersArr) {
      QJsonObject pObj = pVal.toObject();
      MultiplayerPlayerResult player;
      player.name = pObj["name"].toString();
      player.uuid = pObj["uuid"].toString();
      player.wpm = pObj["wpm"].toInt();
      player.accuracy = pObj["accuracy"].toDouble();
      player.errors = pObj["errors"].toInt();
      player.duration = pObj["duration"].toDouble();
      player.position = pObj["position"].toInt();
      player.isLocal = pObj["isLocal"].toBool();
      player.hasLeft = pObj["hasLeft"].toBool();

      entry.players.push_back(player);

      // Cache statistik pemain lokal untuk tampilan cepat
      if (player.isLocal) {
        entry.localWpm = player.wpm;
        entry.localRank = player.position;
      }
    }
    m_entries.push_back(entry);
  }

  // Terapkan sorting berdasarkan pengaturan tersimpan
  sortHistory();

  emit historyChanged();
  return true;
}

/**
 * @brief Menyimpan riwayat ke file JSON.
 * @return true jika berhasil, false jika gagal menulis file.
 *
 * @details Mengkonversi m_entries ke format JSON dan menulis ke disk.
 */
bool MultiplayerHistoryManager::saveHistory() {
  QJsonObject root;
  QJsonArray entriesArr;

  for (const auto &entry : m_entries) {
    QJsonObject obj;
    obj["timestamp"] = entry.timestamp;
    obj["hostName"] = entry.hostName;
    obj["language"] = entry.language;

    QJsonArray playersArr;
    for (const auto &player : entry.players) {
      QJsonObject pObj;
      pObj["name"] = player.name;
      pObj["uuid"] = player.uuid;
      pObj["wpm"] = player.wpm;
      pObj["accuracy"] = player.accuracy;
      pObj["errors"] = player.errors;
      pObj["duration"] = player.duration;
      pObj["position"] = player.position;
      pObj["isLocal"] = player.isLocal;
      pObj["hasLeft"] = player.hasLeft;
      playersArr.append(pObj);
    }
    obj["players"] = playersArr;
    entriesArr.append(obj);
  }

  root["entries"] = entriesArr;

  QFile file(QString::fromStdString(m_filename));
  if (!file.open(QIODevice::WriteOnly)) {
    qWarning() << "[MultiplayerHistoryManager] Failed to save history to"
               << QString::fromStdString(m_filename);
    return false;
  }

  file.write(QJsonDocument(root).toJson());
  file.close();
  return true;
}

/**
 * @brief Slot untuk menerima hasil race dari NetworkManager.
 * @param rankings Daftar ranking pemain dari race yang selesai.
 *
 * @details Mengambil nama host dari NetworkManager dan memanggil addEntry().
 */
void MultiplayerHistoryManager::onRaceFinished(const QVariantList &rankings) {
  qDebug() << "[MultiplayerHistoryManager] Race finished, saving legacy...";

  // Tentukan nama host dari daftar pemain
  QString hostName = "Unknown";
  NetworkManager *nm = NetworkManager::instance();
  if (nm) {
    QVariantList allPlayers = nm->players();
    for (const QVariant &p : allPlayers) {
      QVariantMap map = p.toMap();
      if (map["isHost"].toBool()) {
        hostName = map["name"].toString();
        break;
      }
    }
  }

  addEntry(rankings, hostName);
}

/**
 * @brief Menambahkan entry baru ke riwayat.
 * @param rankings Daftar pemain dan statistik dari NetworkManager.
 * @param hostName Nama pembuat room.
 *
 * @details Entry baru dimasukkan di awal daftar (terbaru pertama),
 * kemudian di-sort ulang sesuai pengaturan user, dan disimpan ke disk.
 */
void MultiplayerHistoryManager::addEntry(const QVariantList &rankings,
                                         const QString &hostName) {
  MultiplayerHistoryEntry entry;
  entry.timestamp = captureTimestamp();
  entry.hostName = hostName;
  
  // Ambil language dari NetworkManager
  NetworkManager *nm = NetworkManager::instance();
  entry.language = nm ? nm->gameLanguage() : "en";

  for (const QVariant &r : rankings) {
    QVariantMap map = r.toMap();
    MultiplayerPlayerResult player;
    player.name = map["name"].toString();
    player.uuid = map["id"].toString();
    player.wpm = map["wpm"].toInt();
    player.accuracy = map["accuracy"].toDouble();
    player.errors = map["errors"].toInt();
    player.duration = map["duration"].toDouble();
    player.position = map["position"].toInt();
    player.isLocal = map["isLocal"].toBool();
    player.hasLeft = map["hasLeft"].toBool();

    entry.players.push_back(player);

    // Cache statistik pemain lokal
    if (player.isLocal) {
      entry.localWpm = player.wpm;
      entry.localRank = player.position;
    }
  }

  // Masukkan di awal (terbaru pertama)
  m_entries.insert(m_entries.begin(), entry);
  
  // Re-sort karena user mungkin punya pengaturan sort berbeda
  sortHistory();
  
  saveHistory();
  emit historyChanged();
}

/**
 * @brief Menghapus semua riwayat.
 *
 * @details Mengosongkan m_entries dan menyimpan file kosong ke disk.
 */
void MultiplayerHistoryManager::clearHistory() {
  m_entries.clear();
  saveHistory();
  emit historyChanged();
}

/**
 * @brief Mendapatkan data riwayat dalam format QVariantList untuk QML.
 * @return QVariantList berisi QVariantMap untuk setiap entry.
 */
QVariantList MultiplayerHistoryManager::getHistoryData() const {
  QVariantList list;
  for (const auto &entry : m_entries) {
    // Filter by language if filter is set
    if (!m_filterLanguage.isEmpty() && m_filterLanguage != "all" && entry.language != m_filterLanguage) {
      continue;
    }
    
    QVariantMap map;
    map["timestamp"] = entry.timestamp;
    map["hostName"] = entry.hostName;
    map["language"] = entry.language;
    map["localWpm"] = entry.localWpm;
    map["localRank"] = entry.localRank;

    QVariantList playersList;
    for (const auto &p : entry.players) {
      QVariantMap pMap;
      pMap["name"] = p.name;
      pMap["wpm"] = p.wpm;
      pMap["accuracy"] = p.accuracy;
      pMap["errors"] = p.errors;
      pMap["duration"] = p.duration;
      pMap["position"] = p.position;
      pMap["isLocal"] = p.isLocal;
      pMap["hasLeft"] = p.hasLeft;
      playersList.append(pMap);
    }
    map["players"] = playersList;

    list.append(map);
  }
  return list;
}

/**
 * @brief Mendapatkan total jumlah entry riwayat.
 * @return Jumlah entry.
 */
int MultiplayerHistoryManager::getTotalEntries() const {
  return static_cast<int>(m_entries.size());
}

/**
 * @brief Mendapatkan field sorting saat ini dari SettingsManager.
 * @return QString field sorting.
 */
QString MultiplayerHistoryManager::sortBy() const {
  return QString::fromStdString(SettingsManager::getMultiplayerHistorySortBy());
}

/**
 * @brief Mengatur field sorting.
 * @param sortBy Field baru untuk sorting ("date", "wpm", "rank").
 *
 * @details Menyimpan ke SettingsManager dan re-sort riwayat.
 */
void MultiplayerHistoryManager::setSortBy(const QString &sortBy) {
  std::string current = SettingsManager::getMultiplayerHistorySortBy();
  if (current != sortBy.toStdString()) {
    SettingsManager::setMultiplayerHistorySortBy(sortBy.toStdString());
    sortHistory();
    emit historyChanged();
    emit sortByChanged();
  }
}

/**
 * @brief Mendapatkan arah sorting dari SettingsManager.
 * @return true jika ascending.
 */
bool MultiplayerHistoryManager::sortAscending() const {
  return SettingsManager::getMultiplayerHistorySortAscending();
}

/**
 * @brief Mengatur arah sorting.
 * @param ascending true untuk ascending, false untuk descending.
 *
 * @details Menyimpan ke SettingsManager dan re-sort riwayat.
 */
void MultiplayerHistoryManager::setSortAscending(bool ascending) {
  if (SettingsManager::getMultiplayerHistorySortAscending() != ascending) {
    SettingsManager::setMultiplayerHistorySortAscending(ascending);
    sortHistory();
    emit historyChanged();
    emit sortAscendingChanged();
  }
}

/**
 * @brief Mendapatkan filter bahasa saat ini.
 * @return QString filter ("all", "id", "en", "prog").
 */
QString MultiplayerHistoryManager::filterLanguage() const {
  return m_filterLanguage;
}

/**
 * @brief Mengatur filter bahasa.
 * @param language Bahasa untuk filter.
 *
 * @details Mengubah filter akan menyebabkan data yang ditampilkan berubah.
 */
void MultiplayerHistoryManager::setFilterLanguage(const QString &language) {
  if (m_filterLanguage != language) {
    m_filterLanguage = language;
    emit filterLanguageChanged();
    emit historyChanged();  // Re-emit karena data yang ditampilkan berubah
  }
}

/**
 * @brief Mengurutkan riwayat berdasarkan pengaturan saat ini.
 *
 * @details Mendukung sorting berdasarkan:
 * - "wpm": Words per minute pemain lokal
 * - "rank": Peringkat pemain lokal
 * - default (date): Timestamp pertandingan
 */
void MultiplayerHistoryManager::sortHistory() {
  QString sortBy = this->sortBy();
  bool ascending = this->sortAscending();

  if (m_entries.empty()) return;

  if (sortBy == "wpm") {
    std::sort(m_entries.begin(), m_entries.end(),
              [ascending](const MultiplayerHistoryEntry &a, const MultiplayerHistoryEntry &b) {
                return ascending ? (a.localWpm < b.localWpm) : (a.localWpm > b.localWpm);
              });
  } else if (sortBy == "rank") {
    std::sort(m_entries.begin(), m_entries.end(),
              [ascending](const MultiplayerHistoryEntry &a, const MultiplayerHistoryEntry &b) {
                return ascending ? (a.localRank < b.localRank) : (a.localRank > b.localRank);
              });
  } else {
    // Default: Sort by date (timestamp format: "dd/MM/yyyy HH:mm:ss")
    std::sort(m_entries.begin(), m_entries.end(),
              [ascending](const MultiplayerHistoryEntry &a, const MultiplayerHistoryEntry &b) {
                QDateTime dtA = QDateTime::fromString(a.timestamp, "dd/MM/yyyy HH:mm:ss");
                QDateTime dtB = QDateTime::fromString(b.timestamp, "dd/MM/yyyy HH:mm:ss");
                
                if (ascending) {
                    return dtA < dtB;
                } else {
                    return dtA > dtB;
                }
              });
  }
}

/**
 * @brief Mengambil timestamp saat ini dalam format standar.
 * @return QString timestamp (dd/MM/yyyy HH:mm:ss).
 */
QString MultiplayerHistoryManager::captureTimestamp() {
    return QDateTime::currentDateTime().toString("dd/MM/yyyy HH:mm:ss");
}

/**
 * @brief Escape karakter khusus dalam string untuk JSON.
 * @param str String input.
 * @return String yang sudah di-escape.
 *
 * @details Menangani karakter: ", \, \n, \r, \t
 */
std::string MultiplayerHistoryManager::escapeJsonString(const std::string& str) {
    std::string escaped;
    for (char c : str) {
        if (c == '"') escaped += "\\\"";
        else if (c == '\\') escaped += "\\\\";
        else if (c == '\n') escaped += "\\n";
        else if (c == '\r') escaped += "\\r";
        else if (c == '\t') escaped += "\\t";
        else escaped += c;
    }
    return escaped;
}
