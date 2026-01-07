#!/bin/bash
set -e

# --- 1. Konfigurasi ---
APP_NAME="rapidtexter"
VERSION="1.0.0"
ARCH="amd64" 
BUILD_DIR="build-deb"
DEB_ROOT="deb-package-root"

# --- KONFIGURASI QT MANUAL (PENTING) ---
# Script akan mencoba mencari instalasi Qt di folder Home pengguna.
# Jika Anda menginstall di lokasi lain, ubah path di bawah ini secara manual.
echo "--- Mencari Instalasi Qt Manual ---"

# Mencari folder 'gcc_64' terbaru di ~/Qt
# Logika: Cari di ~/Qt, max kedalaman 3 folder, cari folder bernama gcc_64, urutkan terbalik (versi terbaru biasanya di atas), ambil yang pertama.
DETECTED_QT=$(find "$HOME/Qt" -maxdepth 3 -name "gcc_64" -type d 2>/dev/null | sort -r | head -n 1)

if [ -n "$DETECTED_QT" ]; then
    echo "✅ Ditemukan Qt Manual di: $DETECTED_QT"
    export CMAKE_PREFIX_PATH="$DETECTED_QT"
    # Tambahkan ke path agar CMake bisa menemukan tools Qt
    export PATH="$DETECTED_QT/bin:$PATH"
else
    echo "❌ TIDAK DITEMUKAN instalasi Qt Manual di $HOME/Qt."
    echo "Pastikan Anda sudah menginstall Qt dari website resminya."
    echo "Jika lokasi install Anda berbeda, edit baris 'export CMAKE_PREFIX_PATH' di script ini secara manual."
    exit 1
fi

# Cek dpkg-deb
if ! command -v dpkg-deb &> /dev/null; then
    echo "Error: 'dpkg-deb' tidak ditemukan."
    exit 1
fi

# Cek Fakeroot
if ! command -v fakeroot &> /dev/null; then
    echo "Warning: 'fakeroot' tidak ditemukan. File dalam .deb akan dimiliki oleh user Anda."
    USE_FAKEROOT=""
else
    USE_FAKEROOT="fakeroot"
fi

if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: Jalankan dari root project."
    exit 1
fi

echo "--- 1. Membersihkan build lama ---"
rm -rf "$BUILD_DIR" "$DEB_ROOT"
mkdir -p "$BUILD_DIR"

# --- 2. Build Aplikasi ---
echo "--- 2. Membangun Aplikasi dengan Qt Manual ---"
cd "$BUILD_DIR"

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
cd ..

# --- 3. Menyiapkan Struktur Folder DEB ---
echo "--- 3. Menyiapkan Struktur Folder ---"
mkdir -p "$DEB_ROOT/DEBIAN"
mkdir -p "$DEB_ROOT/usr/bin"
mkdir -p "$DEB_ROOT/usr/share/applications"
mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps"

# Copy Binary
if [ -f "$BUILD_DIR/RapidTexterGUI" ]; then
    cp "$BUILD_DIR/RapidTexterGUI" "$DEB_ROOT/usr/bin/$APP_NAME"
elif [ -f "$BUILD_DIR/rapidtexter-gui" ]; then
    cp "$BUILD_DIR/rapidtexter-gui" "$DEB_ROOT/usr/bin/$APP_NAME"
elif [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$DEB_ROOT/usr/bin/$APP_NAME"
else
    echo "Error: Binary tidak ditemukan! Build gagal."
    exit 1
fi

chmod 755 "$DEB_ROOT/usr/bin/$APP_NAME"

# Copy Icon
if [ -f "resources/app_icon.png" ]; then
    cp "resources/app_icon.png" "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"
    chmod 644 "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"
fi

# Buat Desktop File
cat > "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Rapid Texter
Comment=Typing practice application
Exec=$APP_NAME
Icon=rapidtexter
Categories=Game;Education;
Terminal=false
EOF
chmod 644 "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop"

# --- 4. Membuat Control File ---
echo "--- 4. Membuat Control File ---"
# CATATAN: Karena menggunakan Qt Manual, dependency sistem di bawah ini mungkin tidak 
# sepenuhnya akurat untuk dijalankan di komputer lain (karena versi Qt library sistem mungkin berbeda).
# Namun ini cukup untuk membuat file .deb berhasil dibuat dan diinstall di komputer ini.
cat > "$DEB_ROOT/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: education
Priority: optional
Architecture: $ARCH
Depends: libc6, libstdc++6, libgl1
Maintainer: Alea Farrel <your-email@example.com>
Description: Typing practice application
 RapidTexter is a typing practice application built with Qt/QML designed for speed and efficiency.
EOF

# --- [CRITICAL FIX] Permission ---
echo "Fixing permissions..."
chmod 755 "$DEB_ROOT/DEBIAN"
chmod 644 "$DEB_ROOT/DEBIAN/control"

# --- 5. Build DEB ---
echo "--- 5. Membungkus DEB ---"
rm -f "${APP_NAME}_${VERSION}_${ARCH}.deb"

if [ -n "$USE_FAKEROOT" ]; then
    $USE_FAKEROOT dpkg-deb --build "$DEB_ROOT" "${APP_NAME}_${VERSION}_${ARCH}.deb"
else
    dpkg-deb --build "$DEB_ROOT" "${APP_NAME}_${VERSION}_${ARCH}.deb"
fi

echo "-----------------------------------------------------"
echo "SUKSES! File DEB siap (Built with Manual Qt):"
ls -lh "${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "-----------------------------------------------------"