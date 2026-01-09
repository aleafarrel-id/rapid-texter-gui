#include "NetworkManager.h"
#include "GameBackend.h"
#include <QDateTime>
#include <QHostAddress>
#include <algorithm>

NetworkManager* NetworkManager::s_instance = nullptr;

NetworkManager* NetworkManager::instance() {
    if (!s_instance) {
        s_instance = new NetworkManager();
    }
    return s_instance;
}

NetworkManager* NetworkManager::create(QQmlEngine* engine, QJSEngine* scriptEngine) {
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return instance();
}

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent)
    , m_playerId(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    // Setup discovery socket
    setupDiscoverySocket();
    
    // Cleanup timer for stale rooms
    m_cleanupTimer = new QTimer(this);
    connect(m_cleanupTimer, &QTimer::timeout, this, &NetworkManager::cleanupStaleRooms);
    
    // Announce timer for room hosting
    m_announceTimer = new QTimer(this);
    connect(m_announceTimer, &QTimer::timeout, this, &NetworkManager::sendAnnounce);
    
    // Progress update timer (50ms for real-time fairness)
    m_progressTimer = new QTimer(this);
    connect(m_progressTimer, &QTimer::timeout, this, &NetworkManager::sendProgressUpdate);
    
    // Connection timeout timer (5 seconds)
    m_connectionTimeoutTimer = new QTimer(this);
    m_connectionTimeoutTimer->setSingleShot(true);
    connect(m_connectionTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (m_isConnecting) {
            m_isConnecting = false;
            emit connectingChanged();
            
            // Clean up partial state
            resetState();
            
            emit joinFailed("Connection timed out. Host not found at " + m_pendingJoinIp);
            qDebug() << "[NetworkManager] Connection timeout to" << m_pendingJoinIp;
        }
    });
    
    // Ready check timer (5 seconds timeout for all players to respond)
    m_readyCheckTimer = new QTimer(this);
    m_readyCheckTimer->setSingleShot(true);
    connect(m_readyCheckTimer, &QTimer::timeout, this, &NetworkManager::onReadyCheckTimeout);
    
    qDebug() << "[NetworkManager] Initialized with UUID:" << m_playerId;
}

NetworkManager::~NetworkManager() {
    resetState();
}

// ============================================================================
// PACKET SERIALIZATION
// ============================================================================

QByteArray NetworkManager::Packet::serialize() const {
    QJsonObject obj;
    obj["type"] = static_cast<int>(type);
    obj["sender"] = senderUuid;
    obj["ts"] = timestamp;
    obj["payload"] = payload;
    
    QByteArray json = QJsonDocument(obj).toJson(QJsonDocument::Compact);
    
    // Prepend length for framing
    QByteArray result;
    QDataStream stream(&result, QIODevice::WriteOnly);
    stream.setVersion(QDataStream::Qt_6_0);
    stream << static_cast<quint32>(json.size());
    result.append(json);
    
    return result;
}

NetworkManager::Packet NetworkManager::Packet::deserialize(const QByteArray& data) {
    Packet packet;
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return packet;
    
    QJsonObject obj = doc.object();
    packet.type = static_cast<PacketType>(obj["type"].toInt());
    packet.senderUuid = obj["sender"].toString();
    packet.timestamp = obj["ts"].toVariant().toLongLong();
    packet.payload = obj["payload"].toObject();
    
    return packet;
}

NetworkManager::Packet NetworkManager::createPacket(PacketType type, const QJsonObject& payload) {
    Packet packet;
    packet.type = type;
    packet.senderUuid = m_playerId;
    packet.timestamp = QDateTime::currentMSecsSinceEpoch();
    packet.payload = payload;
    return packet;
}

// ============================================================================
// DISCOVERY
// ============================================================================

void NetworkManager::setupDiscoverySocket() {
    m_discoverySocket = new QUdpSocket(this);
    if (!m_discoverySocket->bind(QHostAddress::AnyIPv4, DISCOVERY_PORT, 
                            QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint)) {
        qWarning() << "[NetworkManager] Failed to bind discovery socket:" << m_discoverySocket->errorString();
    }
    connect(m_discoverySocket, &QUdpSocket::readyRead, 
            this, &NetworkManager::processDiscoveryDatagram);
}

QString NetworkManager::localIpAddress() const {
    const auto interfaces = QNetworkInterface::allInterfaces();
    QString bestAddress;
    int bestScore = -1;
    
    for (const auto& iface : interfaces) {
        if (!iface.flags().testFlag(QNetworkInterface::IsUp) ||
            !iface.flags().testFlag(QNetworkInterface::IsRunning) ||
            iface.flags().testFlag(QNetworkInterface::IsLoopBack)) {
            continue;
        }
        
        const QString name = iface.humanReadableName().toLower();
        const QString hwName = iface.name().toLower();
        
        // Skip virtual adapters (VMware, VirtualBox, Hyper-V, Docker, WSL)
        if (name.contains("vmware") || name.contains("virtualbox") ||
            name.contains("vbox") || name.contains("hyper-v") ||
            name.contains("virtual") || name.contains("docker") ||
            name.contains("vethernet") || name.contains("wsl") ||
            hwName.contains("vmnet") || hwName.contains("vboxnet") ||
            hwName.contains("virbr") || hwName.contains("br-")) {
            continue;
        }
        
        const auto entries = iface.addressEntries();
        for (const auto& entry : entries) {
            if (entry.ip().protocol() != QAbstractSocket::IPv4Protocol) {
                continue;
            }
            
            QString ip = entry.ip().toString();
            if (ip.startsWith("169.254.")) {  // Skip link-local
                continue;
            }
            
            // Score the interface
            int score = 0;
            
            // Prefer private network ranges used for LAN
            if (ip.startsWith("192.168.") || ip.startsWith("10.") ||
                (ip.startsWith("172.") && ip.section('.', 1, 1).toInt() >= 16 && 
                 ip.section('.', 1, 1).toInt() <= 31)) {
                score += 10;
            }
            
            // Prefer Ethernet over WiFi
            if (name.contains("ethernet") || name.contains("eth") || 
                hwName.startsWith("eth") || name.contains("lan")) {
                score += 5;
            } else if (name.contains("wi-fi") || name.contains("wifi") ||
                       name.contains("wireless") || hwName.startsWith("wlan")) {
                score += 3;
            }
            
            if (score > bestScore) {
                bestScore = score;
                bestAddress = ip;
            }
        }
    }
    
    return bestAddress.isEmpty() ? "127.0.0.1" : bestAddress;
}

