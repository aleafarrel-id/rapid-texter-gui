# Rapid Texter - Multiplayer Flowchart

Dokumen ini berisi diagram alur (flowchart) yang menjelaskan cara kerja sistem multiplayer pada Rapid Texter. Sistem ini menggunakan arsitektur **Peer-to-Peer (P2P) Full Mesh** di mana setiap klien terhubung langsung ke semua klien lainnya.

> [!NOTE]
> **Komponen Jaringan:**
> - **UDP Discovery**: Port 52766 untuk penemuan room di LAN
> - **TCP Mesh**: Port 52765 untuk koneksi data antar peer
> - **Authority**: Floating Authority dengan aturan UUID terendah

---

## 1. Alur Host Membuat Room (Create Room Flow)

```mermaid
flowchart LR
    subgraph START_END [" "]
        A([Start: User pilih Create Room])
    end
    
    subgraph PROCESS_CREATE [" "]
        B[/Input: Player Name/]
        C[Generate UUID unik untuk pemain]
        D[Inisialisasi TCP Server di port 52765]
        E{TCP Server berhasil dimulai?}
        F[Set status: isRoomCreator = true]
        G[Set status: isAuthority = true]
        H[Set status: isConnected = true]
        I[Set status: isInLobby = true]
        J[Mulai UDP Broadcasting di port 52766]
        K[Broadcast paket announce setiap 1 detik]
    end
    
    subgraph END_CREATE [" "]
        L([End: Room berhasil dibuat, menunggu pemain])
        M[/Output: Error - Server gagal dimulai/]
        N([End: Gagal membuat room])
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E -->|Ya| F
    E -->|Tidak| M
    M --> N
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
```

---

## 2. Alur Guest Bergabung ke Room (Join Room Flow)

```mermaid
flowchart LR
    subgraph START_JOIN [" "]
        A([Start: User pilih Join Room])
    end
    
    subgraph DISCOVERY [" "]
        B[/Input: Player Name/]
        C[Mulai scanning UDP pada port 52766]
        D[Dengarkan broadcast dari host]
        E{Menerima paket announce?}
        F[Parse informasi room: hostName, IP, port, playerCount]
        G[/Output: Tampilkan daftar room/]
        H[/Input: User pilih room/]
    end
    
    subgraph CONNECT [" "]
        I[Koneksi TCP ke host pada port 52765]
        J{Koneksi berhasil dalam 5 detik?}
        K[Set status: isConnecting = false]
        L[Set status: isConnected = true]
        M[Kirim paket HELLO ke host]
        N[Terima paket HELLO dari host]
        O[Terima PEER_LIST dari host]
        P[Koneksi ke peer lain dalam mesh]
    end
    
    subgraph END_JOIN [" "]
        Q([End: Berhasil bergabung ke lobby])
        R[/Output: Error - Koneksi timeout/]
        S([End: Gagal bergabung])
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E -->|Ya| F
    E -->|Timeout 30s| R
    R --> S
    F --> G
    G --> H
    H --> I
    I --> J
    J -->|Ya| K
    J -->|Tidak| R
    K --> L
    L --> M
    M --> N
    N --> O
    O --> P
    P --> Q
```

---

## 3. Alur Pembentukan Mesh Penuh (Full Mesh Building)

```mermaid
flowchart LR
    subgraph START_MESH [" "]
        A([Start: Peer baru terkoneksi])
    end
    
    subgraph HANDSHAKE [" "]
        B[Kirim paket HELLO dengan info: name, port, isRoomCreator, hostUuid]
        C[/Input: Terima HELLO dari peer/]
        D[Validasi UUID pemain]
        E{UUID sudah ada?}
        F[Putuskan koneksi duplikat dengan UUID comparison]
        G[Simpan info peer ke daftar]
        H[Set handshakeComplete = true]
    end
    
    subgraph MESH_BUILD [" "]
        I{Apakah host?}
        J[Kirim PEER_LIST ke peer baru]
        K[/Output: Broadcast playerJoined signal/]
        L[/Input: Terima PEER_LIST/]
        M[Parse daftar peer yang perlu dikoneksi]
        N{Ada peer yang belum terkoneksi?}
        O[Koneksi TCP ke peer tersebut]
        P[Ulangi handshake untuk setiap peer]
    end
    
    subgraph END_MESH [" "]
        Q([End: Full Mesh terbentuk])
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E -->|Ya| F
    F --> Q
    E -->|Tidak| G
    G --> H
    H --> I
    I -->|Ya| J
    J --> K
    K --> Q
    I -->|Tidak| L
    L --> M
    M --> N
    N -->|Ya| O
    O --> P
    P --> N
    N -->|Tidak| Q
```

