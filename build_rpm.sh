#!/bin/bash
set -e

# --- 1. Konfigurasi ---
APP_NAME="rapidtexter"
VERSION="1.0.0"  # Ubah versi sesuai keinginan
BUILD_DIR="build-rpm"
RPM_ROOT="rpm-build-root"
STAGING_DIR="staging"

# Cek apakah rpmbuild terinstall
if ! command -v rpmbuild &> /dev/null; then
    echo "Error: 'rpmbuild' tidak ditemukan."
    echo "Silakan install dengan: sudo dnf install rpm-build"
    exit 1
fi

# Pastikan di root project
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: Jalankan script ini dari root directory project."
    exit 1
fi

echo "--- 1. Membersihkan build lama ---"
rm -rf $BUILD_DIR $RPM_ROOT $STAGING_DIR
mkdir -p $BUILD_DIR

# --- 2. Build Aplikasi ---
echo "--- 2. Membangun Aplikasi ---"
cd $BUILD_DIR

# Kita gunakan flag standar untuk Fedora. Tidak perlu workaround aneh-aneh seperti di AppImage.
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
cd ..

# --- 3. Menyiapkan Staging Directory (Meniru struktur instalasi) ---
echo "--- 3. Menyiapkan Struktur Folder ---"
mkdir -p $STAGING_DIR/usr/bin
mkdir -p $STAGING_DIR/usr/share/applications
mkdir -p $STAGING_DIR/usr/share/icons/hicolor/256x256/apps

# Copy Binary
if [ -f "$BUILD_DIR/RapidTexterGUI" ]; then
    cp "$BUILD_DIR/RapidTexterGUI" "$STAGING_DIR/usr/bin/$APP_NAME"
elif [ -f "$BUILD_DIR/rapidtexter-gui" ]; then
    cp "$BUILD_DIR/rapidtexter-gui" "$STAGING_DIR/usr/bin/$APP_NAME"
else
    echo "Error: Binary tidak ditemukan!"
    exit 1
fi
chmod +x "$STAGING_DIR/usr/bin/$APP_NAME"

# Copy Icon
cp resources/app_icon.png "$STAGING_DIR/usr/share/icons/hicolor/256x256/apps/rapidtexter.png"

# Buat Desktop File
cat > "$STAGING_DIR/usr/share/applications/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Rapid Texter
Comment=Typing practice application
Exec=$APP_NAME
Icon=rapidtexter
Categories=Game;Education;
Terminal=false
EOF

# --- 4. Membuat File SPEC (Resep RPM) ---
echo "--- 4. Membuat File SPEC ---"
mkdir -p $RPM_ROOT/SPECS
mkdir -p $RPM_ROOT/BUILD
mkdir -p $RPM_ROOT/RPMS
mkdir -p $RPM_ROOT/SRPMS

# Kita definisikan dependencies Qt6 standar Fedora di sini
cat > $RPM_ROOT/SPECS/$APP_NAME.spec <<EOF
Name:           $APP_NAME
Version:        $VERSION
Release:        1%{?dist}
Summary:        Typing practice application designed for speed and efficiency
License:        MIT
URL:            https://github.com/aleafarrel/rapidtexter-gui
BuildArch:      x86_64

# Dependencies yang dibutuhkan user saat menginstall RPM ini
Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       qt6-qtmultimedia
Requires:       qt6-qtsvg
Requires:       qt6-qt5compat

%description
RapidTexter is a typing practice application built with Qt/QML.

%install
# Langkah ini meng-copy file dari folder staging kita ke dalam sistem build RPM
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps

cp -r $(pwd)/$STAGING_DIR/usr/bin/* %{buildroot}/usr/bin/
cp -r $(pwd)/$STAGING_DIR/usr/share/applications/* %{buildroot}/usr/share/applications/
cp -r $(pwd)/$STAGING_DIR/usr/share/icons/* %{buildroot}/usr/share/icons/

%files
/usr/bin/$APP_NAME
/usr/share/applications/$APP_NAME.desktop
/usr/share/icons/hicolor/256x256/apps/rapidtexter.png

%changelog
* $(date "+%a %b %d %Y") Developer <dev@example.com> - $VERSION-1
- Generated via build_rpm.sh script
EOF

# --- 5. Build RPM ---
echo "--- 5. Membungkus RPM ---"
rpmbuild --define "_topdir $(pwd)/$RPM_ROOT" \
         -bb $RPM_ROOT/SPECS/$APP_NAME.spec

echo "-----------------------------------------------------"
echo "SUKSES! File RPM Anda berada di:"
find $RPM_ROOT/RPMS -name "*.rpm"
echo "-----------------------------------------------------"
echo "Untuk menginstall (test):"
echo "sudo dnf install $(find $RPM_ROOT/RPMS -name "*.rpm" | head -n 1)"