QVariantList NetworkManager::availableInterfaces() const {
    QVariantList result;
    const auto interfaces = QNetworkInterface::allInterfaces();
    
    for (const auto& iface : interfaces) {
        if (!iface.flags().testFlag(QNetworkInterface::IsUp) ||
            !iface.flags().testFlag(QNetworkInterface::IsRunning) ||
            iface.flags().testFlag(QNetworkInterface::IsLoopBack)) {
            continue;
        }
        
        const QString name = iface.humanReadableName();
        const QString nameLower = name.toLower();
        const QString hwName = iface.name().toLower();
        
        // Skip virtual adapters
        if (nameLower.contains("vmware") || nameLower.contains("virtualbox") ||
            nameLower.contains("vbox") || nameLower.contains("hyper-v") ||
            nameLower.contains("virtual") || nameLower.contains("docker") ||
            nameLower.contains("vethernet") || nameLower.contains("wsl") ||
            hwName.contains("vmnet") || hwName.contains("vboxnet") ||
            hwName.contains("virbr") || hwName.contains("br-")) {
            continue;
        }
        
        const auto entries = iface.addressEntries();
        for (const auto& entry : entries) {
            if (entry.ip().protocol() != QAbstractSocket::IPv4Protocol) {
                continue;
            }
            
            QString ip = entry.ip().toString();
            if (ip.startsWith("169.254.")) {  // Skip link-local
                continue;
            }
            
            // Determine interface type
            QString type;
            if (nameLower.contains("ethernet") || nameLower.contains("eth") || 
                hwName.startsWith("eth") || nameLower.contains("lan") ||
                nameLower.contains("realtek") || nameLower.contains("intel")) {
                type = "Ethernet";
            } else if (nameLower.contains("wi-fi") || nameLower.contains("wifi") ||
                       nameLower.contains("wireless") || hwName.startsWith("wlan")) {
                type = "WiFi";
            } else {
                type = "Network";
            }
            
            QVariantMap ifaceInfo;
            ifaceInfo["ip"] = ip;
            ifaceInfo["name"] = name;
            ifaceInfo["type"] = type;
            ifaceInfo["displayName"] = QString("%1 (%2)").arg(type, ip);
            result.append(ifaceInfo);
        }
    }
    
    return result;
}

void NetworkManager::startScanning() {
    if (m_isScanning) return;
    
    m_isScanning = true;
    emit scanningChanged();
    
    m_discoveredRooms.clear();
    emit discoveredRoomsChanged();
    
    m_cleanupTimer->start(ROOM_TIMEOUT_MS / 2);
    qDebug() << "[NetworkManager] Started scanning for rooms";
}

void NetworkManager::stopScanning() {
    if (!m_isScanning) return;
    
    m_isScanning = false;
    emit scanningChanged();
    
    m_cleanupTimer->stop();
    qDebug() << "[NetworkManager] Stopped scanning";
}

void NetworkManager::refreshRooms() {
    m_discoveredRooms.clear();
    emit discoveredRoomsChanged();
}

void NetworkManager::startAnnouncing() {
    sendAnnounce();
    m_announceTimer->start(ANNOUNCE_INTERVAL_MS);
}

void NetworkManager::stopAnnouncing() {
    m_announceTimer->stop();
}

void NetworkManager::sendAnnounce() {
    if (!m_isInLobby) return;
    
    QJsonObject msg;
    msg["app"] = APP_IDENTIFIER;
    msg["type"] = "DISCOVERY";
    msg["uuid"] = m_playerId;
    msg["name"] = m_playerName;
    msg["port"] = m_tcpServer ? m_tcpServer->serverPort() : TCP_PORT;
    msg["playerCount"] = m_players.size();
    msg["status"] = m_isInGame ? "racing" : "waiting";
    
    QByteArray data = QJsonDocument(msg).toJson(QJsonDocument::Compact);
    
    // If a specific interface is selected, broadcast only on that interface
    if (!m_selectedInterface.isEmpty()) {
        // Find the broadcast address for the selected interface
        const auto interfaces = QNetworkInterface::allInterfaces();
        for (const auto& iface : interfaces) {
            const auto entries = iface.addressEntries();
            for (const auto& entry : entries) {
                if (entry.ip().toString() == m_selectedInterface) {
                    QHostAddress broadcast = entry.broadcast();
                    if (!broadcast.isNull()) {
                        m_discoverySocket->writeDatagram(data, broadcast, DISCOVERY_PORT);
                        qDebug() << "[NetworkManager] Broadcasting on" << m_selectedInterface << "to" << broadcast.toString();
                        return;
                    }
                }
            }
        }
    }
    
    // Fallback: broadcast on all interfaces
    m_discoverySocket->writeDatagram(data, QHostAddress::Broadcast, DISCOVERY_PORT);
}

void NetworkManager::processDiscoveryDatagram() {
    while (m_discoverySocket->hasPendingDatagrams()) {
        QByteArray data;
        data.resize(m_discoverySocket->pendingDatagramSize());
        QHostAddress sender;
        quint16 senderPort;
        m_discoverySocket->readDatagram(data.data(), data.size(), &sender, &senderPort);
        
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isObject()) continue;
        
        QJsonObject msg = doc.object();
        if (msg["app"].toString() != APP_IDENTIFIER) continue;
        if (msg["type"].toString() != "DISCOVERY") continue;
        
        QString uuid = msg["uuid"].toString();
        
        // Don't process own broadcasts
        if (uuid == m_playerId) continue;
        
        QString hostIp = sender.toString();
        // Clean up IPv4-mapped IPv6 addresses
        if (hostIp.startsWith("::ffff:")) {
            hostIp = hostIp.mid(7);
        }
        
        RoomInfo room;
        room.hostName = msg["name"].toString();
        room.hostIp = hostIp;
        room.hostUuid = uuid;
        room.port = msg["port"].toInt();
        room.playerCount = msg["playerCount"].toInt();
        room.status = msg["status"].toString();
        room.lastSeen = QDateTime::currentMSecsSinceEpoch();
        
        bool isNew = !m_discoveredRooms.contains(uuid);
        m_discoveredRooms[uuid] = room;
        
        if (isNew) {
            emit roomFound(hostIp, room.port, room.hostName);
            emit discoveredRoomsChanged();
            qDebug() << "[NetworkManager] Discovered room:" << room.hostName << "at" << hostIp << ":" << room.port;
        } else if (m_isScanning) {
            emit discoveredRoomsChanged();
        }
    }
}

void NetworkManager::cleanupStaleRooms() {
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    bool changed = false;
    
    auto it = m_discoveredRooms.begin();
    while (it != m_discoveredRooms.end()) {
        if (now - it.value().lastSeen > ROOM_TIMEOUT_MS) {
            qDebug() << "[NetworkManager] Room timed out:" << it.value().hostName;
            it = m_discoveredRooms.erase(it);
            changed = true;
        } else {
            ++it;
        }
    }
    
    if (changed) {
        emit discoveredRoomsChanged();
    }
}

QVariantList NetworkManager::discoveredRooms() const {
    QVariantList list;
    for (const auto& room : m_discoveredRooms) {
        QVariantMap map;
        map["hostName"] = room.hostName;
        map["hostIp"] = room.hostIp;
        map["hostUuid"] = room.hostUuid;
        map["port"] = room.port;
        map["playerCount"] = room.playerCount;
        map["maxPlayers"] = MAX_PLAYERS;
        map["status"] = room.status;
        list.append(map);
    }
    return list;
}

// ============================================================================
// TCP SERVER (MESH)
// ============================================================================