---

## 4. Alur Memulai Game (Start Game Flow)

```mermaid
flowchart LR
    subgraph START_GAME [" "]
        A([Start: Host klik Start Game])
    end
    
    subgraph VALIDATION [" "]
        B{Apakah authority/host?}
        C{Game text tersedia?}
        D[/Output: Error - tidak punya authority/]
        E[/Output: Error - game text kosong/]
    end
    
    subgraph READY_CHECK [" "]
        F{Ada peer lain?}
        G[Set isWaitingForReady = true]
        H[Broadcast paket READY_CHECK dengan text dan language]
        I[Mulai timer timeout 5 detik]
        J[/Input: Terima READY_RESPONSE dari peer/]
        K[Tandai peer sebagai ready]
        L{Semua peer sudah ready?}
        M{Timeout tercapai?}
    end
    
    subgraph COUNTDOWN [" "]
        N[Set isWaitingForReady = false]
        O[Broadcast paket COUNTDOWN dengan detik: 3]
        P[/Output: countdownStarted signal/]
        Q[Tunggu 3 detik]
        R[Broadcast paket GAME_START]
        S[Set isInGame = true]
        T[Set isInLobby = false]
        U[Mulai timer progress update 50ms]
    end
    
    subgraph END_START [" "]
        V([End: Race dimulai])
        W([End: Abort - validasi gagal])
    end
    
    A --> B
    B -->|Tidak| D
    D --> W
    B -->|Ya| C
    C -->|Tidak| E
    E --> W
    C -->|Ya| F
    F -->|Tidak - Solo Mode| N
    F -->|Ya| G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L -->|Tidak| M
    M -->|Tidak| J
    M -->|Ya| N
    L -->|Ya| N
    N --> O
    O --> P
    P --> Q
    Q --> R
    R --> S
    S --> T
    T --> U
    U --> V
```

---

## 5. Alur Permainan Race (Race Gameplay Flow)

```mermaid
flowchart LR
    subgraph START_RACE [" "]
        A([Start: Game dimulai])
    end
    
    subgraph TYPING [" "]
        B[/Input: User mengetik karakter/]
        C[Hitung position, wpm, accuracy, errors]
        D[Update progress lokal]
        E{Timer 50ms tercapai?}
        F[Broadcast paket PROGRESS_UPDATE ke semua peer]
        G[/Input: Terima PROGRESS_UPDATE dari peer/]
        H[Update progress peer di UI]
    end
    
    subgraph FINISH_CHECK [" "]
        I{Semua karakter diketik?}
        J[Hitung durasi final]
        K[Set progress lokal = 100%]
        L[Broadcast paket FINISH dengan wpm, accuracy, errors, duration]
        M[/Input: Terima FINISH dari peer/]
        N[Tandai peer sebagai finished]
        O{Semua pemain sudah finish?}
    end
    
    subgraph END_RACE [" "]
        P([End: Lanjut ke hasil race])
        Q([End: Menunggu pemain lain])
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E -->|Ya| F
    E -->|Tidak| G
    F --> G
    G --> H
    H --> I
    I -->|Tidak| B
    I -->|Ya| J
    J --> K
    K --> L
    L --> M
    M --> N
    N --> O
    O -->|Ya| P
    O -->|Tidak| Q
    Q --> M
```

---

## 6. Alur Penentuan Hasil Race (Race Results Flow)

