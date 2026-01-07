#!/bin/bash
set -e

# --- 1. Konfigurasi ---
APP_NAME="rapidtexter"
VERSION="1.0.0"
ARCH="amd64"
BUILD_DIR="build-manual"
DEB_ROOT="deb-manual-root"
INSTALL_PREFIX="/opt/$APP_NAME" # Instalasi ke /opt agar rapi

echo "============================================="
echo "   BUILD DEB MANUAL BUNDLE (TANPA LINUXDEPLOYQT)"
echo "============================================="

# --- 2. Mencari Qt Manual ---
# Kita perlu tahu di mana Qt terinstall untuk menyalin library-nya
DETECTED_QT=$(find "$HOME/Qt" -maxdepth 3 -name "gcc_64" -type d 2>/dev/null | sort -r | head -n 1)

if [ -n "$DETECTED_QT" ]; then
    echo "✅ Menggunakan Qt Manual: $DETECTED_QT"
    export CMAKE_PREFIX_PATH="$DETECTED_QT"
    export PATH="$DETECTED_QT/bin:$PATH"
    QT_PLUGINS_DIR="$DETECTED_QT/plugins"
    QT_QML_DIR="$DETECTED_QT/qml"
    QT_LIB_DIR="$DETECTED_QT/lib"
else
    echo "❌ Error: Qt Manual tidak ditemukan di $HOME/Qt"
    exit 1
fi

# --- 3. Build Aplikasi ---
echo "--- Membangun Aplikasi ---"
rm -rf "$BUILD_DIR" "$DEB_ROOT"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
cd ..

# --- 4. Siapkan Struktur Folder (/opt/rapidtexter) ---
echo "--- Menyiapkan Struktur Bundle ---"
TARGET_DIR="$DEB_ROOT$INSTALL_PREFIX"
mkdir -p "$TARGET_DIR/bin"
mkdir -p "$TARGET_DIR/lib"
mkdir -p "$TARGET_DIR/plugins"
mkdir -p "$TARGET_DIR/qml"

# Copy Binary Asli (Kita ganti namanya jadi rapidtexter-bin)
# Nanti 'rapidtexter' yang asli adalah script launcher
if [ -f "$BUILD_DIR/RapidTexterGUI" ]; then
    cp "$BUILD_DIR/RapidTexterGUI" "$TARGET_DIR/bin/rapidtexter-bin"