void NetworkManager::startTcpServer() {
    if (m_tcpServer) return;
    
    m_tcpServer = new QTcpServer(this);
    connect(m_tcpServer, &QTcpServer::newConnection, this, &NetworkManager::onNewTcpConnection);
    
    if (!m_tcpServer->listen(QHostAddress::Any, TCP_PORT)) {
        qWarning() << "[NetworkManager] Failed to start TCP server:" << m_tcpServer->errorString();
        setConnectionError("Failed to start server: " + m_tcpServer->errorString());
        delete m_tcpServer;
        m_tcpServer = nullptr;
        return;
    }
    
    qDebug() << "[NetworkManager] TCP Server started on port" << m_tcpServer->serverPort();
}

void NetworkManager::stopTcpServer() {
    if (!m_tcpServer) return;
    
    m_tcpServer->close();
    m_tcpServer->deleteLater();
    m_tcpServer = nullptr;
    qDebug() << "[NetworkManager] TCP Server stopped";
}

void NetworkManager::onNewTcpConnection() {
    while (m_tcpServer && m_tcpServer->hasPendingConnections()) {
        QTcpSocket* socket = m_tcpServer->nextPendingConnection();
        if (!socket) continue;
        
        if (m_peers.size() >= MAX_PLAYERS - 1) {
            qDebug() << "[NetworkManager] Max players reached, rejecting connection";
            socket->close();
            socket->deleteLater();
            continue;
        }
        
        QString peerIp = socket->peerAddress().toString();
        if (peerIp.startsWith("::ffff:")) {
            peerIp = peerIp.mid(7);
        }
        
        // Create peer connection with temporary key until we get UUID
        PeerConnection* peer = new PeerConnection();
        peer->socket = socket;
        peer->ip = peerIp;
        peer->port = socket->peerPort();
        peer->handshakeComplete = false;
        
        // Connect signals
        connect(socket, &QTcpSocket::readyRead, this, &NetworkManager::onPeerReadyRead);
        connect(socket, &QTcpSocket::disconnected, this, &NetworkManager::onPeerDisconnected);
        connect(socket, &QTcpSocket::errorOccurred, this, &NetworkManager::onPeerError);
        
        // Store with temporary key
        QString tempKey = QString("pending_%1:%2").arg(peerIp).arg(socket->peerPort());
        
        // Store properties for lookup
        socket->setProperty("peerPtr", QVariant::fromValue(static_cast<void*>(peer)));
        socket->setProperty("pendingKey", tempKey);
        
        m_peers[tempKey] = peer;
        
        qDebug() << "[NetworkManager] Incoming connection from" << peerIp << "Socket:" << socket;
        qDebug() << "[NetworkManager] Added to m_peers with key:" << tempKey;
        
        // Send our HELLO
        sendHello(peer);
    }
}

// ============================================================================
// PEER CONNECTION
// ============================================================================

bool NetworkManager::connectToPeer(const QString& ip, int port, const QString& uuid) {
    QString key = getPeerKey(ip, port);
    
    // Check if already connected or connecting
    if (m_pendingConnections.contains(key)) {
        qDebug() << "[NetworkManager] Already connecting to" << key;
        return false;
    }
    
    // Check if already connected by UUID
    if (!uuid.isEmpty() && m_peers.contains(uuid)) {
        qDebug() << "[NetworkManager] Already connected to peer" << uuid;
        return false;
    }
    
    // Check if it's ourselves
    if (ip == localIpAddress() && port == (m_tcpServer ? m_tcpServer->serverPort() : TCP_PORT)) {
        qDebug() << "[NetworkManager] Skipping connection to self";
        return false;
    }
    
    m_pendingConnections.insert(key);
    
    QTcpSocket* socket = new QTcpSocket(this);
    
    PeerConnection* peer = new PeerConnection();
    peer->socket = socket;
    peer->uuid = uuid;
    peer->ip = ip;
    peer->port = port;
    peer->handshakeComplete = false;
    
    connect(socket, &QTcpSocket::connected, this, &NetworkManager::onPeerConnected);
    connect(socket, &QTcpSocket::readyRead, this, &NetworkManager::onPeerReadyRead);
    connect(socket, &QTcpSocket::disconnected, this, &NetworkManager::onPeerDisconnected);
    connect(socket, &QTcpSocket::errorOccurred, this, &NetworkManager::onPeerError);
    
    // Store socket in property for lookup in slots
    socket->setProperty("peerPtr", QVariant::fromValue(static_cast<void*>(peer)));
    socket->setProperty("pendingKey", key);
    
    // CRITICAL FIX: Add to m_peers immediately with pending key
    // This matches the behavior of onNewTcpConnection() for incoming connections
    // Without this, onPeerReadyRead() may fail to find the peer for outgoing connections
    m_peers[key] = peer;
    
    qDebug() << "[NetworkManager] Connecting to peer at" << ip << ":" << port;
    qDebug() << "[NetworkManager] Added to m_peers with key:" << key;
    socket->connectToHost(ip, port);
    
    return true;
}

void NetworkManager::onPeerConnected() {
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket) return;
    
    PeerConnection* peer = static_cast<PeerConnection*>(socket->property("peerPtr").value<void*>());
    if (!peer) return;
    
    QString key = socket->property("pendingKey").toString();
    m_pendingConnections.remove(key);
    
    qDebug() << "[NetworkManager] Connected to peer at" << peer->ip;
    
    // Send HELLO packet
    sendHello(peer);
}

void NetworkManager::onPeerDisconnected() {
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket) return;
    
    // Find the peer
    QString disconnectedUuid;
    QString disconnectedName;
    
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.value()->socket == socket) {
            disconnectedUuid = it.value()->uuid;
            disconnectedName = it.value()->name;
            break;
        }
    }
    
    if (!disconnectedUuid.isEmpty()) {
        qDebug() << "[NetworkManager] Peer disconnected:" << disconnectedName << "(" << disconnectedUuid << ")";
        removePeer(disconnectedUuid);
        
        // Remove from players list (critical for race completion check)
        m_players.remove(disconnectedUuid);
        emit playersChanged();
        
        // Notify about player leaving
        if (!disconnectedName.isEmpty()) {
            emit playerLeft(disconnectedName);
        }
        
        // Update authority
        updateAuthority();
        
        // Check if race can now complete (in case player left mid-race)
        checkRaceCompletion();
    } else {
        // Clean up pending connections
        QString pendingKey = socket->property("pendingKey").toString();
        m_pendingConnections.remove(pendingKey);
        
        // Remove from pending peers
        for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
            if (it.value()->socket == socket) {
                delete it.value();
                m_peers.erase(it);
                break;
            }
        }
    }
    
    socket->deleteLater();
}

void NetworkManager::onPeerError(QAbstractSocket::SocketError error) {
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket) return;
    
    qWarning() << "[NetworkManager] Peer socket error:" << error << socket->errorString();
    
    QString pendingKey = socket->property("pendingKey").toString();
    m_pendingConnections.remove(pendingKey);
}