```mermaid
flowchart LR
    subgraph START_RESULT [" "]
        A([Start: Semua pemain finished])
    end
    
    subgraph RANKING [" "]
        B{Apakah authority?}
        C[Kumpulkan statistik semua pemain]
        D[Sort berdasarkan: WPM desc, Accuracy desc, Errors asc, Duration asc]
        E[Assign posisi ranking 1st, 2nd, 3rd, dst]
        F[Broadcast paket RACE_RESULTS dengan array ranking]
        G[/Input: Terima RACE_RESULTS dari host/]
        H[Parse dan simpan ranking]
    end
    
    subgraph DISPLAY [" "]
        I[Set isInGame = false]
        J[/Output: raceFinished signal dengan rankings/]
        K[Simpan ke MultiplayerHistoryManager]
        L[Tampilkan halaman RaceResultsPage]
    end
    
    subgraph END_RESULT [" "]
        M([End: Hasil ditampilkan])
    end
    
    A --> B
    B -->|Ya| C
    C --> D
    D --> E
    E --> F
    F --> I
    B -->|Tidak| G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L --> M
```

---

## 7. Alur Play Again (Bermain Lagi)

```mermaid
flowchart LR
    subgraph START_PLAY_AGAIN [" "]
        A([Start: Race selesai, hasil ditampilkan])
    end
    
    subgraph HOST_ACTION [" "]
        B{Apakah host?}
        C[/Input: Host klik Play Again/]
        D[Broadcast paket PLAY_AGAIN_INVITE]
        E[Kembali ke lobby]
        F[Generate teks baru]
        G[Menunggu respons dari guest]
    end
    
    subgraph GUEST_ACTION [" "]
        H[/Input: Terima PLAY_AGAIN_INVITE/]
        I[/Output: Tampilkan dialog invite/]
        J[/Input: User pilih Accept atau Decline/]
        K{Accept?}
        L[Kirim PLAY_AGAIN_RESPONSE accepted: true]
        M[Kembali ke lobby]
        N[Kirim PLAY_AGAIN_RESPONSE accepted: false]
        O[Keluar dari room]
    end
    
    subgraph HOST_RECEIVE [" "]
        P[/Input: Terima PLAY_AGAIN_RESPONSE/]
        Q{Accepted?}
        R[/Output: playAgainAccepted signal/]
        S[/Output: playAgainDeclined signal/]
        T[Hapus peer dari daftar]
    end
    
    subgraph END_PLAY_AGAIN [" "]
        U([End: Kembali ke lobby bersama])
        V([End: Guest keluar dari room])
    end
    
    A --> B
    B -->|Ya| C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> P
    B -->|Tidak| H
    H --> I
    I --> J
    J --> K
    K -->|Ya| L
    L --> M
    M --> U
    K -->|Tidak| N
    N --> O
    O --> V
    P --> Q
    Q -->|Ya| R
    R --> U
    Q -->|Tidak| S
    S --> T
    T --> V
```

---

## 8. Alur Pemain Keluar/Disconnect (Player Leave Flow)

```mermaid
flowchart LR
    subgraph START_LEAVE [" "]
        A([Start: Pemain disconnect atau leave])
    end
    
    subgraph DETECTION [" "]
        B[/Input: Socket disconnect detected/]
        C[Ambil UUID pemain yang keluar]
        D{Dalam game aktif?}
    end
    
    subgraph IN_GAME [" "]
        E[Tandai pemain hasLeft = true]
        F[Pertahankan data untuk hasil]
        G[Broadcast PLAYER_LEFT ke semua peer]
        H{Semua pemain aktif sudah finish?}
        I[Lanjut ke hasil race]
    end
    
    subgraph IN_LOBBY [" "]
        J[Hapus peer dari daftar]
        K[Broadcast PLAYER_LEFT ke semua peer]
        L[/Output: playerLeft signal/]
    end
    
    subgraph AUTHORITY_CHECK [" "]
        M{Apakah host yang keluar?}
        N[Migrasi authority ke UUID terendah]
        O[Update isAuthority untuk pemilik baru]
        P[/Output: authorityChanged signal/]
    end
    
    subgraph END_LEAVE [" "]
        Q([End: Pemain dihapus, game lanjut])
        R([End: Pemain dihapus dari lobby])
    end
    
    A --> B
    B --> C
    C --> D
    D -->|Ya| E
    E --> F
    F --> G
    G --> H
    H -->|Ya| I
    I --> M
    H -->|Tidak| M
    D -->|Tidak| J
    J --> K
    K --> L
    L --> M
    M -->|Ya| N
    N --> O
    O --> P
    P --> Q
    M -->|Tidak| Q
    Q --> R
```

---

## 9. Alur Lengkap Sistem Multiplayer (Complete System Flow)

