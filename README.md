<div align="center">

# 🚀 Rapid Texter GUI

![C++](https://img.shields.io/badge/C++-17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Qt](https://img.shields.io/badge/Qt-6.8-41CD52?style=for-the-badge&logo=qt&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Uji kecepatan jari dan ketepatan pikiran Anda dengan tampilan modern.** Rapid Texter kini hadir dengan antarmuka **GUI (Graphical User Interface)** yang memukau, animasi halus, dan pengalaman pengguna yang lebih intuitif.

[Fitur](#-fitur-utama) • [Download](#-download--instalasi) • [Cara Build](#%EF%B8%8F-cara-build-dari-source) • [Kontribusi](#-lisensi)

</div>

---

## ⚡ Fitur Utama

* **✨ Modern GUI:** Dibangun menggunakan **Qt/QML 6.8**, menghadirkan tampilan yang estetis dan responsif.
* **🌐 Multi-Bahasa:** Tersedia mode Bahasa Indonesia & Bahasa Inggris.
* **💻 Mode Programmer:** Latih pengetikan simbol dan sintaks koding (`#include`, `std::vector`, dll).
* **📊 Statistik Visual:** Pantau WPM (*Words Per Minute*), Akurasi, dan Grafik Progress dengan tampilan visual yang menarik.
* **🎨 Tema & Animasi:** Transisi antar menu yang halus dan desain antarmuka yang nyaman di mata.
* **🎵 Sound Effects:** Umpan balik audio yang memuaskan saat mengetik benar (ding!) atau salah.
* **🖱️ Mouse & Keyboard Friendly:** Navigasi menu bisa menggunakan mouse atau tetap dengan keyboard untuk kecepatan.

---

## 📥 Download & Instalasi

Cara termudah untuk menggunakan Rapid Texter adalah dengan mengunduh installer yang sudah kami sediakan.

### 🪟 Windows (Recommended)
1. Buka halaman **[Releases](https://github.com/aleafarrel-id/rapidtexter-gui/releases)** terbaru.
2. Download file `RapidTexterGUI_win64-Setup.exe`.
3. Jalankan file `.exe` dan ikuti petunjuk instalasi.
4. Aplikasi siap digunakan! Shortcut akan tersedia di Desktop dan Start Menu.

### 🐧 Linux (AppImage)
1. Download file `.AppImage` dari halaman Releases.
2. Berikan izin eksekusi: `chmod +x RapidTexterGUI-x86_64.AppImage`.
3. Jalankan aplikasinya!

---

## 🎮 Cara Menggunakan Aplikasi

### 1. Menu Utama
Tampilan awal yang elegan memudahkan Anda memilih mode:
- **Play Game**: Mulai permainan baru.
- **History**: Lihat grafik perkembangan kecepatan mengetik Anda.
- **Settings**: Atur efek suara dan preferensi lainnya.

### 2. Kustomisasi Permainan
Sebelum mulai, Anda bisa mengatur:
- **Bahasa**: Indonesia (ID) atau English (EN).
- **Waktu**: 15s, 30s, 60s, atau Custom.
- **Mode**:
    - **Manual**: Target WPM bebas.
    - **Campaign**: Level bertingkat (Easy, Medium, Hard, Programmer).

### 3. Gameplay
Ketik teks yang muncul di layar.
- **Hijau**: Huruf benar.
- **Merah**: Huruf salah.
- **Backspace**: Bisa digunakan untuk meralat kesalahan sebelumnya.

### 4. Hasil & Evaluasi
Di akhir sesi, Anda akan melihat kartu hasil yang menampilkan:
- **WPM Besar**: Angka kecepatan utama.
- **Akurasi**: Persentase ketepatan.
- **Grafik**: Perbandingan dengan sesi sebelumnya (jika ada).

---

## 🛠️ Cara Build dari Source

Bagi developer yang ingin mengembangkan atau memodifikasi kode sumber.

### Prasyarat
1.  **Qt 6.8** (Install via Qt Online Installer, pilih komponen **Qt Quick**, **Qt Quick Controls 2**, **Qt Multimedia**).
2.  **C++ Compiler** (MSVC 2019+ atau GCC//Clang terbaru).
3.  **CMake** versi 3.16 ke atas.

### Langkah Build

Clone repository ini:
```bash
git clone https://github.com/aleafarrel-id/rapidtexter-gui.git
cd rapidtexter-gui
```

Lakukan build menggunakan CMake:

```bash
# 1. Konfigurasi (Pastikan path Qt 6.8 sudah benar/terdeteksi)
cmake -S . -B build

# 2. Compile
cmake --build build --config Release
```

### Jalankan Aplikasi
Hasil build akan ada di folder `build/Release/` (Windows) atau `build/` (Linux).

---

## 📂 Struktur Project

```text
rapidtexter-gui/
├── assets/             # Word banks, fonts, icons, sfx
├── src/                # C++ Backend logic (GameBackend, Stats, etc.)
├── include/            # Header files C++
├── qml/                # Antarmuka Pengguna (Qt Quick/QML)
│   ├── components/     # Komponen UI reusable (Button, Card, etc.)
│   └── pages/          # Halaman layar (Menu, Game, Result)
├── resources/          # Resource definition (.rc and icons)
├── CMakeLists.txt      # Konfigurasi Build CMake
└── README.md           # Dokumentasi ini
```

## 📜 Lisensi

Project ini dilisensikan di bawah **MIT License**. Bebas untuk digunakan, dimodifikasi, dan didistribusikan.

---
<div align="center">
  Developed 2025 by Alea Farrel & Team.
</div>
