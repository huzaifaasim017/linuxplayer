// SPDX-License-Identifier: GPL-3.0-or-later
#include "DesktopIntegration.h"

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QTemporaryDir>
#include <QTimer>

int main(int argc, char **argv)
{
    QTemporaryDir temporary;
    if (!temporary.isValid())
        return 1;
    const QString data = temporary.path() + QStringLiteral("/data");
    const QString config = temporary.path() + QStringLiteral("/config");
    const QString bin = temporary.path() + QStringLiteral("/bin");
    QDir().mkpath(data + QStringLiteral("/applications"));
    QDir().mkpath(config);
    QDir().mkpath(bin);
    qputenv("XDG_DATA_HOME", data.toUtf8());
    qputenv("XDG_DATA_DIRS", data.toUtf8());
    qputenv("XDG_CONFIG_HOME", config.toUtf8());
    qputenv("PATH", (bin + QStringLiteral(":") + QString::fromLocal8Bit(qgetenv("PATH"))).toUtf8());

    const QString desktopPath = data + QStringLiteral("/applications/io.github.teamkrope.LinuxPlayer.desktop");
    QFile desktop(desktopPath);
    if (!desktop.open(QIODevice::WriteOnly) || desktop.write("[Desktop Entry]\nType=Application\nName=LinuxPlayer\nExec=linuxplayer %f\nMimeType=video/mp4;\n") < 0)
        return 2;
    desktop.close();

    QFile xdg(bin + QStringLiteral("/xdg-mime"));
    if (!xdg.open(QIODevice::WriteOnly))
        return 3;
    xdg.write("#!/bin/sh\n"
              "if [ \"$1\" = default ]; then mkdir -p \"$XDG_CONFIG_HOME/$(dirname \"$3\")\"; printf '%s\\n' \"$2\" > \"$XDG_CONFIG_HOME/$3\"; exit $?; fi\n"
              "if [ \"$1\" = query ] && [ \"$2\" = default ]; then cat \"$XDG_CONFIG_HOME/$3\"; exit $?; fi\n"
              "exit 1\n");
    xdg.close();
    xdg.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);

    QCoreApplication app(argc, argv);
    DesktopIntegration integration;
    QEventLoop loop;
    bool success = false;
    QObject::connect(&integration, &DesktopIntegration::defaultPlayerFinished, &loop,
                     [&](bool ok, const QString &message) { qInfo() << "desktop integration:" << ok << message; success = ok; loop.quit(); });
    QTimer::singleShot(10000, &loop, &QEventLoop::quit);
    integration.setAsDefaultVideoPlayer();
    loop.exec();
    if (!success || !QFile::exists(config + QStringLiteral("/video/mp4")))
        return 4;

    QFile::remove(desktopPath);
    success = true;
    integration.setAsDefaultVideoPlayer();
    return success ? 5 : 0;
}
