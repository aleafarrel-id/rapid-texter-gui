#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "GameBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Set application metadata for QStandardPaths
    app.setOrganizationName("RapidTexter");
    app.setApplicationName("RapidTexter");
    
    // Create GameBackend singleton instance BEFORE loading QML
    GameBackend* backend = GameBackend::instance();
    
    QQmlApplicationEngine engine;
    
    // Register GameBackend as QML singleton
    qmlRegisterSingletonInstance("rapid_texter", 1, 0, "GameBackend", backend);
    
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("rapid_texter", "Main");

    return app.exec();
}