void NetworkManager::onPeerReadyRead() {
    QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket) return;
    
    // Find the peer
    PeerConnection* peer = nullptr;
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.value()->socket == socket) {
            peer = it.value();
            break;
        }
    }
    
    if (!peer) {
        // Fallback for outgoing connections
        peer = static_cast<PeerConnection*>(socket->property("peerPtr").value<void*>());
    }
    
    if (!peer) {
        qDebug() << "[NetworkManager] ERROR: onPeerReadyRead called for unknown socket:" << socket;
        // Print all known sockets
        for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
            qDebug() << "  Known socket:" << it.value()->socket;
        }
        return;
    }
    
    // Append to buffer
    QByteArray newData = socket->readAll();
    peer->readBuffer.append(newData);
    // qDebug() << "[NetworkManager] Read" << newData.size() << "bytes from" << peer->name;
    
    // Process complete packets
    while (peer->readBuffer.size() >= 4) {
        // Read length prefix
        QDataStream stream(peer->readBuffer.left(4));
        stream.setVersion(QDataStream::Qt_6_0);
        quint32 packetSize;
        stream >> packetSize;
        
        if (peer->readBuffer.size() < static_cast<int>(4 + packetSize)) {
            // Wait for more data
            break;
        }
        
        // Extract packet data
        QByteArray packetData = peer->readBuffer.mid(4, packetSize);
        peer->readBuffer.remove(0, 4 + packetSize);
        
        // Deserialize and process
        Packet packet = Packet::deserialize(packetData);
        processPacket(peer, packet);
    }
}

void NetworkManager::removePeer(const QString& uuid) {
    if (!m_peers.contains(uuid)) return;
    
    PeerConnection* peer = m_peers.take(uuid);
    if (peer->socket) {
        peer->socket->disconnect();
        peer->socket->close();
        peer->socket->deleteLater();
    }
    delete peer;
    
    // Remove from players list
    m_players.remove(uuid);
    emit playersChanged();
    emit peersChanged();
}

QString NetworkManager::getPeerKey(const QString& ip, int port) const {
    return QString("%1:%2").arg(ip).arg(port);
}

// ============================================================================
// HANDSHAKE & MESH
// ============================================================================

void NetworkManager::sendHello(PeerConnection* peer) {
    QJsonObject payload;
    payload["name"] = m_playerName;
    payload["port"] = m_tcpServer ? m_tcpServer->serverPort() : TCP_PORT;
    payload["isRoomCreator"] = m_isRoomCreator;
    payload["hostUuid"] = m_hostUuid.isEmpty() ? m_playerId : m_hostUuid;
    
    Packet packet = createPacket(PacketType::HELLO, payload);
    sendToPeer(peer, packet);
}

void NetworkManager::handleHello(PeerConnection* peer, const Packet& packet) {
    peer->uuid = packet.senderUuid;
    peer->name = packet.payload["name"].toString();
    peer->port = packet.payload["port"].toInt();
    peer->handshakeComplete = true;
    
    // Learn about host from the packet
    bool peerIsRoomCreator = packet.payload["isRoomCreator"].toBool();
    QString peerHostUuid = packet.payload["hostUuid"].toString();
    
    qDebug() << "[NetworkManager] Received HELLO from" << peer->name << "(" << peer->uuid << ")"
             << "isRoomCreator:" << peerIsRoomCreator << "hostUuid:" << peerHostUuid;
    
    // If we don't know who the host is yet (we're a guest joining), learn it
    if (!m_isRoomCreator && m_hostUuid.isEmpty() && !peerHostUuid.isEmpty()) {
        m_hostUuid = peerHostUuid;
        qDebug() << "[NetworkManager] Learned host UUID:" << m_hostUuid;
    }
    
    // Move from temporary key to UUID key if needed
    QString tempKey;
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.value() == peer && it.key() != peer->uuid) {
            tempKey = it.key();
            break;
        }
    }
    
    if (!tempKey.isEmpty()) {
        m_peers.remove(tempKey);
        
        // Check for duplicate connections (both sides connected simultaneously)
        if (m_peers.contains(peer->uuid)) {
            // Use UUID comparison to decide who keeps the connection
            if (m_playerId < peer->uuid) {
                // We initiated, keep our connection, close theirs
                qDebug() << "[NetworkManager] Duplicate connection detected, keeping ours";
                PeerConnection* existing = m_peers[peer->uuid];
                delete peer;
                peer = existing;
            } else {
                // They initiated, close our connection, keep theirs
                qDebug() << "[NetworkManager] Duplicate connection detected, keeping theirs";
                PeerConnection* existing = m_peers[peer->uuid];
                existing->socket->disconnect();
                existing->socket->close();
                existing->socket->deleteLater();
                delete existing;
                m_peers[peer->uuid] = peer;
            }
        } else {
            m_peers[peer->uuid] = peer;
        }
    }
    
    // If we were connecting to this peer, complete the join process
    if (m_isConnecting && peer->ip == m_pendingJoinIp) {
        m_isConnecting = false;
        m_connectionTimeoutTimer->stop();
        
        m_isInLobby = true;
        m_isConnected = true;
        
        emit connectingChanged();
        emit lobbyStateChanged();
        emit connectionChanged();
        emit joinSucceeded();
        
        qDebug() << "[NetworkManager] Join successful to" << peer->name;
    }
    
    // Add to players
    PlayerInfo playerInfo;
    playerInfo.uuid = peer->uuid;
    playerInfo.name = peer->name;
    m_players[peer->uuid] = playerInfo;
    
    emit playerJoined(peer->name);
    emit playersChanged();
    emit peersChanged();
    
    // Send peer list to complete mesh
    sendPeerList(peer);
    
    // If we are the room creator (host), send the current game text to the new player
    if (m_isRoomCreator && !m_gameText.isEmpty()) {
        QJsonObject textPayload;
        textPayload["text"] = m_gameText;
        textPayload["language"] = m_gameLanguage;
        Packet textPacket = createPacket(PacketType::GAME_TEXT, textPayload);
        sendToPeer(peer, textPacket);
        qDebug() << "[NetworkManager] Sent game text to new player" << peer->name;
    }
    
    // Update authority (no-op now since it's based on room creator, but emit signal)
    updateAuthority();
}

void NetworkManager::sendPeerList(PeerConnection* peer) {
    QJsonArray peerArray;
    
    // Add all known peers (except the one we're sending to)
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.key() == peer->uuid) continue;
        if (!it.value()->handshakeComplete) continue;
        
        QJsonObject peerObj;
        peerObj["uuid"] = it.value()->uuid;
        peerObj["name"] = it.value()->name;
        peerObj["ip"] = it.value()->ip;
        peerObj["port"] = it.value()->port;
        peerArray.append(peerObj);
    }
    
    // Also add ourselves
    QJsonObject selfObj;
    selfObj["uuid"] = m_playerId;
    selfObj["name"] = m_playerName;
    selfObj["ip"] = localIpAddress();
    selfObj["port"] = m_tcpServer ? m_tcpServer->serverPort() : TCP_PORT;
    // Don't add self, they already know us
    
    QJsonObject payload;
    payload["peers"] = peerArray;
    
    Packet packet = createPacket(PacketType::PEER_LIST, payload);
    sendToPeer(peer, packet);
}