```mermaid
flowchart LR
    subgraph ENTRY [" "]
        A([Start: Menu Multiplayer])
        B[/Input: Pilih Create atau Join/]
        C{Create Room?}
    end
    
    subgraph CREATE_FLOW [" "]
        D[Create Room]
        E[Start TCP Server]
        F[Start UDP Broadcast]
    end
    
    subgraph JOIN_FLOW [" "]
        G[Scan for Rooms]
        H[Select Room]
        I[Connect via TCP]
        J[Handshake HELLO]
        K[Build Full Mesh]
    end
    
    subgraph LOBBY [" "]
        L[Lobby State]
        M{Host klik Start?}
        N[Ready Check]
        O[Countdown 3s]
    end
    
    subgraph GAME [" "]
        P[Race Gameplay]
        Q[Progress Updates setiap 50ms]
        R{Selesai mengetik?}
        S[Kirim FINISH]
        T{Semua pemain selesai?}
    end
    
    subgraph RESULTS [" "]
        U[Calculate Rankings]
        V[Show Results]
        W{Play Again?}
    end
    
    subgraph EXIT [" "]
        X([End: Kembali ke menu])
    end
    
    A --> B
    B --> C
    C -->|Ya| D
    D --> E
    E --> F
    F --> L
    C -->|Tidak| G
    G --> H
    H --> I
    I --> J
    J --> K
    K --> L
    L --> M
    M -->|Ya| N
    N --> O
    O --> P
    M -->|Tidak| L
    P --> Q
    Q --> R
    R -->|Ya| S
    R -->|Tidak| P
    S --> T
    T -->|Tidak| P
    T -->|Ya| U
    U --> V
    V --> W
    W -->|Ya| L
    W -->|Tidak| X
```

---

## Legenda Simbol Flowchart

| Simbol | Bentuk | Keterangan |
|--------|--------|------------|
| `([...])` | Oval / Stadium | **Start** dan **End** - Titik awal dan akhir proses |
| `[...]` | Persegi Panjang | **Process** - Proses atau aksi yang dilakukan |
| `{...}` | Belah Ketupat | **Decision** - Keputusan dengan cabang Ya/Tidak |
| `[/.../]` | Jajar Genjang | **Input/Output** - Data masuk atau keluar sistem |

---

## Tipe Paket Jaringan

| Paket | Deskripsi | Arah |
|-------|-----------|------|
| `HELLO` | Handshake awal dengan info pemain | Bi-directional |
| `PEER_LIST` | Daftar peer untuk pembentukan mesh | Host → Guest |
| `READY_CHECK` | Permintaan konfirmasi ready | Host → All |
| `READY_RESPONSE` | Respons konfirmasi ready | Guest → Host |
| `COUNTDOWN` | Sinyal countdown sebelum race | Host → All |
| `GAME_START` | Sinyal mulai race | Host → All |
| `GAME_TEXT` | Distribusi teks game | Host → All |
| `PROGRESS_UPDATE` | Update progress mengetik real-time | All → All |
| `FINISH` | Notifikasi pemain selesai | All → All |
| `PLAYER_LEFT` | Notifikasi pemain keluar | All → All |
| `RACE_RESULTS` | Hasil akhir dengan ranking | Host → All |
| `PLAY_AGAIN_INVITE` | Undangan bermain lagi | Host → All |
| `PLAY_AGAIN_RESPONSE` | Respons undangan | Guest → Host |
| `KICK` | Mengeluarkan pemain | Host → Target |

---

## Konstanta Sistem

| Konstanta | Nilai | Keterangan |
|-----------|-------|------------|
| `DISCOVERY_PORT` | 52766 | Port UDP untuk discovery |
| `TCP_PORT` | 52765 | Port TCP untuk koneksi mesh |
| `ANNOUNCE_INTERVAL_MS` | 1000 | Interval broadcast (1 detik) |
| `PROGRESS_UPDATE_MS` | 50 | Interval update progress (50ms) |
| `ROOM_TIMEOUT_MS` | 5000 | Timeout room stale (5 detik) |
| `SCAN_TIMEOUT_MS` | 30000 | Timeout scanning (30 detik) |
| `MAX_PLAYERS` | 8 | Maksimum pemain per room |
