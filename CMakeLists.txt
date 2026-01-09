cmake_minimum_required(VERSION 3.16)

project(RapidTexterGUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Find Qt packages
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 Multimedia Network)

qt_standard_project_setup(REQUIRES 6.8)
qt_policy(SET QTP0004 OLD)

# C++ Source files for game logic
set(GAME_LOGIC_SOURCES
    src/GameBackend.cpp
    src/TextProvider.cpp
    src/HistoryManager.cpp
    src/ProgressManager.cpp
    src/SettingsManager.cpp
    src/NetworkManager.cpp
)

# Header files
set(GAME_LOGIC_HEADERS
    include/GameBackend.h
    include/TextProvider.h
    include/HistoryManager.h
    include/ProgressManager.h
    include/SettingsManager.h
    include/Stats.h
    include/NetworkManager.h
)

# Windows application icon (only include on Windows)
if(WIN32)
    set(APP_ICON_RESOURCE_WINDOWS "${CMAKE_CURRENT_SOURCE_DIR}/resources/app.rc")
endif()

qt_add_executable(RapidTexterGUI
    main.cpp
    ${GAME_LOGIC_SOURCES}
    ${GAME_LOGIC_HEADERS}
    $<$<BOOL:${WIN32}>:${APP_ICON_RESOURCE_WINDOWS}>
)

# Add include directory for headers
target_include_directories(RapidTexterGUI PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Mark Theme.qml as a singleton
set_source_files_properties(qml/components/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(RapidTexterGUI
    URI rapid_texter
    VERSION 1.0
    QML_FILES
        Main.qml
        # Components
        qml/components/Theme.qml
        qml/components/MenuItemC.qml
        qml/components/NavBtn.qml
        qml/components/StatusBar.qml
        qml/components/HistoryDetailOverlay.qml
        qml/components/SplashScreen.qml
        # Pages
        qml/pages/MainMenuPage.qml
        qml/pages/LanguageMenuPage.qml
        qml/pages/DurationMenuPage.qml
        qml/pages/CustomDurationPage.qml
        qml/pages/ModeMenuPage.qml
        qml/pages/ManualSetupPage.qml
        qml/pages/CampaignMenuPage.qml
        qml/pages/ResultsPage.qml
        qml/pages/HistoryPage.qml
        qml/pages/CreditsPage.qml
        qml/pages/ResetHistoryPage.qml
        qml/pages/ResetProgressPage.qml
        qml/pages/GameplayPage.qml
        # Multiplayer Pages
        qml/pages/MultiplayerMenuPage.qml
        qml/pages/PlayerNamePage.qml
        qml/pages/GameBrowserPage.qml
        qml/pages/LobbyPage.qml
        qml/pages/RaceGameplayPage.qml
        qml/pages/RaceResultsPage.qml
        # Multiplayer Components
        qml/components/RaceTrack.qml
        qml/components/RaceLane.qml
        qml/components/CountdownOverlay.qml
    RESOURCES
        # Fonts
        assets/font/JetBrainsMono.ttf
        # Word banks
        assets/en.txt
        assets/id.txt
        assets/prog.txt
        # SFX
        assets/sfx/true.wav
        assets/sfx/false.wav
        # Icons
        assets/icons/globe.svg
        assets/icons/clock.svg
        assets/icons/gamepad.svg
        assets/icons/volume-on.svg
        assets/icons/volume-off.svg
        assets/icons/play.svg
        assets/icons/history.svg
        assets/icons/close.svg
        assets/icons/arrow-left.svg
        assets/icons/arrow-right.svg
        assets/icons/campaign.svg
        assets/icons/manual.svg
        assets/icons/hand.svg
        assets/icons/trophy.svg
        assets/icons/leaf.svg
        assets/icons/trend-up.svg
        assets/icons/fire.svg
        assets/icons/monitor.svg
        assets/icons/users.svg
        assets/icons/user.svg
        assets/icons/refresh.svg
        assets/icons/trash.svg
        assets/icons/warning.svg
        assets/icons/check.svg
        assets/icons/heart.svg
        assets/icons/target.svg
        assets/icons/lock.svg
        assets/icons/unlock.svg
        assets/icons/terminal.svg
        assets/icons/send.svg
        assets/icons/arrow-down-circle.svg
        assets/icons/cpu.svg
        assets/icons/info.svg
        assets/icons/infinity.svg
        assets/icons/sliders.svg
        assets/icons/chevron-up.svg
        assets/icons/chevron-down.svg
)

set_target_properties(RapidTexterGUI PROPERTIES
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(RapidTexterGUI
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia Qt6::Network
)

# --- Installation Rules (untuk Flatpak dan RPM) ---
include(GNUInstallDirs)

# Install executable
install(TARGETS RapidTexterGUI
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install desktop file
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/io.github.aleafarrel.RapidTexter.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

# Install AppStream metainfo
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/io.github.aleafarrel.RapidTexter.metainfo.xml
    DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo
)

# Install icon
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/resources/app_icon.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps
    RENAME io.github.aleafarrel.RapidTexter.png
)