void NetworkManager::handlePeerList(const Packet& packet) {
    QJsonArray peerArray = packet.payload["peers"].toArray();
    qDebug() << "[NetworkManager] Received PEER_LIST with" << peerArray.size() << "peers";
    
    connectToMissingPeers(peerArray);
}

void NetworkManager::connectToMissingPeers(const QJsonArray& peerList) {
    for (const auto& peerVal : peerList) {
        QJsonObject peerObj = peerVal.toObject();
        QString uuid = peerObj["uuid"].toString();
        QString ip = peerObj["ip"].toString();
        int port = peerObj["port"].toInt();
        
        // Skip if it's us
        if (uuid == m_playerId) continue;
        
        // Skip if already connected
        if (m_peers.contains(uuid)) continue;
        
        // Connect to this peer
        qDebug() << "[NetworkManager] Connecting to missing peer:" << uuid << "at" << ip << ":" << port;
        connectToPeer(ip, port, uuid);
    }
}

// ============================================================================
// PACKET PROCESSING
// ============================================================================

void NetworkManager::processPacket(PeerConnection* peer, const Packet& packet) {
    // Log selected packet types to debug
    if (packet.type == PacketType::PROGRESS_UPDATE) {
        // Throttled logging
        static int procLogCounter = 0;
        if (procLogCounter++ % 20 == 0) {
            qDebug() << "[NetworkManager] Processing PROGRESS_UPDATE from" << packet.senderUuid;
        }
    } else if (packet.type != PacketType::PROGRESS_UPDATE) {
         // Log others normally (except maybe repeated ones)
         // qDebug() << "[NetworkManager] Processing packet type" << (int)packet.type << "from" << packet.senderUuid;
    }

    switch (packet.type) {
        case PacketType::HELLO:
            handleHello(peer, packet);
            break;
        case PacketType::PEER_LIST:
            handlePeerList(packet);
            break;
        case PacketType::GAME_START:
            handleGameStart(packet);
            break;
        case PacketType::PROGRESS_UPDATE:
            handleProgressUpdate(peer, packet);
            break;
        case PacketType::FINISH:
            handleFinish(peer, packet);
            break;
        case PacketType::GAME_TEXT:
            handleGameText(packet);
            break;
        case PacketType::COUNTDOWN:
            handleCountdown(packet);
            break;
        case PacketType::PLAYER_LEFT:
            handlePlayerLeft(packet);
            break;
        case PacketType::RACE_RESULTS:
            handleRaceResults(packet);
            break;
        case PacketType::READY_CHECK:
            handleReadyCheck(packet);
            break;
        case PacketType::READY_RESPONSE:
            handleReadyResponse(packet);
            break;
        case PacketType::PLAY_AGAIN_INVITE:
            handlePlayAgainInvite(packet);
            break;
        case PacketType::PLAY_AGAIN_RESPONSE:
            handlePlayAgainResponse(peer, packet);
            break;
    }
}

void NetworkManager::broadcastToAllPeers(const Packet& packet) {
    QByteArray data = packet.serialize();
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.value()->socket && it.value()->socket->state() == QAbstractSocket::ConnectedState) {
            it.value()->socket->write(data);
            it.value()->socket->flush();
        }
    }
}

void NetworkManager::sendToPeer(PeerConnection* peer, const Packet& packet) {
    if (!peer || !peer->socket) return;
    if (peer->socket->state() != QAbstractSocket::ConnectedState) return;
    
    QByteArray data = packet.serialize();
    peer->socket->write(data);
    peer->socket->flush();
}

// ============================================================================
// AUTHORITY (Room Creator Based)
// ============================================================================

void NetworkManager::updateAuthority() {
    bool wasAuthority = m_isAuthority;
    
    // If we are the original room creator, we have authority
    if (m_isRoomCreator) {
        m_isAuthority = true;
    }
    // Otherwise, check if the host has left and we need to elect new authority
    else if (!m_hostUuid.isEmpty() && !m_players.contains(m_hostUuid)) {
        // Host is gone! We need to elect a new authority
        // The first player (by UUID sort) becomes new authority
        if (!m_players.isEmpty()) {
            QStringList uuids = m_players.keys();
            uuids.sort();
            if (uuids.first() == m_playerId) {
                // We are the new authority!
                m_isAuthority = true;
                m_hostUuid = m_playerId;  // Update host UUID to self
                qDebug() << "[NetworkManager] Authority transferred to us! We are now the host.";
            } else {
                m_isAuthority = false;
            }
        } else {
            m_isAuthority = false;
        }
    } else {
        // Normal case: we are a guest
        m_isAuthority = false;
    }
    
    if (wasAuthority != m_isAuthority) {
        qDebug() << "[NetworkManager] Authority status:" << (m_isAuthority ? "HOST (Authority)" : "GUEST");
        emit authorityChanged();
    }
}

// ============================================================================
// ROOM FUNCTIONS
// ============================================================================

bool NetworkManager::createRoom() {
    if (m_isInLobby || m_isConnected) return false;
    
    startTcpServer();
    if (!m_tcpServer) return false;
    
    m_isInLobby = true;
    m_isConnected = true;
    m_isRoomCreator = true;   // We created the room, we are the HOST
    m_isAuthority = true;      // Room creator is always authority
    m_hostUuid = m_playerId;   // We are the host
    
    // Add self to players
    PlayerInfo self;
    self.uuid = m_playerId;
    self.name = m_playerName;
    m_players[m_playerId] = self;
    
    startAnnouncing();
    
    emit lobbyStateChanged();
    emit connectionChanged();
    emit authorityChanged();
    emit playersChanged();
    
    qDebug() << "[NetworkManager] Room created. I am the HOST (room creator).";
    
    return true;
}

void NetworkManager::closeRoom() {
    // CRITICAL: Stop timers FIRST to prevent callbacks during cleanup
    m_progressTimer->stop();
    if (m_readyCheckTimer) {
        m_readyCheckTimer->stop();
    }
    if (m_connectionTimeoutTimer) {
        m_connectionTimeoutTimer->stop();
    }
    
    // Improved guard: only cleanup if we have state to cleanup
    if (!m_isInLobby && !m_isInGame && !m_isConnected) {
        qDebug() << "[NetworkManager] closeRoom: No state to cleanup";
        return;
    }
    
    qDebug() << "[NetworkManager] Closing room...";
    
    stopAnnouncing();
    
    // Disconnect all peers
    for (auto it = m_peers.begin(); it != m_peers.end(); ++it) {
        if (it.value()->socket) {
            it.value()->socket->disconnect();  // Disconnect signals first
            it.value()->socket->close();
            it.value()->socket->deleteLater();
        }
        delete it.value();
    }
    m_peers.clear();
    
    stopTcpServer();
    resetState();
    
    qDebug() << "[NetworkManager] Room closed successfully";
}

