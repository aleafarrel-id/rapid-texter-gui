#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QUdpSocket>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QNetworkInterface>
#include <QTimer>
#include <QUuid>
#include <QQmlEngine>
#include <QDataStream>

/**
 * @brief NetworkManager handles P2P Full Mesh multiplayer for Rapid Texter.
 * 
 * Architecture: Full Mesh Peer-to-Peer with Floating Authority
 * - Discovery: UDP Broadcast (LAN)
 * - Transport: TCP (Reliable State Sync)
 * - Authority: Lowest UUID Rule (Deterministic)
 * 
 * Ports:
 * - 52766: UDP Broadcast for discovery
 * - 52765: TCP for mesh connections
 */
class NetworkManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    
    // === QML PROPERTIES ===
    Q_PROPERTY(bool isAuthority READ isAuthority NOTIFY authorityChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY scanningChanged)
    Q_PROPERTY(bool isInGame READ isInGame NOTIFY gameStateChanged)
    Q_PROPERTY(bool isInLobby READ isInLobby NOTIFY lobbyStateChanged)
    Q_PROPERTY(QString localIpAddress READ localIpAddress CONSTANT)
    Q_PROPERTY(QString playerId READ playerId CONSTANT)
    Q_PROPERTY(QString playerName READ playerName WRITE setPlayerName NOTIFY playerNameChanged)
    Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)
    Q_PROPERTY(QVariantList discoveredRooms READ discoveredRooms NOTIFY discoveredRoomsChanged)
    Q_PROPERTY(QString gameText READ gameText NOTIFY gameTextChanged)
    Q_PROPERTY(QString gameLanguage READ gameLanguage NOTIFY gameLanguageChanged)
    Q_PROPERTY(QString connectionError READ connectionError NOTIFY connectionErrorChanged)
    Q_PROPERTY(int peerCount READ peerCount NOTIFY peersChanged)
    Q_PROPERTY(QVariantList availableInterfaces READ availableInterfaces CONSTANT)
    Q_PROPERTY(bool isConnecting READ isConnecting NOTIFY connectingChanged)
    Q_PROPERTY(QString selectedInterface READ selectedInterface WRITE setSelectedInterface NOTIFY selectedInterfaceChanged)
    
public:
    static NetworkManager* instance();
    static NetworkManager* create(QQmlEngine* engine, QJSEngine* scriptEngine);
    
    // === PACKET TYPES ===
    enum class PacketType : quint8 {
        HELLO = 0,
        PEER_LIST,
        GAME_START,
        PROGRESS_UPDATE,
        FINISH,
        GAME_TEXT,
        COUNTDOWN,
        PLAYER_LEFT,
        RACE_RESULTS
    };
    Q_ENUM(PacketType)
    
    // === PACKET STRUCTURE ===
    struct Packet {
        PacketType type;
        QString senderUuid;
        qint64 timestamp;
        QJsonObject payload;
        
        QByteArray serialize() const;
        static Packet deserialize(const QByteArray& data);
    };
    
    // === ROOM FUNCTIONS ===
    Q_INVOKABLE bool createRoom();
    Q_INVOKABLE void closeRoom();
    
    // === DISCOVERY FUNCTIONS ===
    Q_INVOKABLE void startScanning();
    Q_INVOKABLE void stopScanning();
    Q_INVOKABLE void refreshRooms();
    
    // === CONNECTION FUNCTIONS ===
    Q_INVOKABLE bool joinRoom(const QString& hostIp, int port);
    Q_INVOKABLE void leaveRoom();
    Q_INVOKABLE bool connectToPeer(const QString& ip, int port, const QString& uuid = QString());
    
    // === GAME CONTROL (Authority only) ===
    Q_INVOKABLE void setGameText(const QString& text);
    Q_INVOKABLE void setGameLanguage(const QString& language);
    Q_INVOKABLE void refreshGameText();
    Q_INVOKABLE void startCountdown();
    Q_INVOKABLE void kickPlayer(const QString& uuid);
    
    // === PLAYER ACTIONS ===
    Q_INVOKABLE void updateProgress(int position, int totalChars, int wpm);
    Q_INVOKABLE void finishRace(int wpm, double accuracy, int errors);
    
    // === GETTERS ===
    bool isAuthority() const { return m_isAuthority; }
    bool isConnected() const { return m_isConnected; }
    bool isScanning() const { return m_isScanning; }
    bool isInGame() const { return m_isInGame; }
    bool isInLobby() const { return m_isInLobby; }
    QString localIpAddress() const;
    QString playerId() const { return m_playerId; }
    QString playerName() const { return m_playerName; }
    QVariantList players() const;
    QVariantList discoveredRooms() const;
    QString gameText() const { return m_gameText; }
    QString gameLanguage() const { return m_gameLanguage; }
    QString connectionError() const { return m_connectionError; }
    int peerCount() const { return m_peers.size(); }
    QVariantList availableInterfaces() const;
    bool isConnecting() const { return m_isConnecting; }
    QString selectedInterface() const { return m_selectedInterface; }
    
    void setPlayerName(const QString& name);
    Q_INVOKABLE void setSelectedInterface(const QString& ip);
    
