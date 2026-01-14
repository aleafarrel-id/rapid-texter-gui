/**
 * @file MultiplayerHistoryManager.h
 * @brief Manager untuk menyimpan dan mengambil riwayat permainan multiplayer.
 * @author Alea Farrel & Team
 * @date 2025-2026
 *
 * @details MultiplayerHistoryManager bertanggung jawab untuk:
 * - Menyimpan hasil race multiplayer ke file JSON
 * - Memuat riwayat dari file JSON saat aplikasi dimulai
 * - Menyediakan data riwayat ke QML untuk ditampilkan
 * - Sorting berdasarkan tanggal, WPM, atau rank
 *
 * File riwayat disimpan di: %APPDATA%/RapidTexter/multiplayer_history.json
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
 * @struct MultiplayerPlayerResult
 * @brief Menyimpan hasil satu pemain dalam pertandingan multiplayer.
 *
 * @details Struktur ini merepresentasikan performa individu pemain
 * dalam satu sesi race multiplayer.
 */
struct MultiplayerPlayerResult {
    QString name;      ///< Nama pemain
    QString uuid;      ///< UUID unik pemain
    int wpm;           ///< Words per minute yang dicapai
    double accuracy;   ///< Akurasi mengetik (0-100)
    int errors;        ///< Jumlah kesalahan ketik
    double duration;   ///< Durasi menyelesaikan race (detik)
    int position;      ///< Peringkat finish (1st, 2nd, 3rd, ...)
    bool isLocal;      ///< true jika ini adalah pemain lokal
    bool hasLeft;      ///< true jika pemain disconnect sebelum selesai

    /**
     * @brief Constructor default dengan nilai awal.
     */
    MultiplayerPlayerResult() : wpm(0), accuracy(0), errors(0), duration(0), position(0), isLocal(false), hasLeft(false) {}
};

/**
 * @struct MultiplayerHistoryEntry
 * @brief Menyimpan record lengkap satu pertandingan multiplayer.
 *
 * @details Berisi timestamp pertandingan, informasi host, dan
 * daftar semua pemain beserta hasil mereka.
 */
struct MultiplayerHistoryEntry {
    QString timestamp;   ///< Waktu pertandingan (format: dd/MM/yyyy HH:mm:ss)
    QString hostName;    ///< Nama pembuat room (host)
    std::vector<MultiplayerPlayerResult> players;  ///< Daftar hasil semua pemain
    
    // Derived local stats untuk quick display
    int localWpm;   ///< WPM pemain lokal untuk tampilan cepat
    int localRank;  ///< Rank pemain lokal untuk tampilan cepat
    
    /**
     * @brief Constructor default dengan nilai awal.
     */
    MultiplayerHistoryEntry() : localWpm(0), localRank(0) {}
};

/**
 * @class MultiplayerHistoryManager
 * @brief Singleton manager untuk penyimpanan riwayat multiplayer (format JSON).
 *
 * @details Kelas ini menangani persistensi data riwayat multiplayer ke disk
 * dan menyediakan interface untuk QML melalui QML_SINGLETON.
 *
 * @par Format Penyimpanan:
 * Data disimpan dalam format JSON dengan struktur:
 * @code{.json}
 * {
 *   "entries": [
 *     {
 *       "timestamp": "01/01/2026 12:00:00",
 *       "hostName": "Player1",
 *       "players": [...]
 *     }
 *   ]
 * }
 * @endcode
 */
class MultiplayerHistoryManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    
    /**
     * @property historyData
     * @brief Data riwayat dalam format QVariantList untuk QML.
     */
    Q_PROPERTY(QVariantList historyData READ getHistoryData NOTIFY historyChanged)
    
    /**
     * @property totalEntries
     * @brief Total jumlah entry riwayat.
     */
    Q_PROPERTY(int totalEntries READ getTotalEntries NOTIFY historyChanged)
    
    /**
     * @property sortBy
     * @brief Field yang digunakan untuk sorting ("date", "wpm", "rank").
     */
    Q_PROPERTY(QString sortBy READ sortBy WRITE setSortBy NOTIFY sortByChanged)
    
    /**
     * @property sortAscending
     * @brief Arah sorting (true = ascending, false = descending).
     */
    Q_PROPERTY(bool sortAscending READ sortAscending WRITE setSortAscending NOTIFY sortAscendingChanged)

public:
    /**
     * @brief Constructor.
     * @param parent Parent QObject.
     */
    explicit MultiplayerHistoryManager(QObject *parent = nullptr);
    
    /**
     * @brief Mendapatkan singleton instance.
     * @return Pointer ke instance MultiplayerHistoryManager.
     */
    static MultiplayerHistoryManager *instance();
    
    /**
     * @brief Memuat riwayat dari file JSON.
     * @return true jika berhasil memuat, false jika gagal.
     */
    bool loadHistory();
    
    /**
     * @brief Menyimpan riwayat ke file JSON.
     * @return true jika berhasil menyimpan, false jika gagal.
     */
    bool saveHistory();
    
    /**
     * @brief Menambahkan entry baru dari hasil race.
     * @param rankings Daftar pemain dan statistik dari NetworkManager.
     * @param hostName Nama pembuat room.
     */
    void addEntry(const QVariantList& rankings, const QString& hostName);
    
    /**
     * @brief Menghapus semua riwayat.
     * @note Dapat dipanggil dari QML.
     */
    Q_INVOKABLE void clearHistory();
    
    /**
     * @brief Mendapatkan data riwayat dalam format QVariantList untuk QML.
     * @return QVariantList berisi semua entry riwayat.
     */
    QVariantList getHistoryData() const;
    
    /**
     * @brief Mendapatkan total jumlah entry.
     * @return Jumlah entry riwayat.
     */
    int getTotalEntries() const;

    /**
     * @brief Mendapatkan field sorting saat ini.
     * @return QString field sorting ("date", "wpm", "rank").
     */
    QString sortBy() const;
    
    /**
     * @brief Mengatur field sorting.
     * @param sortBy Field untuk sorting.
     */
    void setSortBy(const QString &sortBy);

    /**
     * @brief Mendapatkan arah sorting.
     * @return true jika ascending, false jika descending.
     */
    bool sortAscending() const;
    
    /**
     * @brief Mengatur arah sorting.
     * @param ascending true untuk ascending, false untuk descending.
     */
    void setSortAscending(bool ascending);

public slots:
    /**
     * @brief Slot untuk menerima hasil race dari NetworkManager.
     * @param rankings Daftar ranking pemain.
     */
    void onRaceFinished(const QVariantList& rankings);

signals:
    /** @brief Dipancarkan saat data riwayat berubah. */
    void historyChanged();
    
    /** @brief Dipancarkan saat field sorting berubah. */
    void sortByChanged();
    
    /** @brief Dipancarkan saat arah sorting berubah. */
    void sortAscendingChanged();

private:
    static MultiplayerHistoryManager *s_instance;  ///< Singleton instance
    std::vector<MultiplayerHistoryEntry> m_entries; ///< Daftar entry riwayat
    std::string m_filename;  ///< Path file riwayat
    
    /**
     * @brief Mengambil timestamp saat ini.
     * @return QString timestamp dalam format dd/MM/yyyy HH:mm:ss.
     */
    QString captureTimestamp();
    
    /**
     * @brief Mengurutkan riwayat berdasarkan pengaturan saat ini.
     */
    void sortHistory();
    
    /**
     * @brief Escape karakter khusus dalam string untuk JSON.
     * @param str String input.
     * @return String yang sudah di-escape.
     */
    std::string escapeJsonString(const std::string& str);
};

#endif // MULTIPLAYERHISTORYMANAGER_H