bool NetworkManager::joinRoom(const QString& hostIp, int port) {
    if (m_isInLobby || m_isConnected || m_isConnecting) return false;
    
    // Validate IP format
    QHostAddress addr;
    if (!addr.setAddress(hostIp)) {
        emit joinFailed("Invalid IP address format: " + hostIp);
        return false;
    }
    
    // Store pending connection info
    m_pendingJoinIp = hostIp;
    m_pendingJoinPort = port;
    
    // Set connecting state - we are joining, NOT creating
    m_isConnecting = true;
    m_isRoomCreator = false;  // We are a GUEST, not the host
    m_isAuthority = false;     // Guests never have authority
    m_hostUuid.clear();        // Will be learned from host's HELLO
    emit connectingChanged();
    
    stopScanning();
    startTcpServer();  // We also need to accept connections for mesh
    
    // Add self to players (temporarily, will be cleaned up on failure)
    PlayerInfo self;
    self.uuid = m_playerId;
    self.name = m_playerName;
    m_players[m_playerId] = self;
    
    // Start connection timeout (5 seconds)
    m_connectionTimeoutTimer->start(5000);
    
    // Connect to the host
    bool result = connectToPeer(hostIp, port);
    
    if (!result) {
        m_connectionTimeoutTimer->stop();
        m_isConnecting = false;
        emit connectingChanged();
        resetState();
        emit joinFailed("Failed to initiate connection to " + hostIp);
        return false;
    }
    
    qDebug() << "[NetworkManager] Attempting to join room at" << hostIp << ":" << port;
    return true;
}

void NetworkManager::leaveRoom() {
    closeRoom();
}

// ============================================================================
// GAME CONTROL
// ============================================================================

void NetworkManager::setGameText(const QString& text) {
    if (!m_isRoomCreator) return;  // Only host can set game text
    
    m_gameText = text;
    emit gameTextChanged();
    
    QJsonObject payload;
    payload["text"] = text;
    payload["language"] = m_gameLanguage;
    
    Packet packet = createPacket(PacketType::GAME_TEXT, payload);
    broadcastToAllPeers(packet);
}

void NetworkManager::setGameLanguage(const QString& language) {
    if (!m_isRoomCreator) return;  // Only host can change language
    if (m_gameLanguage == language) return;
    
    m_gameLanguage = language;
    emit gameLanguageChanged();
    
    // Auto-refresh text when language changes
    refreshGameText();
}

void NetworkManager::refreshGameText() {
    if (!m_isRoomCreator) return;  // Only host can refresh text
    
    // Use GameBackend to generate text based on language
    GameBackend* backend = GameBackend::instance();
    if (backend) {
        // Use medium difficulty with 20 words for multiplayer
        QString text = backend->getRandomText(m_gameLanguage, "medium", 20);
        setGameText(text);
    }
}

void NetworkManager::startCountdown() {
    if (!m_isRoomCreator) {
        qDebug() << "[NetworkManager] Only room creator (host) can start the game";
        return;
    }
    
    // Ensure we have game text
    if (m_gameText.isEmpty()) {
        qDebug() << "[NetworkManager] Cannot start: no game text set";
        return;
    }
    
    // If no other players, start immediately
    if (m_peers.isEmpty()) {
        qDebug() << "[NetworkManager] Solo mode - starting immediately";
        beginCountdown();
        return;
    }
    
    // Reset race state for all players
    m_finishedCount = 0;
    m_localFinished = false;
    for (auto it = m_players.begin(); it != m_players.end(); ++it) {
        it.value().position = 0;
        it.value().totalChars = 0;
        it.value().wpm = 0;
        it.value().finished = false;
        it.value().racePosition = 0;
        it.value().finishTime = 0;
    }
    emit playersChanged();
    
    // Initialize ready check state
    m_playersReady.clear();
    m_playersReady[m_playerId] = true;  // Host is ready
    m_isWaitingForReady = true;
    emit waitingForReadyChanged();
    
    // Send READY_CHECK to all peers with the game text to ensure sync
    QJsonObject payload;
    payload["text"] = m_gameText;
    payload["language"] = m_gameLanguage;
    
    Packet packet = createPacket(PacketType::READY_CHECK, payload);
    broadcastToAllPeers(packet);
    
    qDebug() << "[NetworkManager] Sent READY_CHECK to" << m_peers.size() << "peers, waiting for responses...";
    
    // Start timeout timer (5 seconds to respond)
    m_readyCheckTimer->start(5000);
}

void NetworkManager::handleReadyCheck(const Packet& packet) {
    // Guest received ready check from host
    // Sync the game text and language
    QString text = packet.payload["text"].toString();
    QString lang = packet.payload["language"].toString();
    
    if (m_gameText != text) {
        m_gameText = text;
        emit gameTextChanged();
    }
    if (m_gameLanguage != lang) {
        m_gameLanguage = lang;
        emit gameLanguageChanged();
    }
    
    qDebug() << "[NetworkManager] Received READY_CHECK, synced text (" << text.length() << "chars), sending READY_RESPONSE";
    
    // Send ready response back
    Packet response = createPacket(PacketType::READY_RESPONSE);
    broadcastToAllPeers(response);
}

void NetworkManager::handleReadyResponse(const Packet& packet) {
    if (!m_isRoomCreator || !m_isWaitingForReady) {
        return;  // Only host should process ready responses during ready check
    }
    
    QString senderId = packet.senderUuid;
    m_playersReady[senderId] = true;
    
    qDebug() << "[NetworkManager] Received READY_RESPONSE from" << senderId 
             << "(" << m_playersReady.size() << "/" << m_players.size() << "ready)";
    
    // Check if all players are ready
    if (m_playersReady.size() >= m_players.size()) {
        m_readyCheckTimer->stop();
        m_isWaitingForReady = false;
        emit waitingForReadyChanged();
        emit allPlayersReady();
        
        qDebug() << "[NetworkManager] All players ready! Starting countdown.";
        beginCountdown();
    }
}

void NetworkManager::onReadyCheckTimeout() {
    if (!m_isWaitingForReady) return;
    
    qDebug() << "[NetworkManager] Ready check timeout! Only" << m_playersReady.size() 
             << "/" << m_players.size() << "players responded.";
    
    // Start anyway with whoever responded
    m_isWaitingForReady = false;
    emit waitingForReadyChanged();
    
    // Log who didn't respond
    for (const auto& player : m_players) {
        if (!m_playersReady.contains(player.uuid)) {
            qDebug() << "[NetworkManager] Player did not respond:" << player.name;
        }
    }
    
    beginCountdown();
}

void NetworkManager::beginCountdown() {
    // Broadcast countdown start to all peers
    QJsonObject payload;
    payload["seconds"] = 3;
    
    Packet packet = createPacket(PacketType::COUNTDOWN, payload);
    broadcastToAllPeers(packet);
    emit countdownStarted(3);
    
    // After 3 seconds, start game
    QTimer::singleShot(3000, this, [this]() {
        m_isInGame = true;
        emit gameStateChanged();
        
        Packet startPacket = createPacket(PacketType::GAME_START);
        broadcastToAllPeers(startPacket);
        emit gameStarted();
        
        // Start sending progress updates
        m_progressTimer->start(PROGRESS_UPDATE_MS);
    });
}

