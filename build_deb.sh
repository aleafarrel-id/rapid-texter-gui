#!/bin/bash
set -e

# --- 1. Konfigurasi ---
APP_NAME="rapidtexter"
VERSION="1.0.0"
ARCH="amd64" 
BUILD_DIR="build-deb"
DEB_ROOT="deb-package-root"

# Cek apakah dpkg-deb terinstall
if ! command -v dpkg-deb &> /dev/null; then
    echo "Error: 'dpkg-deb' tidak ditemukan."
    echo "Jika Anda di Fedora, install dengan: sudo dnf install dpkg"
    echo "Jika di Ubuntu/Debian, ini sudah terinstall otomatis."
    exit 1
fi

# Cek Fakeroot (Penting untuk kepemilikan file root di dalam .deb)
if ! command -v fakeroot &> /dev/null; then
    echo "Warning: 'fakeroot' tidak ditemukan. File dalam .deb akan dimiliki oleh user Anda, bukan root."
    echo "Saran: Install fakeroot (sudo apt install fakeroot atau sudo dnf install fakeroot)"
    USE_FAKEROOT=""
else
    USE_FAKEROOT="fakeroot"
fi

# Pastikan di root project
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: Jalankan script ini dari root directory project."
    exit 1
fi

echo "--- 1. Membersihkan build lama ---"
rm -rf $BUILD_DIR $DEB_ROOT
mkdir -p $BUILD_DIR

# --- 2. Build Aplikasi ---
echo "--- 2. Membangun Aplikasi ---"
cd $BUILD_DIR

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
cd ..

# --- 3. Menyiapkan Struktur Folder DEB ---
echo "--- 3. Menyiapkan Struktur Folder ---"
# Buat struktur direktori
mkdir -p "$DEB_ROOT/DEBIAN"
mkdir -p "$DEB_ROOT/usr/bin"
mkdir -p "$DEB_ROOT/usr/share/applications"
mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps"

# Copy Binary
# Mencoba beberapa kemungkinan nama output binary
if [ -f "$BUILD_DIR/RapidTexterGUI" ]; then
    cp "$BUILD_DIR/RapidTexterGUI" "$DEB_ROOT/usr/bin/$APP_NAME"
elif [ -f "$BUILD_DIR/rapidtexter-gui" ]; then
    cp "$BUILD_DIR/rapidtexter-gui" "$DEB_ROOT/usr/bin/$APP_NAME"
elif [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$DEB_ROOT/usr/bin/$APP_NAME"
else
    echo "Error: Binary tidak ditemukan di folder build! Cek output cmake/make di atas."
    exit 1
fi

# Set permission binary agar executable
chmod 755 "$DEB_ROOT/usr/bin/$APP_NAME"

# Copy Icon (Pastikan file ada, jika tidak, buat dummy atau skip warning)
if [ -f "resources/app_icon.png" ]; then
    cp "resources/app_icon.png" "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"
    chmod 644 "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"
else
    echo "Warning: resources/app_icon.png tidak ditemukan. Icon dilewati."
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

# --- 4. Membuat Control File (Metadata DEB) ---
echo "--- 4. Membuat Control File ---"
cat > "$DEB_ROOT/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: education
Priority: optional
Architecture: $ARCH
Depends: libc6, libstdc++6, libqt6gui6, libqt6widgets6, libqt6qml6, qml6-module-qtquick, qml6-module-qtquick-controls, qml6-module-qtquick-layouts, libqt6core5compat6
Maintainer: Alea Farrel <your-email@example.com>
Description: Typing practice application
 RapidTexter is a typing practice application built with Qt/QML designed for speed and efficiency.
EOF

# --- [CRITICAL FIX] Mengatur Permission Folder DEBIAN ---
# dpkg-deb akan gagal jika permission folder control salah
echo "Fixing permissions..."
chmod 755 "$DEB_ROOT/DEBIAN"
chmod 644 "$DEB_ROOT/DEBIAN/control"

# --- 5. Build DEB ---
echo "--- 5. Membungkus DEB ---"
# Menggunakan fakeroot agar file di dalam .deb dimiliki oleh root
if [ -n "$USE_FAKEROOT" ]; then
    $USE_FAKEROOT dpkg-deb --build "$DEB_ROOT" "${APP_NAME}_${VERSION}_${ARCH}.deb"
else
    dpkg-deb --build "$DEB_ROOT" "${APP_NAME}_${VERSION}_${ARCH}.deb"
fi

echo "-----------------------------------------------------"
echo "SUKSES! File DEB Anda siap:"
ls -lh "${APP_NAME}_${VERSION}_${ARCH}.deb"
echo "-----------------------------------------------------"