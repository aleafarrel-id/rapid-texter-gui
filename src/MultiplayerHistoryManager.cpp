/**
 * @file MultiplayerHistoryManager.cpp
 * @brief Implementation of MultiplayerHistoryManager.
 * @author RapidTexter Team
 * @date 2026
 */

#include "MultiplayerHistoryManager.h"
#include "NetworkManager.h"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

MultiplayerHistoryManager *MultiplayerHistoryManager::s_instance = nullptr;

MultiplayerHistoryManager::MultiplayerHistoryManager(QObject *parent)
    : QObject(parent) {
  if (s_instance) {
    qWarning() << "[MultiplayerHistoryManager] Instance already exists!";
    return;
  }
  s_instance = this;

  // Determine data directory using QStandardPaths (Standard Qt way)
  // HistoryManager.cpp uses custom logic, but we can try to be consistent with
  // Qt best practices or stick to the manual logic if needed. Let's use
  // QStandardPaths which maps to the same locations usually. data location:
  // ~/.local/share/RapidTexter/ or %APPDATA%/RapidTexter/

  QString dataLocation =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
  QDir dir(dataLocation);
  if (!dir.exists()) {
    dir.mkpath(".");
  }

  m_filename = dir.filePath("multiplayer_history.json").toStdString();

  loadHistory();
}

MultiplayerHistoryManager *MultiplayerHistoryManager::instance() {
  return s_instance;
  // Note: It's created in main.cpp, but this accessor is useful.
  // If null, it shouldn't auto-create because it needs QML context potentially,
  // though here it's simple QObject.
}

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

      if (player.isLocal) {
        entry.localWpm = player.wpm;
        entry.localRank = player.position;
      }
    }
    m_entries.push_back(entry);
  }

  emit historyChanged();
  return true;
}

bool MultiplayerHistoryManager::saveHistory() {
  QJsonObject root;
  QJsonArray entriesArr;

  for (const auto &entry : m_entries) {
    QJsonObject obj;
    obj["timestamp"] = entry.timestamp;
    obj["hostName"] = entry.hostName;

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

void MultiplayerHistoryManager::onRaceFinished(const QVariantList &rankings) {
  qDebug() << "[MultiplayerHistoryManager] Race finished, saving legacy...";

  // Determine host name
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

void MultiplayerHistoryManager::addEntry(const QVariantList &rankings,
                                         const QString &hostName) {
  MultiplayerHistoryEntry entry;
  entry.timestamp =
      QDateTime::currentDateTime().toString("dd/MM/yyyy HH:mm:ss");
  entry.hostName = hostName;

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

    if (player.isLocal) {
      entry.localWpm = player.wpm;
      entry.localRank = player.position;
    }
  }

  // Insert at beginning (newest first)
  m_entries.insert(m_entries.begin(), entry);
  saveHistory();
  emit historyChanged();
}

void MultiplayerHistoryManager::clearHistory() {
  m_entries.clear();
  saveHistory();
  emit historyChanged();
}

QVariantList MultiplayerHistoryManager::getHistoryData() const {
  QVariantList list;
  for (const auto &entry : m_entries) {
    QVariantMap map;
    map["timestamp"] = entry.timestamp;
    map["hostName"] = entry.hostName;
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

int MultiplayerHistoryManager::getTotalEntries() const {
  return static_cast<int>(m_entries.size());
}
