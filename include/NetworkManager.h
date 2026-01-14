/**
 * @file NetworkManager.h
 * @brief Network Manager untuk multiplayer Peer-to-Peer (P2P) Full Mesh di Rapid Texter.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details NetworkManager bertanggung jawab untuk mengelola seluruh komunikasi jaringan
 * dalam mode multiplayer Rapid Texter. Menggunakan arsitektur P2P Full Mesh dimana
 * setiap klien terhubung langsung ke semua klien lainnya.
 *
 * @section arch Arsitektur Jaringan
 * - **Discovery**: UDP Broadcast pada port 52766 untuk penemuan ruangan di LAN
 * - **Transport**: TCP pada port 52765 untuk koneksi mesh yang reliable
 * - **Authority**: Floating Authority berdasarkan aturan UUID terendah (deterministik)
 *
 * @section flow Alur Koneksi
 * 1. Host membuat room dan memulai broadcasting UDP
 * 2. Guest menerima broadcast dan melihat room di daftar
 * 3. Guest memilih room dan terhubung via TCP
 * 4. Handshake HELLO dilakukan untuk pertukaran identitas
 * 5. Peer list dikirim untuk membentuk mesh penuh
 *
 * @section packets Tipe Paket
 * - HELLO: Handshake awal dengan informasi pemain
 * - PEER_LIST: Daftar peer untuk pembentukan mesh
 * - GAME_START: Sinyal mulai permainan
 * - PROGRESS_UPDATE: Update progres mengetik real-time (50ms interval)
 * - FINISH: Notifikasi pemain selesai mengetik
 * - GAME_TEXT: Distribusi teks game dari host
 * - COUNTDOWN: Countdown sinkron sebelum race
 * - PLAYER_LEFT: Notifikasi pemain keluar
 * - RACE_RESULTS: Hasil akhir race dengan ranking
 * - READY_CHECK/RESPONSE: Mekanisme ready check sebelum mulai
 * - PLAY_AGAIN_INVITE/RESPONSE: Sistem undangan main lagi
 * - KICK: Pemain di-kick oleh host
 *
 * @note Maksimum 8 pemain per room untuk performa optimal
 */

#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QDataStream>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QObject>
#include <QQmlEngine>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimer>
#include <QUdpSocket>
#include <QUuid>

/**
 * @class NetworkManager
 * @brief Singleton manager untuk komunikasi jaringan multiplayer P2P Full Mesh.
 *
 * @details NetworkManager menyediakan abstraksi lengkap untuk:
 * - Penemuan ruangan via UDP broadcast
 * - Koneksi mesh antar peer via TCP
 * - Sinkronisasi state permainan
 * - Manajemen authority (host)
 * - Update progres real-time
 *
 * Kelas ini diekspos ke QML sebagai singleton sehingga dapat diakses
 * dari mana saja dalam aplikasi.
 *
 * @par Contoh Penggunaan di QML:
 * @code{.qml}
 * // Membuat room sebagai host
 * NetworkManager.playerName = "PlayerOne"
 * NetworkManager.createRoom()
 *
 * // Bergabung ke room yang ada
 * NetworkManager.joinRoom("192.168.1.100", 52765)
 *
 * // Memulai game (hanya host)
 * NetworkManager.startCountdown()
 * @endcode
 */
class NetworkManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  // === QML PROPERTIES ===
  
  /**
   * @property isAuthority
   * @brief Menandakan apakah klien ini memiliki authority (host).
   * @details Authority dapat berpindah ke guest jika host asli keluar.
   * Host memiliki kontrol untuk memulai game, kick pemain, dll.
   */
  Q_PROPERTY(bool isAuthority READ isAuthority NOTIFY authorityChanged)
  
  /**
   * @property isRoomCreator
   * @brief Menandakan apakah klien ini yang membuat room.
   * @details Berbeda dengan isAuthority, ini tidak berubah meskipun host berganti.
   */
  Q_PROPERTY(bool isRoomCreator READ isRoomCreator NOTIFY authorityChanged)
  
  /**
   * @property isConnected
   * @brief Status koneksi aktif ke jaringan multiplayer.
   */
  Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
  
  /**
   * @property isScanning
   * @brief Menandakan apakah sedang melakukan scanning room.
   * @details Scanning otomatis berhenti setelah 30 detik.
   */
  Q_PROPERTY(bool isScanning READ isScanning NOTIFY scanningChanged)
  
  /**
   * @property isInGame
   * @brief Status apakah sedang dalam sesi permainan aktif.
   */
  Q_PROPERTY(bool isInGame READ isInGame NOTIFY gameStateChanged)
  
  /**
   * @property isInLobby
   * @brief Status apakah berada di lobby (menunggu game dimulai).
   */
  Q_PROPERTY(bool isInLobby READ isInLobby NOTIFY lobbyStateChanged)
  
  /**
   * @property localIpAddress
   * @brief Alamat IP lokal yang digunakan untuk koneksi.
   * @details Dipilih otomatis berdasarkan prioritas (Ethernet > WiFi).
   */
  Q_PROPERTY(QString localIpAddress READ localIpAddress CONSTANT)
  
  /**
   * @property playerId
   * @brief UUID unik untuk pemain ini (dibuat saat inisialisasi).
   */
  Q_PROPERTY(QString playerId READ playerId CONSTANT)
  
  /**
   * @property playerName
   * @brief Nama tampilan pemain yang terlihat oleh pemain lain.
   */
  Q_PROPERTY(QString playerName READ playerName WRITE setPlayerName NOTIFY
                 playerNameChanged)
  
  /**
   * @property players
   * @brief Daftar semua pemain di room saat ini.
   * @details Berisi QVariantMap dengan id, name, isHost, isLocal, progress, wpm, dll.
   */
  Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)
  
  /**
   * @property discoveredRooms
   * @brief Daftar room yang ditemukan dari UDP broadcast.
   * @details Berisi QVariantMap dengan hostName, hostIp, port, playerCount, status.
   */
  Q_PROPERTY(QVariantList discoveredRooms READ discoveredRooms NOTIFY
                 discoveredRoomsChanged)
  
  /**
   * @property gameText
   * @brief Teks yang harus diketik dalam game.
   * @details Di-set oleh host dan disinkronkan ke semua pemain.
   */
  Q_PROPERTY(QString gameText READ gameText NOTIFY gameTextChanged)
  
  /**
   * @property gameLanguage
   * @brief Bahasa teks game ("id", "en", "prog").
   */
  Q_PROPERTY(QString gameLanguage READ gameLanguage NOTIFY gameLanguageChanged)
  
  /**
   * @property connectionError
   * @brief Pesan error koneksi terakhir.
   */
  Q_PROPERTY(QString connectionError READ connectionError NOTIFY
                 connectionErrorChanged)
  
  /**
   * @property peerCount
   * @brief Jumlah peer yang terhubung (tidak termasuk diri sendiri).
   */
  Q_PROPERTY(int peerCount READ peerCount NOTIFY peersChanged)
  
  /**
   * @property availableInterfaces
   * @brief Daftar network interface yang tersedia.
   * @details Digunakan untuk memilih interface broadcast.
   */
  Q_PROPERTY(QVariantList availableInterfaces READ availableInterfaces CONSTANT)
  
  /**
   * @property isConnecting
   * @brief Status apakah sedang dalam proses koneksi.
   */
  Q_PROPERTY(bool isConnecting READ isConnecting NOTIFY connectingChanged)
  
  /**
   * @property selectedInterface
   * @brief Network interface yang dipilih untuk broadcasting.
   */
  Q_PROPERTY(QString selectedInterface READ selectedInterface WRITE
                 setSelectedInterface NOTIFY selectedInterfaceChanged)
  
  /**
   * @property isWaitingForReady
   * @brief Status apakah host sedang menunggu semua pemain ready.
   */
  Q_PROPERTY(bool isWaitingForReady READ isWaitingForReady NOTIFY
                 waitingForReadyChanged)
  
  /**
   * @property rankings
   * @brief Hasil ranking setelah race selesai.
   * @details Berisi QVariantMap dengan id, name, wpm, accuracy, errors, position.
   */
  Q_PROPERTY(QVariantList rankings READ rankings NOTIFY rankingsChanged)