void NetworkManager::kickPlayer(const QString& uuid) {
    if (!m_isRoomCreator) return;  // Only host can kick players
    if (!m_peers.contains(uuid)) return;
    
    PeerConnection* peer = m_peers[uuid];
    QString name = peer->name;
    
    // Notify others
    QJsonObject payload;
    payload["uuid"] = uuid;
    payload["name"] = name;
    Packet packet = createPacket(PacketType::PLAYER_LEFT, payload);
    broadcastToAllPeers(packet);
    
    // Disconnect the peer
    removePeer(uuid);
    emit playerLeft(name);
}

// ============================================================================
// GAME LOGIC HANDLERS
// ============================================================================

void NetworkManager::handleGameStart(const Packet& packet) {
    Q_UNUSED(packet)
    m_isInGame = true;
    emit gameStateChanged();
    emit gameStarted();
    
    m_progressTimer->start(PROGRESS_UPDATE_MS);
}

void NetworkManager::handleGameText(const Packet& packet) {
    m_gameText = packet.payload["text"].toString();
    emit gameTextChanged();
    
    // Sync language if provided
    if (packet.payload.contains("language")) {
        QString lang = packet.payload["language"].toString();
        if (m_gameLanguage != lang) {
            m_gameLanguage = lang;
            emit gameLanguageChanged();
        }
    }
}

void NetworkManager::handleCountdown(const Packet& packet) {
    int seconds = packet.payload["seconds"].toInt();
    emit countdownStarted(seconds);
}

void NetworkManager::handlePlayerLeft(const Packet& packet) {
    QString uuid = packet.payload["uuid"].toString();
    QString name = packet.payload["name"].toString();
    
    m_players.remove(uuid);
    emit playerLeft(name);
    emit playersChanged();
    
    // Remove peer if we have it
    if (m_peers.contains(uuid)) {
        removePeer(uuid);
    }
    
    updateAuthority();
    checkRaceCompletion();
}

void NetworkManager::handleRaceResults(const Packet& packet) {
    QVariantList rankings;
    QJsonArray arr = packet.payload["rankings"].toArray();
    for (const auto& r : arr) {
        rankings.append(r.toObject().toVariantMap());
    }
    
    // Store rankings as property
    m_rankings = rankings;
    emit rankingsChanged();
    
    emit raceFinished(rankings);
    
    m_isInGame = false;
    emit gameStateChanged();
    m_progressTimer->stop();
}

// ============================================================================
// PROGRESS & RACE
// ============================================================================

void NetworkManager::updateProgress(int position, int totalChars, int wpm) {
    m_currentPosition = position;
    m_currentTotal = totalChars;
    m_currentWpm = wpm;
    
    // Update local player state
    if (m_players.contains(m_playerId)) {
        m_players[m_playerId].position = position;
        m_players[m_playerId].totalChars = totalChars;
        m_players[m_playerId].wpm = wpm;
    }
    
    // Notify UI of local changes immediately
    emit playersChanged();
}

void NetworkManager::finishRace(int wpm, double accuracy, int errors) {
    Q_UNUSED(errors)
    
    m_localFinished = true;
    m_finishedCount++;
    
    if (m_players.contains(m_playerId)) {
        m_players[m_playerId].finished = true;
        m_players[m_playerId].finishTime = QDateTime::currentMSecsSinceEpoch();
        m_players[m_playerId].racePosition = m_finishedCount;
        m_players[m_playerId].wpm = wpm;
        m_players[m_playerId].accuracy = accuracy;
    }
    
    // Broadcast finish with accuracy
    QJsonObject payload;
    payload["wpm"] = wpm;
    payload["accuracy"] = accuracy;
    payload["position"] = m_finishedCount;
    
    Packet packet = createPacket(PacketType::FINISH, payload);
    broadcastToAllPeers(packet);
    
    checkRaceCompletion();
}

void NetworkManager::sendProgressUpdate() {
    if (!m_isInGame) return;
    
    QJsonObject payload;
    payload["position"] = m_currentPosition;
    payload["total"] = m_currentTotal;
    payload["wpm"] = m_currentWpm;
    payload["finished"] = m_localFinished;
    
    Packet packet = createPacket(PacketType::PROGRESS_UPDATE, payload);
    
    // Debug log to verify sending (throttled to avoid spam)
    static int sendLogCounter = 0;
    if (sendLogCounter++ % 20 == 0) {
        qDebug() << "[NetworkManager] Sending PROGRESS_UPDATE: pos=" << m_currentPosition 
                 << " total=" << m_currentTotal << " wpm=" << m_currentWpm;
    }
    
    broadcastToAllPeers(packet);
}

void NetworkManager::handleProgressUpdate(PeerConnection* peer, const Packet& packet) {
    QString playerId = packet.senderUuid;
    
    if (!m_players.contains(playerId)) {
        qDebug() << "[NetworkManager] WARN: Ignoring PROGRESS_UPDATE from unknown player:" << playerId;
         // Print known keys for debugging
         qDebug() << "[NetworkManager] Known players:" << m_players.keys();
        return;
    }
    
    auto& player = m_players[playerId];
    player.position = packet.payload["position"].toInt();
    player.totalChars = packet.payload["total"].toInt();
    player.wpm = packet.payload["wpm"].toInt();
    player.finished = packet.payload["finished"].toBool();
    
    // Debug log
    static int recvLogCounter = 0;
    if (recvLogCounter++ % 20 == 0) {
        qDebug() << "[NetworkManager] Updated progress for" << player.name 
                 << "pos=" << player.position << "finished=" << player.finished;
    }
    
    double progress = player.totalChars > 0 ? 
                     static_cast<double>(player.position) / player.totalChars : 0.0;
    
    emit playerProgressUpdated(playerId, player.name, progress, player.wpm, 
                               player.finished, player.racePosition);
                               
    // Notify UI to update track positions
    emit playersChanged();
}

void NetworkManager::handleFinish(PeerConnection* peer, const Packet& packet) {
    Q_UNUSED(peer)
    QString playerId = packet.senderUuid;
    
    if (!m_players.contains(playerId)) return;
    
    auto& player = m_players[playerId];
    bool wasFinished = player.finished;
    
    if (!wasFinished) {
        m_finishedCount++;
        player.finished = true;
        player.finishTime = QDateTime::currentMSecsSinceEpoch();
        player.racePosition = m_finishedCount;
        player.wpm = packet.payload["wpm"].toInt();
        player.accuracy = packet.payload["accuracy"].toDouble(100.0);
        
        emit playerProgressUpdated(playerId, player.name, 1.0, player.wpm, 
                                   true, player.racePosition);
                                   
        // Notify UI of finish state
        emit playersChanged();
    }
    
    checkRaceCompletion();
}

