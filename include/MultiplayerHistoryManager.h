/**
 * @file MultiplayerHistoryManager.h
 * @brief Manager for storing and retrieving multiplayer game history.
 * @author RapidTexter Team
 * @date 2026
 */

#ifndef MULTIPLAYERHISTORYMANAGER_H
#define MULTIPLAYERHISTORYMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <vector>
#include <string>
#include <ctime>
#include <QtQml/qqmlregistration.h>

/**
 * @brief Represents the result of a single player in a multiplayer match.
 */
struct MultiplayerPlayerResult {
    QString name;
    QString uuid;
    int wpm;
    double accuracy;
    int errors;
    double duration;
    int position; // Rank (1st, 2nd, ...)
    bool isLocal; // True if this result belongs to the local user
    bool hasLeft; // True if player disconnected

    MultiplayerPlayerResult() : wpm(0), accuracy(0), errors(0), duration(0), position(0), isLocal(false), hasLeft(false) {}
};

/**
 * @brief Represents a full record of a multiplayer match.
 */
struct MultiplayerHistoryEntry {
    QString timestamp;
    QString hostName; // Name of the room host
    std::vector<MultiplayerPlayerResult> players;
    
    // Derived local stats for quick display in list
    int localWpm;
    int localRank;
    
    MultiplayerHistoryEntry() : localWpm(0), localRank(0) {}
};

/**
 * @class MultiplayerHistoryManager
 * @brief Manages multiplayer history storage (JSON) and access.
 * 
 * Stores history in "multiplayer_history.json".
 */
class MultiplayerHistoryManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    
    Q_PROPERTY(QVariantList historyData READ getHistoryData NOTIFY historyChanged)
    Q_PROPERTY(int totalEntries READ getTotalEntries NOTIFY historyChanged)

public:
    explicit MultiplayerHistoryManager(QObject *parent = nullptr);
    static MultiplayerHistoryManager *instance();
    
    /**
     * @brief Loads history from JSON file.
     */
    bool loadHistory();
    
    /**
     * @brief Saves history to JSON file.
     */
    bool saveHistory();
    
    /**
     * @brief Add a new entry from race results.
     * @param rankings The list of players and their stats from NetworkManager.
     * @param hostName Name of the room creator.
     */
    void addEntry(const QVariantList& rankings, const QString& hostName);
    
    /**
     * @brief Clears all history.
     */
    Q_INVOKABLE void clearHistory();
    
    /**
     * @brief Returns history formatted for QML.
     */
    QVariantList getHistoryData() const;
    
    int getTotalEntries() const;

public slots:
    /**
     * @brief Slot to receive race results from NetworkManager.
     */
    void onRaceFinished(const QVariantList& rankings);

signals:
    void historyChanged();

private:
    static MultiplayerHistoryManager *s_instance;
    std::vector<MultiplayerHistoryEntry> m_entries;
    std::string m_filename;
    
    std::string getCurrentTimestamp();
    std::string escapeJsonString(const std::string& str);
};

#endif // MULTIPLAYERHISTORYMANAGER_H