public:
  /**
   * @brief Mendapatkan singleton instance dari NetworkManager.
   * @return Pointer ke instance NetworkManager.
   */
  static NetworkManager *instance();
  
  /**
   * @brief Factory method untuk QML singleton registration.
   * @param engine Pointer ke QQmlEngine.
   * @param scriptEngine Pointer ke QJSEngine.
   * @return Pointer ke instance NetworkManager.
   */
  static NetworkManager *create(QQmlEngine *engine, QJSEngine *scriptEngine);

  // === PACKET TYPES ===
  /**
   * @enum PacketType
   * @brief Jenis paket yang digunakan dalam komunikasi jaringan.
   */
  enum class PacketType : quint8 {
    HELLO = 0,           ///< Handshake awal dengan informasi pemain
    PEER_LIST,           ///< Daftar peer untuk pembentukan mesh
    GAME_START,          ///< Sinyal mulai permainan
    PROGRESS_UPDATE,     ///< Update progres mengetik real-time
    FINISH,              ///< Notifikasi pemain selesai mengetik
    GAME_TEXT,           ///< Distribusi teks game dari host
    COUNTDOWN,           ///< Countdown sinkron sebelum race
    PLAYER_LEFT,         ///< Notifikasi pemain keluar dari room
    RACE_RESULTS,        ///< Hasil akhir race dengan ranking lengkap
    READY_CHECK,         ///< Host meminta konfirmasi ready dari semua pemain
    READY_RESPONSE,      ///< Respons pemain terhadap ready check
    PLAY_AGAIN_INVITE,   ///< Host mengundang guest untuk bermain lagi
    PLAY_AGAIN_RESPONSE, ///< Guest menerima/menolak undangan
    KICK                 ///< Host mengeluarkan pemain dari room
  };
  Q_ENUM(PacketType)

  // === PACKET STRUCTURE ===
  /**
   * @struct Packet
   * @brief Struktur data paket untuk komunikasi jaringan.
   *
   * @details Setiap paket memiliki header yang berisi tipe, pengirim, dan timestamp,
   * diikuti dengan payload JSON yang berisi data spesifik tipe paket.
   */
  struct Packet {
    PacketType type;      ///< Tipe paket
    QString senderUuid;   ///< UUID pengirim
    qint64 timestamp;     ///< Timestamp pengiriman (ms since epoch)
    QJsonObject payload;  ///< Data payload dalam format JSON

    /**
     * @brief Serialisasi paket menjadi QByteArray untuk pengiriman.
     * @return QByteArray berisi paket yang sudah di-serialize dengan length prefix.
     */
    QByteArray serialize() const;
    
    /**
     * @brief Deserialisasi QByteArray menjadi Packet.
     * @param data Data mentah dari socket.
     * @return Packet hasil deserialisasi.
     */
    static Packet deserialize(const QByteArray &data);
  };

  // === ROOM FUNCTIONS ===
  
  /**
   * @brief Membuat room baru sebagai host.
   * @return true jika berhasil membuat room, false jika gagal.
   * @details Memulai TCP server dan UDP broadcasting.
   * Klien ini menjadi authority (host) dengan kontrol penuh.
   */
  Q_INVOKABLE bool createRoom();
  
  /**
   * @brief Menutup room dan memutuskan semua koneksi.
   * @details Menghentikan broadcasting, memutuskan semua peer,
   * dan mereset state ke kondisi awal.
   */
  Q_INVOKABLE void closeRoom();

  // === DISCOVERY FUNCTIONS ===
  
  /**
   * @brief Memulai scanning untuk menemukan room di jaringan lokal.
   * @details Mendengarkan UDP broadcast dari host lain.
   * Scanning otomatis berhenti setelah 30 detik.
   */
  Q_INVOKABLE void startScanning();
  
  /**
   * @brief Menghentikan scanning room.
   */
  Q_INVOKABLE void stopScanning();
  
  /**
   * @brief Membersihkan daftar room dan memulai scanning ulang.
   */
  Q_INVOKABLE void refreshRooms();

  // === CONNECTION FUNCTIONS ===
  
  /**
   * @brief Bergabung ke room yang ada.
   * @param hostIp Alamat IP host.
   * @param port Port TCP host.
   * @return true jika koneksi dimulai, false jika gagal.
   * @details Koneksi async dengan timeout 5 detik.
   * Signal joinSucceeded() atau joinFailed() akan di-emit.
   */
  Q_INVOKABLE bool joinRoom(const QString &hostIp, int port);
  
  /**
   * @brief Keluar dari room saat ini.
   * @details Alias untuk closeRoom(), membersihkan semua koneksi.
   */
  Q_INVOKABLE void leaveRoom();
  
  /**
   * @brief Terhubung ke peer spesifik (internal mesh building).
   * @param ip Alamat IP peer.
   * @param port Port TCP peer.
   * @param uuid UUID peer (opsional, untuk identifikasi).
   * @return true jika koneksi dimulai.
   */
  Q_INVOKABLE bool connectToPeer(const QString &ip, int port,
                                 const QString &uuid = QString());

  // === GAME CONTROL (Authority only) ===
  
  /**
   * @brief Mengatur teks game yang akan diketik.
   * @param text Teks untuk race.
   * @note Hanya host yang dapat memanggil fungsi ini.
   */
  Q_INVOKABLE void setGameText(const QString &text);
  
  /**
   * @brief Mengatur bahasa teks game.
   * @param language Kode bahasa ("id", "en", "prog").
   * @note Hanya host yang dapat memanggil fungsi ini.
   * Teks akan di-refresh otomatis saat bahasa berubah.
   */
  Q_INVOKABLE void setGameLanguage(const QString &language);
  
  /**
   * @brief Generate teks game baru berdasarkan bahasa yang dipilih.
   * @note Hanya authority (host) yang dapat memanggil fungsi ini.
   */
  Q_INVOKABLE void refreshGameText();
  
  /**
   * @brief Memulai countdown dan kemudian race.
   * @details Mengirim READY_CHECK ke semua peer, menunggu respons,
   * lalu memulai countdown 3 detik diikuti GAME_START.
   * @note Hanya authority (host) yang dapat memanggil fungsi ini.
   */
  Q_INVOKABLE void startCountdown();
  
  /**
   * @brief Mengeluarkan pemain dari room.
   * @param uuid UUID pemain yang akan di-kick.
   * @note Hanya host yang dapat melakukan kick.
   */
  Q_INVOKABLE void kickPlayer(const QString &uuid);

  // === PLAYER ACTIONS ===
  
  /**
   * @brief Update progres mengetik lokal.
   * @param position Posisi karakter saat ini.
   * @param totalChars Total karakter dalam teks.
   * @param wpm Words per minute saat ini.
   * @param accuracy Akurasi mengetik (0-100).
   * @param errors Jumlah error.
   * @details Dipanggil setiap kali ada perubahan input.
   * Data akan di-broadcast ke semua peer setiap 50ms.
   */
  Q_INVOKABLE void updateProgress(int position, int totalChars, int wpm,
                                  double accuracy, int errors);
  
  /**
   * @brief Menandai bahwa pemain lokal telah menyelesaikan race.
   * @param wpm Words per minute final.
   * @param accuracy Akurasi final (0-100).
   * @param errors Total error.
   * @param duration Durasi race dalam detik.
   */
  Q_INVOKABLE void finishRace(int wpm, double accuracy, int errors,
                              int duration);

  // === PLAY AGAIN FUNCTIONS ===
  
  /**
   * @brief Host mengirim undangan bermain lagi ke semua guest.
   * @note Hanya authority (host) yang dapat memanggil fungsi ini.
   */
  Q_INVOKABLE void sendPlayAgainInvite();
  
  /**
   * @brief Guest menerima undangan bermain lagi.
   * @details Akan kembali ke lobby dan mengirim PLAY_AGAIN_RESPONSE.
   */
  Q_INVOKABLE void acceptPlayAgain();
  
  /**
   * @brief Guest menolak undangan dan keluar dari room.
   */
  Q_INVOKABLE void declinePlayAgain();
  
  /**
   * @brief Kembali ke lobby dengan mempertahankan koneksi.
   * @details Reset state game tanpa memutuskan koneksi.
   */
  Q_INVOKABLE void returnToLobby();

  // === GETTERS ===
  
  /**
   * @brief Cek apakah klien ini memiliki authority.
   * @return true jika klien ini adalah host atau telah menerima authority.
   */
  bool isAuthority() const {
    return m_isAuthority;
  }
  
  /**
   * @brief Cek apakah klien ini yang membuat room.
   * @return true jika klien ini adalah pembuat room asli.
   */
  bool isRoomCreator() const { return m_isRoomCreator; }
  
  /**
   * @brief Cek status koneksi.
   * @return true jika terhubung ke room.
   */
  bool isConnected() const { return m_isConnected; }
  
  /**
   * @brief Cek status scanning.
   * @return true jika sedang scanning room.
   */
  bool isScanning() const { return m_isScanning; }
  
  /**
   * @brief Cek apakah sedang dalam game.
   * @return true jika race sedang berlangsung.
   */
  bool isInGame() const { return m_isInGame; }
  
  /**
   * @brief Cek apakah berada di lobby.
   * @return true jika di lobby.
   */
  bool isInLobby() const { return m_isInLobby; }
  
  /**
   * @brief Cek apakah menunggu ready dari pemain.
   * @return true jika host sedang menunggu ready response.
   */
  bool isWaitingForReady() const { return m_isWaitingForReady; }
  
  /**
   * @brief Mendapatkan alamat IP lokal.
   * @return QString berisi alamat IP yang dipilih.
   */
  QString localIpAddress() const;
  
  /**
   * @brief Mendapatkan player ID (UUID).
   * @return QString berisi UUID pemain.
   */
  QString playerId() const { return m_playerId; }
  
  /**
   * @brief Mendapatkan nama pemain.
   * @return QString berisi nama yang ditampilkan.
   */
  QString playerName() const { return m_playerName; }
  
  /**
   * @brief Mendapatkan daftar pemain sebagai QVariantList untuk QML.
   * @return QVariantList berisi QVariantMap untuk setiap pemain.
   */
  QVariantList players() const;
  
  /**
   * @brief Mendapatkan daftar room yang ditemukan.
   * @return QVariantList berisi QVariantMap untuk setiap room.
   */
  QVariantList discoveredRooms() const;
  
  /**
   * @brief Mendapatkan teks game.
   * @return QString berisi teks yang harus diketik.
   */
  QString gameText() const { return m_gameText; }
  
  /**
   * @brief Mendapatkan bahasa game.
   * @return QString berisi kode bahasa.
   */
  QString gameLanguage() const { return m_gameLanguage; }
  
  /**
   * @brief Mendapatkan pesan error koneksi.
   * @return QString berisi pesan error terakhir.
   */
  QString connectionError() const { return m_connectionError; }
  
  /**
   * @brief Mendapatkan jumlah peer terhubung.
   * @return int jumlah peer (tidak termasuk diri sendiri).
   */
  int peerCount() const { return m_peers.size(); }
  
  /**
   * @brief Mendapatkan daftar network interface.
   * @return QVariantList berisi informasi interface.
   */
  QVariantList availableInterfaces() const;
  
  /**
   * @brief Mendapatkan hasil ranking.
   * @return QVariantList berisi ranking pemain.
   */
  QVariantList rankings() const { return m_rankings; }
  
  /**
   * @brief Cek status connecting.
   * @return true jika sedang dalam proses koneksi.
   */
  bool isConnecting() const { return m_isConnecting; }
  
  /**
   * @brief Mendapatkan interface yang dipilih.
   * @return QString berisi IP interface yang dipilih.
   */
  QString selectedInterface() const { return m_selectedInterface; }

  /**
   * @brief Mengatur nama pemain.
   * @param name Nama baru untuk ditampilkan.
   */
  void setPlayerName(const QString &name);
  
  /**
   * @brief Mengatur network interface untuk broadcasting.
   * @param ip Alamat IP interface yang dipilih.
   */
  Q_INVOKABLE void setSelectedInterface(const QString &ip);