void NetworkManager::checkRaceCompletion() {
    // Check if all players have finished
    bool allFinished = true;
    for (const auto& player : m_players) {
        if (!player.finished) {
            allFinished = false;
            break;
        }
    }
    
    if (allFinished && m_isAuthority) {
        // Build rankings
        QList<PlayerInfo> sorted = m_players.values();
        std::sort(sorted.begin(), sorted.end(), [](const PlayerInfo& a, const PlayerInfo& b) {
            return a.racePosition < b.racePosition;
        });
        
        QVariantList rankings;
        for (const auto& player : sorted) {
            QVariantMap map;
            map["id"] = player.uuid;
            map["name"] = player.name;
            map["wpm"] = player.wpm;
            map["accuracy"] = player.accuracy;
            map["position"] = player.racePosition;
            rankings.append(map);
        }
        
        // Store rankings as property
        m_rankings = rankings;
        emit rankingsChanged();
        
        // Broadcast results
        QJsonArray arr;
        for (const auto& r : rankings) {
            arr.append(QJsonObject::fromVariantMap(r.toMap()));
        }
        QJsonObject payload;
        payload["rankings"] = arr;
        
        Packet packet = createPacket(PacketType::RACE_RESULTS, payload);
        broadcastToAllPeers(packet);
        
        emit raceFinished(rankings);
        
        // End game state
        m_isInGame = false;
        emit gameStateChanged();
        m_progressTimer->stop();
    }
}

// ============================================================================
// UTILITIES
// ============================================================================

QVariantList NetworkManager::players() const {
    QVariantList list;
    for (const auto& player : m_players) {
        QVariantMap map;
        map["id"] = player.uuid;
        map["name"] = player.name;
        // A player is the host if they are the room creator (m_hostUuid)
        // If we know the hostUuid, compare against it; otherwise for self-check use m_isRoomCreator
        bool isPlayerHost = (m_hostUuid.isEmpty()) 
            ? (player.uuid == m_playerId && m_isRoomCreator)
            : (player.uuid == m_hostUuid);
        map["isHost"] = isPlayerHost;
        map["isLocal"] = (player.uuid == m_playerId);
        map["progress"] = player.totalChars > 0 ? 
                         static_cast<double>(player.position) / player.totalChars : 0.0;
        map["wpm"] = player.wpm;
        map["finished"] = player.finished;
        map["position"] = player.racePosition;
        list.append(map);
    }
    return list;
}

void NetworkManager::setPlayerName(const QString& name) {
    if (m_playerName == name) return;
    m_playerName = name;
    emit playerNameChanged();
}

void NetworkManager::setConnectionError(const QString& error) {
    m_connectionError = error;
    emit connectionErrorChanged();
    qWarning() << "[NetworkManager] Error:" << error;
}

void NetworkManager::resetState() {
    m_isAuthority = false;
    m_isRoomCreator = false;
    m_isConnected = false;
    m_isInGame = false;
    m_isInLobby = false;
    m_hostUuid.clear();
    m_players.clear();
    m_gameText.clear();
    m_currentPosition = 0;
    m_currentTotal = 0;
    m_currentWpm = 0;
    m_localFinished = false;
    m_finishedCount = 0;
    m_pendingConnections.clear();
    m_rankings.clear();
    
    // Ready check state
    m_isWaitingForReady = false;
    m_playersReady.clear();
    if (m_readyCheckTimer) {
        m_readyCheckTimer->stop();
    }
    
    m_progressTimer->stop();
    
    emit authorityChanged();
    emit connectionChanged();
    emit gameStateChanged();
    emit lobbyStateChanged();
    emit playersChanged();
    emit gameTextChanged();
    emit peersChanged();
    emit waitingForReadyChanged();
    emit rankingsChanged();
}

void NetworkManager::setSelectedInterface(const QString& ip) {
    if (m_selectedInterface == ip) return;
    
    m_selectedInterface = ip;
    emit selectedInterfaceChanged();
    
    qDebug() << "[NetworkManager] Selected interface:" << (ip.isEmpty() ? "All interfaces" : ip);
    
    // If already hosting, restart announcing on new interface
    if (m_isInLobby && m_isAuthority) {
        sendAnnounce();
    }
}

// ============================================================================
// PLAY AGAIN FUNCTIONALITY
// ============================================================================

void NetworkManager::returnToLobby() {
    qDebug() << "[NetworkManager] Returning to lobby (keeping connection)";
    
    // Reset game state but keep connection alive
    m_isInGame = false;
    m_localFinished = false;
    m_finishedCount = 0;
    m_currentPosition = 0;
    m_currentTotal = 0;
    m_currentWpm = 0;
    
    // Reset player race state while keeping player info
    for (auto& player : m_players) {
        player.position = 0;
        player.totalChars = 0;
        player.wpm = 0;
        player.accuracy = 100.0;
        player.finished = false;
        player.racePosition = 0;
        player.finishTime = 0;
    }
    
    // Stop progress timer
    m_progressTimer->stop();
    
    // Clear rankings
    m_rankings.clear();
    
    // Generate new text for next race
    if (m_isRoomCreator) {
        refreshGameText();
    }
    
    emit gameStateChanged();
    emit playersChanged();
    emit rankingsChanged();
    emit returnedToLobby();
    
    qDebug() << "[NetworkManager] Returned to lobby successfully";
}

void NetworkManager::sendPlayAgainInvite() {
    if (!m_isRoomCreator) {
        qDebug() << "[NetworkManager] Only host can send play again invite";
        return;
    }
    
    qDebug() << "[NetworkManager] Sending play again invite to guests";
    
    // Return host to lobby first
    returnToLobby();
    
    // Broadcast invite to all peers
    Packet packet = createPacket(PacketType::PLAY_AGAIN_INVITE);
    broadcastToAllPeers(packet);
}

void NetworkManager::acceptPlayAgain() {
    qDebug() << "[NetworkManager] Accepting play again invite";
    
    // Return to lobby
    returnToLobby();
    
    // Send response to host
    QJsonObject payload;
    payload["accepted"] = true;
    payload["name"] = m_playerName;
    
    Packet packet = createPacket(PacketType::PLAY_AGAIN_RESPONSE, payload);
    broadcastToAllPeers(packet);
}

void NetworkManager::declinePlayAgain() {
    qDebug() << "[NetworkManager] Declining play again invite";
    
    // Send decline response first
    QJsonObject payload;
    payload["accepted"] = false;
    payload["name"] = m_playerName;
    
    Packet packet = createPacket(PacketType::PLAY_AGAIN_RESPONSE, payload);
    broadcastToAllPeers(packet);
    
    // Then leave the room
    leaveRoom();
}

void NetworkManager::handlePlayAgainInvite(const Packet& packet) {
    Q_UNUSED(packet)
    
    if (m_isRoomCreator) {
        // Host doesn't receive own invite
        return;
    }
    
    qDebug() << "[NetworkManager] Received play again invite from host";
    emit playAgainInviteReceived();
}

void NetworkManager::handlePlayAgainResponse(PeerConnection* peer, const Packet& packet) {
    if (!m_isRoomCreator) {
        // Only host processes responses
        return;
    }
    
    bool accepted = packet.payload["accepted"].toBool();
    QString playerName = packet.payload["name"].toString();
    
    if (playerName.isEmpty() && peer) {
        playerName = peer->name;
    }
    
    if (accepted) {
        qDebug() << "[NetworkManager] Player" << playerName << "accepted play again";
        emit playAgainAccepted(playerName);
    } else {
        qDebug() << "[NetworkManager] Player" << playerName << "declined play again";
        emit playAgainDeclined(playerName);
    }
}