signals:
    // Property change signals
    void authorityChanged();
    void connectionChanged();
    void scanningChanged();
    void gameStateChanged();
    void lobbyStateChanged();
    void playerNameChanged();
    void playersChanged();
    void discoveredRoomsChanged();
    void gameTextChanged();
    void gameLanguageChanged();
    void connectionErrorChanged();
    void peersChanged();
    
    // Game flow signals
    void playerJoined(const QString& name);
    void playerLeft(const QString& name);
    void countdownStarted(int seconds);
    void gameStarted();
    void playerProgressUpdated(const QString& id, const QString& name, 
                               double progress, int wpm, bool finished, int position);
    void raceFinished(const QVariantList& rankings);
    
    // Discovery signals
    void roomFound(const QString& ip, int port, const QString& hostName);
    
    // Connection result signals
    void joinSucceeded();
    void joinFailed(const QString& reason);
    void connectingChanged();
    void selectedInterfaceChanged();
    
private:
    explicit NetworkManager(QObject* parent = nullptr);
    ~NetworkManager();
    
    static NetworkManager* s_instance;
    
    // === CONSTANTS ===
    static constexpr int DISCOVERY_PORT = 52766;
    static constexpr int TCP_PORT = 52765;
    static constexpr int ANNOUNCE_INTERVAL_MS = 1000;  // 1 second as per blueprint
    static constexpr int ROOM_TIMEOUT_MS = 5000;
    static constexpr int PROGRESS_UPDATE_MS = 50;  // 50ms for real-time fairness
    static constexpr int MAX_PLAYERS = 8;
    inline static const char* APP_IDENTIFIER = "RapidTexterP2P";
    
    // === STATE ===
    bool m_isAuthority = false;
    bool m_isConnected = false;
    bool m_isScanning = false;
    bool m_isInGame = false;
    bool m_isInLobby = false;
    QString m_playerId;
    QString m_playerName;
    QString m_gameText;
    QString m_gameLanguage = "en";  // Default language
    QString m_connectionError;
    bool m_isConnecting = false;
    QString m_pendingJoinIp;
    int m_pendingJoinPort = 0;
    QString m_selectedInterface;  // Selected interface IP for broadcasting
    
    // === TCP (Mesh) ===
    QTcpServer* m_tcpServer = nullptr;
    
    // === PEER CONNECTION ===
    struct PeerConnection {
        QTcpSocket* socket = nullptr;
        QString uuid;
        QString name;
        QString ip;
        int port = 0;
        bool handshakeComplete = false;
        QByteArray readBuffer;
    };
    QMap<QString, PeerConnection*> m_peers;  // UUID -> PeerConnection
    QSet<QString> m_pendingConnections;       // IP:Port being connected to (prevent duplicates)
    
    // === UDP DISCOVERY ===
    QUdpSocket* m_discoverySocket = nullptr;
    QTimer* m_announceTimer = nullptr;
    QTimer* m_cleanupTimer = nullptr;
    QTimer* m_connectionTimeoutTimer = nullptr;
    
    // === DATA ===
    struct PlayerInfo {
        QString uuid;
        QString name;
        int position = 0;
        int totalChars = 0;
        int wpm = 0;
        bool finished = false;
        int racePosition = 0;
        qint64 finishTime = 0;
    };
    QMap<QString, PlayerInfo> m_players;
    
    struct RoomInfo {
        QString hostName;
        QString hostIp;
        QString hostUuid;
        int port = 0;
        int playerCount = 0;
        QString status;  // "waiting", "countdown", "racing"
        qint64 lastSeen = 0;
    };
    QMap<QString, RoomInfo> m_discoveredRooms;  // UUID -> RoomInfo
    
    // Local player state
    int m_currentPosition = 0;
    int m_currentTotal = 0;
    int m_currentWpm = 0;
    bool m_localFinished = false;
    int m_finishedCount = 0;
    
    // Progress timer
    QTimer* m_progressTimer = nullptr;
    
    // === PRIVATE METHODS ===
    
    // Discovery
    void setupDiscoverySocket();
    void startAnnouncing();
    void stopAnnouncing();
    void sendAnnounce();
    void processDiscoveryDatagram();
    void cleanupStaleRooms();
    
    // TCP Mesh
    void startTcpServer();
    void stopTcpServer();
    void onNewTcpConnection();
    void onPeerConnected();
    void onPeerDisconnected();
    void onPeerReadyRead();
    void onPeerError(QAbstractSocket::SocketError error);
    
    // Handshake & Mesh
    void sendHello(PeerConnection* peer);
    void handleHello(PeerConnection* peer, const Packet& packet);
    void sendPeerList(PeerConnection* peer);
    void handlePeerList(const Packet& packet);
    void connectToMissingPeers(const QJsonArray& peerList);
    
    // Packet Handling
    void processPacket(PeerConnection* peer, const Packet& packet);
    void broadcastToAllPeers(const Packet& packet);
    void sendToPeer(PeerConnection* peer, const Packet& packet);
    Packet createPacket(PacketType type, const QJsonObject& payload = {});
    
    // Authority
    bool determineAuthority();
    void updateAuthority();
    
    // Game Logic
    void handleGameStart(const Packet& packet);
    void handleProgressUpdate(PeerConnection* peer, const Packet& packet);
    void handleFinish(PeerConnection* peer, const Packet& packet);
    void handleGameText(const Packet& packet);
    void handleCountdown(const Packet& packet);
    void handlePlayerLeft(const Packet& packet);
    void handleRaceResults(const Packet& packet);
    void sendProgressUpdate();
    void checkRaceCompletion();
    
    // Utilities
    void setConnectionError(const QString& error);
    void resetState();
    QString getPeerKey(const QString& ip, int port) const;
    void removePeer(const QString& uuid);
};

#endif // NETWORKMANAGER_H
