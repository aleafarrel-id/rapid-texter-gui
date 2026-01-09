/**
 * @file main.cpp
 * @brief Entry point for the RapidTexter GUI typing test application.
 * @author RapidTexter Team (Alea Farrel, Hensa Katelu, Yanuar Adi Candra,
 *         Arif Wibowo P., Aria Mahendra U.)
 * @date 2026
 *
 * This file initializes the Qt application, sets up the GameBackend
 * singleton for game logic, and loads the main QML interface.
 *
 * @see GameBackend For the C++ backend handling game state, history,
 *      word generation, and sound effects.
 * @see NetworkManager For the multiplayer networking backend.
 * @see Main.qml For the main QML application window and UI components.
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "GameBackend.h"
#include "NetworkManager.h"

/**
 * @brief Application entry point.
 *
 * Initializes the Qt GUI application with the following steps:
 * 1. Creates QGuiApplication instance for event handling
 * 2. Sets organization/application name for QStandardPaths (used for
 *    persistent storage of game history and settings)
 * 3. Creates GameBackend singleton before QML loads (ensures backend
 *    is ready when QML components request it)
 * 4. Registers GameBackend as a QML singleton accessible via
 *    "import rapid_texter 1.0"
 * 5. Loads the main QML module and starts the event loop
 *
 * @param argc Command-line argument count
 * @param argv Command-line argument values
 * @return Exit code (0 for success, -1 if QML object creation fails)
 */
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    /*
     * Set application metadata for QStandardPaths.
     * This determines where persistent data (history.json, progress.json)
     * is stored on the user's system.
     */
    app.setOrganizationName("RapidTexter");
    app.setApplicationName("RapidTexter");

    /*
     * Create GameBackend singleton instance BEFORE loading QML.
     * This ensures the backend is fully initialized when QML components
     * attempt to access it. The singleton pattern guarantees only one
     * instance exists throughout the application lifecycle.
     */
    GameBackend* backend = GameBackend::instance();
    
    /*
     * Create NetworkManager singleton for multiplayer functionality.
     * Handles UDP discovery, WebSocket lobby, and UDP multicast gameplay.
     */
    NetworkManager* networkManager = NetworkManager::instance();

    QQmlApplicationEngine engine;

    /*
     * Register GameBackend as a QML singleton.
     * - Module: "rapid_texter"
     * - Version: 1.0
     * - QML name: "GameBackend"
     * After this, QML can access it via: import rapid_texter 1.0
     */
    qmlRegisterSingletonInstance("rapid_texter", 1, 0, "GameBackend", backend);
    
    /*
     * Register NetworkManager as a QML singleton for multiplayer.
     */
    qmlRegisterSingletonInstance("rapid_texter", 1, 0, "NetworkManager", networkManager);

    /*
     * Connect to objectCreationFailed signal to handle QML loading errors.
     * If the main QML file fails to load, exit with error code -1.
     * Qt::QueuedConnection ensures the exit happens after the signal
     * is fully processed.
     */
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    /* Load the main QML module - this triggers the UI creation */
    engine.loadFromModule("rapid_texter", "Main");

    /* Start the Qt event loop - blocks until application quits */
    return app.exec();
}
