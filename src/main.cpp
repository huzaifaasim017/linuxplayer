// SPDX-License-Identifier: GPL-3.0-or-later
#include "MpvItem.h"

#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
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
    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [] { QCoreApplication::exit(1); }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return 1;

    const QStringList arguments = app.arguments();
    const int captureIndex = arguments.indexOf(QStringLiteral("--capture-ui"));
    if (captureIndex >= 0 && captureIndex + 1 < arguments.size()) {
        const QString path = arguments.at(captureIndex + 1);
        auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (captureIndex + 2 < arguments.size()) {
            auto *player = engine.rootObjects().first()->findChild<MpvItem *>(QStringLiteral("player"));
            if (player)
                player->openFile(QUrl::fromUserInput(arguments.at(captureIndex + 2)));
        }
        QTimer::singleShot(3000, &app, [window, path] {
            if (window)
                window->grabWindow().save(path);
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