signals:
  // Property change signals
  
  /** @brief Dipancarkan saat status authority berubah. */
  void authorityChanged();
  
  /** @brief Dipancarkan saat status koneksi berubah. */
  void connectionChanged();
  
  /** @brief Dipancarkan saat status scanning berubah. */
  void scanningChanged();
  
  /** @brief Dipancarkan saat status game berubah (in/out of game). */
  void gameStateChanged();
  
  /** @brief Dipancarkan saat status lobby berubah. */
  void lobbyStateChanged();
  
  /** @brief Dipancarkan saat nama pemain berubah. */
  void playerNameChanged();
  
  /** @brief Dipancarkan saat daftar pemain berubah. */
  void playersChanged();
  
  /** @brief Dipancarkan saat daftar room ditemukan berubah. */
  void discoveredRoomsChanged();
  
  /** @brief Dipancarkan saat teks game berubah. */
  void gameTextChanged();
  
  /** @brief Dipancarkan saat bahasa game berubah. */
  void gameLanguageChanged();
  
  /** @brief Dipancarkan saat ada error koneksi. */
  void connectionErrorChanged();
  
  /** @brief Dipancarkan saat jumlah peer berubah. */
  void peersChanged();
  
  /** @brief Dipancarkan saat status waiting for ready berubah. */
  void waitingForReadyChanged();
  
  /** @brief Dipancarkan saat semua pemain sudah ready. */
  void allPlayersReady();
  
  /** @brief Dipancarkan saat ranking tersedia. */
  void rankingsChanged();

  // Game flow signals
  
  /**
   * @brief Dipancarkan saat pemain baru bergabung.
   * @param name Nama pemain yang bergabung.
   */
  void playerJoined(const QString &name);
  
  /**
   * @brief Dipancarkan saat pemain keluar dari room.
   * @param name Nama pemain yang keluar.
   */
  void playerLeft(const QString &name);
  
  /**
   * @brief Dipancarkan saat countdown dimulai.
   * @param seconds Jumlah detik countdown.
   */
  void countdownStarted(int seconds);
  
  /** @brief Dipancarkan saat game/race dimulai. */
  void gameStarted();
  
  /**
   * @brief Dipancarkan saat ada update progres dari pemain.
   * @param id UUID pemain.
   * @param name Nama pemain.
   * @param progress Progres (0.0 - 1.0).
   * @param wpm Words per minute saat ini.
   * @param finished Apakah sudah selesai.
   * @param position Posisi finish (jika sudah selesai).
   */
  void playerProgressUpdated(const QString &id, const QString &name,
                             double progress, int wpm, bool finished,
                             int position);
  
  /**
   * @brief Dipancarkan saat race selesai dengan ranking.
   * @param rankings Daftar ranking pemain.
   */
  void raceFinished(const QVariantList &rankings);

  // Discovery signals
  
  /**
   * @brief Dipancarkan saat room baru ditemukan.
   * @param ip Alamat IP host.
   * @param port Port TCP host.
   * @param hostName Nama host.
   */
  void roomFound(const QString &ip, int port, const QString &hostName);

  // Connection result signals
  
  /** @brief Dipancarkan saat berhasil bergabung ke room. */
  void joinSucceeded();
  
  /**
   * @brief Dipancarkan saat gagal bergabung ke room.
   * @param reason Alasan kegagalan.
   */
  void joinFailed(const QString &reason);
  
  /** @brief Dipancarkan saat status connecting berubah. */
  void connectingChanged();
  
  /** @brief Dipancarkan saat interface yang dipilih berubah. */
  void selectedInterfaceChanged();
  
  /** @brief Dipancarkan saat pemain ini di-kick oleh host. */
  void kicked();

  // Play again signals
  
  /** @brief Dipancarkan saat guest menerima undangan bermain lagi. */
  void playAgainInviteReceived();
  
  /**
   * @brief Dipancarkan saat pemain menerima undangan (untuk host).
   * @param name Nama pemain yang menerima.
   */
  void playAgainAccepted(const QString &name);
  
  /**
   * @brief Dipancarkan saat pemain menolak undangan (untuk host).
   * @param name Nama pemain yang menolak.
   */
  void playAgainDeclined(const QString &name);
  
  /** @brief Dipancarkan saat berhasil kembali ke lobby. */
  void returnedToLobby();
  
  /** @brief Dipancarkan jika guest mencoba accept tapi game sudah dimulai. */
  void gameInProgress();

