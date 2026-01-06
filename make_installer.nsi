; Script NSIS untuk RapidTexter GUI
; Dibuat untuk aleafarrel-id/rapidtexter-gui

;--------------------------------
; Include Modern UI
; Ini membuat tampilan installer terlihat modern
!include "MUI2.nsh"

;--------------------------------
; Konfigurasi Umum

; Nama Aplikasi
!define APP_NAME "Rapid Texter"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Alea Farrel & Team"
!define APP_EXE "RapidTexterGUI.exe" ; Disesuaikan dengan nama file di folder deploy

; Nama file installer yang akan dihasilkan
Name "${APP_NAME}"
OutFile "RapidTexterGUI_win64-Setup.exe"

; Folder instalasi default (Program Files 64-bit)
InstallDir "$PROGRAMFILES64\${APP_NAME}"

; Meminta hak akses admin untuk install ke Program Files
RequestExecutionLevel admin

; Kompresi terbaik
SetCompressor /SOLID lzma

;--------------------------------
; Konfigurasi Antarmuka (Interface)

; Icon Installer (Pastikan path ini benar relatif terhadap file .nsi)
!define MUI_ICON "resources\app_icon.ico"
!define MUI_UNICON "resources\app_icon.ico"

; Header image (Opsional, hapus jika error)
; !define MUI_HEADERIMAGE
; !define MUI_HEADERIMAGE_BITMAP "resources\header.bmp" 

; Halaman-halaman Installer
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE" ; Menggunakan file LICENSE yang ada di root
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Halaman-halaman Uninstaller
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Bahasa Installer
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Indonesian"

;--------------------------------
; Section - Instalasi Utama

Section "MainGame" SecMain
    ; Set folder tujuan instalasi
    SetOutPath "$INSTDIR"
    
    ; --- COPY FILES ---
    ; PENTING: Kita mengambil file dari folder 'deploy' yang sudah disiapkan
    ; Tanda * berarti mengambil semua isi folder tersebut (DLL, plugins, assets, exe)
    File /r "deploy\*"

    ; Buat Uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; Tambahkan entry ke Windows "Add/Remove Programs"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" \
                     "DisplayIcon" "$INSTDIR\${APP_EXE}"

SectionEnd

;--------------------------------
; Section - Shortcut (Menu Start & Desktop)

Section "Start Menu & Desktop Shortcuts" SecShortcuts
    SetOutPath "$INSTDIR"
    
    ; Buat Shortcut di Desktop
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    
    ; Buat Folder di Start Menu
    CreateDirectory "$SMPROGRAMS\${APP_NAME}"
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
SectionEnd

;--------------------------------
; Section - Uninstaller

Section "Uninstall"
    ; Hapus file instalasi
    ; /r berarti rekursif (hati-hati, ini menghapus folder instalasi)
    RMDir /r "$INSTDIR"

    ; Hapus Shortcut Desktop
    Delete "$DESKTOP\${APP_NAME}.lnk"

    ; Hapus Shortcut Start Menu
    RMDir /r "$SMPROGRAMS\${APP_NAME}"

    ; Hapus Registry Keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd