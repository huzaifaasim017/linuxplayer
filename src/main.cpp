// SPDX-License-Identifier: GPL-3.0-or-later
#include "MpvItem.h"
#include "WindowOperations.h"

#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QTimer>
#include <QUrl>

#include <clocale>

int main(int argc, char *argv[])
{
    // QQuickFramebufferObject needs OpenGL, including under Wayland.
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("LinuxPlayer"));
    app.setOrganizationName(QStringLiteral("TeamKrope"));
    app.setDesktopFileName(QStringLiteral("io.github.teamkrope.LinuxPlayer"));

    // libmpv requires the numeric C locale after Qt's application setup.
    std::setlocale(LC_NUMERIC, "C");

    qmlRegisterType<MpvItem>("LinuxPlayer", 1, 0, "MpvItem");
    WindowOperations windowOperations;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("windowOperations"), &windowOperations);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return 1;

    const QStringList arguments = app.arguments();
    const bool captureRestored = arguments.contains(QStringLiteral("--capture-restored"));
    const bool captureMini = captureRestored || arguments.contains(QStringLiteral("--capture-mini"));
    const bool captureHidden = arguments.contains(QStringLiteral("--capture-hidden"));
    const int captureIndex = arguments.indexOf(captureRestored ? QStringLiteral("--capture-restored")
                                                       : captureMini ? QStringLiteral("--capture-mini")
                                                       : captureHidden ? QStringLiteral("--capture-hidden")
                                                                     : QStringLiteral("--capture-ui"));
    if (captureIndex >= 0 && captureIndex + 1 < arguments.size()) {
        const QString path = arguments.at(captureIndex + 1);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (captureIndex + 2 < arguments.size()) {
            auto *player = engine.rootObjects().first()->findChild<MpvItem *>(QStringLiteral("player"));
            if (player)
                player->openFile(QUrl::fromUserInput(arguments.at(captureIndex + 2)));
        }
        if (captureMini) {
            QTimer::singleShot(1600, &app, [root = engine.rootObjects().first()] {
                QMetaObject::invokeMethod(root, "toggleMiniPlayer");
            });
            if (captureRestored) {
                QTimer::singleShot(2500, &app, [root = engine.rootObjects().first()] {
                    QMetaObject::invokeMethod(root, "toggleMiniPlayer");
                });
            }
        }
        if (captureHidden) {
            QTimer::singleShot(1300, &app, [root = engine.rootObjects().first()] {
                QMetaObject::invokeMethod(root, "toggleTools");
            });
        }
        QTimer::singleShot(captureRestored ? 4200 : captureMini ? 3500 : 2100,
                           &app, [window, path, captureMini, captureRestored] {
            if (window) {
                const QImage frame = window->grabWindow();
                const bool correctMode = captureRestored ? window->width() >= 640 && frame.width() >= 640
                                                        : !captureMini || window->width() <= 500;
                if (!correctMode || !frame.save(path)) {
                    QCoreApplication::exit(2);
                    return;
                }
            }
            QCoreApplication::quit();
        });
    } else if (arguments.contains(QStringLiteral("--smoke-test"))) {
        QTimer::singleShot(1200, &app, &QCoreApplication::quit);
    } else if (arguments.size() > 1) {
        const QUrl url = QUrl::fromUserInput(arguments.at(1));
        auto *player = engine.rootObjects().first()->findChild<MpvItem *>(QStringLiteral("player"));
        if (player)
            player->openFile(url);
    }
    return app.exec();
}