private:
  /**
   * @brief Constructor privat untuk singleton pattern.
   * @param parent Parent QObject.
   */
  explicit NetworkManager(QObject *parent = nullptr);
  
  /** @brief Destructor. */
  ~NetworkManager();

  static NetworkManager *s_instance;  ///< Singleton instance

  // === CONSTANTS ===
  static constexpr int DISCOVERY_PORT = 52766;     ///< Port UDP untuk discovery
  static constexpr int TCP_PORT = 52765;           ///< Port TCP untuk koneksi mesh
  static constexpr int ANNOUNCE_INTERVAL_MS = 1000; ///< Interval broadcast (1 detik)
  static constexpr int ROOM_TIMEOUT_MS = 5000;     ///< Timeout room stale (5 detik)
  static constexpr int SCAN_TIMEOUT_MS = 30000;    ///< Timeout scanning (30 detik)
  static constexpr int PROGRESS_UPDATE_MS = 50;    ///< Interval progress update (50ms)
  static constexpr int MAX_PLAYERS = 8;            ///< Maksimum pemain per room
  inline static const char *APP_IDENTIFIER = "RapidTexterP2P"; ///< Identifier aplikasi

  // === STATE ===
  bool m_isAuthority = false;    ///< Apakah memiliki authority (host)
  bool m_isRoomCreator = false;  ///< Apakah pembuat room asli
  bool m_isConnected = false;    ///< Status koneksi
  bool m_isScanning = false;     ///< Status scanning
  bool m_isInGame = false;       ///< Status dalam game
  bool m_isInLobby = false;      ///< Status di lobby
  QString m_playerId;            ///< UUID pemain lokal
  QString m_playerName;          ///< Nama pemain lokal
  QString m_gameText;            ///< Teks game saat ini
  QString m_gameLanguage = "en"; ///< Bahasa game default
  QString m_connectionError;     ///< Pesan error terakhir
  bool m_isConnecting = false;   ///< Status connecting
  QString m_pendingJoinIp;       ///< IP target join
  int m_pendingJoinPort = 0;     ///< Port target join
  QString m_selectedInterface;   ///< Interface yang dipilih
  QString m_hostUuid;            ///< UUID host room

  // Ready check state
  bool m_isWaitingForReady = false;        ///< Status menunggu ready
  QMap<QString, bool> m_playersReady;      ///< Map pemain dan status ready
  QTimer *m_readyCheckTimer = nullptr;     ///< Timer timeout ready check

  // Play again state
  bool m_isPendingInvite = false;  ///< Ada undangan pending
  bool m_hostHasStarted = false;   ///< Host sudah mulai tanpa kita

  // Race timing
  qint64 m_raceStartTime = 0;  ///< Waktu mulai race (untuk sinkronisasi durasi)

  // === TCP (Mesh) ===
  QTcpServer *m_tcpServer = nullptr;  ///< TCP server untuk menerima koneksi

  // === PEER CONNECTION ===
  /**
   * @struct PeerConnection
   * @brief Menyimpan informasi koneksi ke peer.
   */
  struct PeerConnection {
    QTcpSocket *socket = nullptr;  ///< Socket TCP ke peer
    QString uuid;                  ///< UUID peer
    QString name;                  ///< Nama peer
    QString ip;                    ///< Alamat IP peer
    int port = 0;                  ///< Port TCP peer
    bool handshakeComplete = false; ///< Status handshake selesai
    QByteArray readBuffer;         ///< Buffer untuk membaca data
  };
  QMap<QString, PeerConnection *> m_peers;  ///< Map UUID -> PeerConnection
  QSet<QString> m_pendingConnections;       ///< Koneksi yang sedang dalam proses

  // === UDP DISCOVERY ===
  QUdpSocket *m_discoverySocket = nullptr;     ///< Socket UDP untuk discovery
  QTimer *m_announceTimer = nullptr;           ///< Timer untuk broadcast
  QTimer *m_cleanupTimer = nullptr;            ///< Timer untuk cleanup room stale
  QTimer *m_connectionTimeoutTimer = nullptr;  ///< Timer timeout koneksi
  QTimer *m_scanTimeoutTimer = nullptr;        ///< Timer timeout scanning

  // === DATA ===
  /**
   * @struct PlayerInfo
   * @brief Menyimpan informasi pemain dalam game.
   */
  struct PlayerInfo {
    QString uuid;            ///< UUID pemain
    QString name;            ///< Nama pemain
    int position = 0;        ///< Posisi karakter saat ini
    int totalChars = 0;      ///< Total karakter dalam teks
    int wpm = 0;             ///< Words per minute
    double accuracy = 100.0; ///< Akurasi mengetik
    int errors = 0;          ///< Jumlah error
    bool finished = false;   ///< Sudah selesai mengetik
    int racePosition = 0;    ///< Posisi finish (1st, 2nd, dll)
    qint64 finishTime = 0;   ///< Waktu finish (timestamp)
    int duration = 0;        ///< Durasi race dalam detik
    bool hasLeft = false;    ///< Pemain sudah disconnect
  };
  QMap<QString, PlayerInfo> m_players;  ///< Map UUID -> PlayerInfo

  /**
   * @struct RoomInfo
   * @brief Menyimpan informasi room yang ditemukan.
   */
  struct RoomInfo {
    QString hostName;        ///< Nama host
    QString hostIp;          ///< IP host
    QString hostUuid;        ///< UUID host
    int port = 0;            ///< Port TCP
    int playerCount = 0;     ///< Jumlah pemain
    QString status;          ///< Status room ("waiting", "countdown", "racing")
    qint64 lastSeen = 0;     ///< Timestamp terakhir dilihat
  };
  QMap<QString, RoomInfo> m_discoveredRooms;  ///< Map UUID -> RoomInfo

  // Local player state
  int m_currentPosition = 0;       ///< Posisi karakter lokal
  int m_currentTotal = 0;          ///< Total karakter lokal
  int m_currentWpm = 0;            ///< WPM lokal
  double m_currentAccuracy = 100.0; ///< Akurasi lokal
  int m_currentErrors = 0;         ///< Error lokal
  bool m_localFinished = false;    ///< Status finish lokal
  int m_finishedCount = 0;         ///< Jumlah pemain yang sudah finish
  QVariantList m_rankings;         ///< Hasil ranking

  // Progress timer
  QTimer *m_progressTimer = nullptr;  ///< Timer untuk broadcast progress

  // === PRIVATE METHODS ===

  // Discovery
  /** @brief Setup socket UDP untuk discovery. */
  void setupDiscoverySocket();
  /** @brief Mulai broadcasting room. */
  void startAnnouncing();
  /** @brief Berhenti broadcasting room. */
  void stopAnnouncing();
  /** @brief Kirim satu paket broadcast. */
  void sendAnnounce();
  /** @brief Proses datagram yang diterima. */
  void processDiscoveryDatagram();
  /** @brief Hapus room yang sudah timeout. */
  void cleanupStaleRooms();

  // TCP Mesh
  /** @brief Mulai TCP server. */
  void startTcpServer();
  /** @brief Berhenti TCP server. */
  void stopTcpServer();
  /** @brief Handler koneksi TCP baru. */
  void onNewTcpConnection();
  /** @brief Handler peer connected. */
  void onPeerConnected();
  /** @brief Handler peer disconnected. */
  void onPeerDisconnected();
  /** @brief Handler data ready untuk dibaca. */
  void onPeerReadyRead();
  /** @brief Handler error socket. */
  void onPeerError(QAbstractSocket::SocketError error);

  // Handshake & Mesh
  /** @brief Kirim HELLO ke peer. */
  void sendHello(PeerConnection *peer);
  /** @brief Handle HELLO dari peer. */
  void handleHello(PeerConnection *peer, const Packet &packet);
  /** @brief Kirim daftar peer ke peer baru. */
  void sendPeerList(PeerConnection *peer);
  /** @brief Handle daftar peer yang diterima. */
  void handlePeerList(const Packet &packet);
  /** @brief Koneksi ke peer yang belum terhubung. */
  void connectToMissingPeers(const QJsonArray &peerList);

  // Packet Handling
  /** @brief Proses paket yang diterima. */
  void processPacket(PeerConnection *peer, const Packet &packet);
  /** @brief Broadcast paket ke semua peer. */
  void broadcastToAllPeers(const Packet &packet);
  /** @brief Kirim paket ke peer spesifik. */
  void sendToPeer(PeerConnection *peer, const Packet &packet);
  /** @brief Buat paket baru dengan header terisi. */
  Packet createPacket(PacketType type, const QJsonObject &payload = {});

  // Authority (room creator based)
  /** @brief Update status authority. */
  void updateAuthority();

  // Game Logic
  /** @brief Handle GAME_START. */
  void handleGameStart(const Packet &packet);
  /** @brief Handle PROGRESS_UPDATE. */
  void handleProgressUpdate(PeerConnection *peer, const Packet &packet);
  /** @brief Handle FINISH. */
  void handleFinish(PeerConnection *peer, const Packet &packet);
  /** @brief Handle GAME_TEXT. */
  void handleGameText(const Packet &packet);
  /** @brief Handle COUNTDOWN. */
  void handleCountdown(const Packet &packet);
  /** @brief Handle PLAYER_LEFT. */
  void handlePlayerLeft(const Packet &packet);
  /** @brief Handle RACE_RESULTS. */
  void handleRaceResults(const Packet &packet);
  /** @brief Handle READY_CHECK. */
  void handleReadyCheck(const Packet &packet);
  /** @brief Handle READY_RESPONSE. */
  void handleReadyResponse(const Packet &packet);
  /** @brief Kirim progress update ke semua peer. */
  void sendProgressUpdate();
  /** @brief Cek apakah race sudah selesai. */
  void checkRaceCompletion();
  /** @brief Mulai countdown setelah ready check. */
  void beginCountdown();
  /** @brief Handler timeout ready check. */
  void onReadyCheckTimeout();

  // Play Again handlers
  /** @brief Handle PLAY_AGAIN_INVITE. */
  void handlePlayAgainInvite(const Packet &packet);
  /** @brief Handle PLAY_AGAIN_RESPONSE. */
  void handlePlayAgainResponse(PeerConnection *peer, const Packet &packet);
  /** @brief Handle KICK. */
  void handleKick(const Packet &packet);

  // Utilities
  /** @brief Set pesan error koneksi. */
  void setConnectionError(const QString &error);
  /** @brief Reset semua state ke kondisi awal. */
  void resetState();
  /** @brief Generate key untuk peer dari IP:port. */
  QString getPeerKey(const QString &ip, int port) const;
  /** @brief Hapus peer dari daftar. */
  void removePeer(const QString &uuid);
};

#endif // NETWORKMANAGER_H