elif [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$TARGET_DIR/bin/rapidtexter-bin"
else
    echo "Error: Binary tidak ditemukan."
    exit 1
fi
chmod 755 "$TARGET_DIR/bin/rapidtexter-bin"

# --- 5. MANUAL BUNDLING (Bagian Inti) ---
echo "--- Menyalin Library Qt Secara Manual ---"

# A. Menyalin Library .so (Shared Objects)
# Kita gunakan 'ldd' untuk melihat library apa saja yang dipakai binary,
# lalu kita filter hanya library yang berasal dari folder Qt Manual.
echo "   -> Menganalisis dependensi dengan ldd..."
BINARY_PATH="$TARGET_DIR/bin/rapidtexter-bin"

# Logic: ldd -> ambil path -> filter string "Qt" (agar library sistem tdk ikut) -> copy ke lib/
ldd "$BINARY_PATH" | awk '{print $3}' | grep "$DETECTED_QT" | sort | uniq | while read -r LIB_PATH; do
    if [ -f "$LIB_PATH" ]; then
        echo "      Copying: $(basename $LIB_PATH)"
        cp -L "$LIB_PATH" "$TARGET_DIR/lib/"
    fi
done

# B. Menyalin Plugins (Wajib untuk GUI)
echo "   -> Menyalin Qt Plugins (platforms, xcb, imageformats)..."
mkdir -p "$TARGET_DIR/plugins/platforms"
mkdir -p "$TARGET_DIR/plugins/xcbglintegrations"
mkdir -p "$TARGET_DIR/plugins/imageformats"

# Plugin Platform (Agar window muncul)
cp "$QT_PLUGINS_DIR/platforms/libqxcb.so" "$TARGET_DIR/plugins/platforms/"
# Plugin Gambar (SVG, JPG, dll)
cp -r "$QT_PLUGINS_DIR/imageformats" "$TARGET_DIR/plugins/"
# Plugin XCB (Untuk integrasi GL/Linux)
if [ -d "$QT_PLUGINS_DIR/xcbglintegrations" ]; then
    cp -r "$QT_PLUGINS_DIR/xcbglintegrations" "$TARGET_DIR/plugins/"
fi

# C. Menyalin QML Modules (Wajib untuk QtQuick & Qt5Compat)
echo "   -> Menyalin QML Modules (QtQuick, Qt5Compat)..."
# Kita copy modul-modul penting.
# PERINGATAN: Folder QML bisa sangat besar. Kita hanya ambil yang umum dipakai.
MODULES_TO_COPY=("Qt" "QtQuick" "Qt5Compat" "QtQml")

for MOD in "${MODULES_TO_COPY[@]}"; do
    if [ -d "$QT_QML_DIR/$MOD" ]; then
        echo "      Copying QML Module: $MOD"
        mkdir -p "$TARGET_DIR/qml/$MOD"
        cp -r "$QT_QML_DIR/$MOD"/* "$TARGET_DIR/qml/$MOD/"
    fi
done

# --- 6. Konfigurasi Runtime (qt.conf & Launcher) ---

# Buat qt.conf agar binary tahu lokasi library relatifnya
cat > "$TARGET_DIR/bin/qt.conf" <<EOF
[Paths]
Prefix=..
Plugins=plugins
Imports=qml
Qml2Imports=qml
EOF

# Buat Launcher Script
# Ini pengganti RPATH. Script ini mengatur LD_LIBRARY_PATH sebelum menjalankan aplikasi.
cat > "$TARGET_DIR/bin/$APP_NAME" <<EOF
#!/bin/sh
appname=\$(basename "\$0")
dirname=\$(dirname "\$0")
tmp="\${dirname#?}"

if [ "\${dirname%\$tmp}" != "/" ]; then
dirname=\$PWD/\$dirname
fi

# Set library path ke folder lib di dalam bundle
LD_LIBRARY_PATH=\$dirname/../lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

# Jalankan binary asli
"\$dirname/rapidtexter-bin" "\$@"
EOF

chmod +x "$TARGET_DIR/bin/$APP_NAME"

# --- 7. Integrasi Sistem (Desktop File, Icon, Symlink) ---
mkdir -p "$DEB_ROOT/usr/share/applications"
mkdir -p "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$DEB_ROOT/usr/bin"

# Icon
cp "resources/app_icon.png" "$DEB_ROOT/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"

# Symlink ke /usr/bin (menunjuk ke script launcher di /opt)
ln -s "$INSTALL_PREFIX/bin/$APP_NAME" "$DEB_ROOT/usr/bin/$APP_NAME"

# Desktop File
cat > "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Rapid Texter
Comment=Typing practice application
Exec=$INSTALL_PREFIX/bin/$APP_NAME
Icon=rapidtexter
Categories=Game;Education;
Terminal=false
EOF
chmod 644 "$DEB_ROOT/usr/share/applications/$APP_NAME.desktop"

# --- 8. Build DEB ---
echo "--- Membungkus DEB ---"
mkdir -p "$DEB_ROOT/DEBIAN"

cat > "$DEB_ROOT/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: education
Priority: optional
Architecture: $ARCH
Depends: libc6, libgl1
Maintainer: Alea Farrel <your-email@example.com>
Description: Typing practice application (Standalone)
 RapidTexter is a typing practice application.
 This package includes pre-bundled Qt libraries manually.
EOF

chmod 755 "$DEB_ROOT/DEBIAN"
chmod 644 "$DEB_ROOT/DEBIAN/control"

DEB_NAME="${APP_NAME}_${VERSION}_manualbundle_${ARCH}.deb"
rm -f "$DEB_NAME"

if command -v fakeroot &> /dev/null; then
    fakeroot dpkg-deb --build "$DEB_ROOT" "$DEB_NAME"
else
    dpkg-deb --build "$DEB_ROOT" "$DEB_NAME"
fi

echo "====================================================="
echo "✅ SUKSES! Paket Manual Bundle Siap: $DEB_NAME"
echo "   Install dengan: sudo dpkg -i $DEB_NAME"
echo "====================================================="