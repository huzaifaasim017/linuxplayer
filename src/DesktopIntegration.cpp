// SPDX-License-Identifier: GPL-3.0-or-later
#include "DesktopIntegration.h"

#include <QFileInfo>
#include <QStandardPaths>
#include <QTimer>

namespace {
constexpr auto desktopId = "io.github.teamkrope.LinuxPlayer.desktop";
}

DesktopIntegration::DesktopIntegration(QObject *parent) : QObject(parent)
{
    m_mimeTypes = {QStringLiteral("video/mp4"), QStringLiteral("video/x-matroska"),
                   QStringLiteral("video/webm"), QStringLiteral("video/x-msvideo"),
                   QStringLiteral("video/quicktime"), QStringLiteral("video/mpeg"),
                   QStringLiteral("video/ogg"), QStringLiteral("video/x-flv"),
                   QStringLiteral("video/x-ms-wmv")};
    connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, &DesktopIntegration::processFinished);
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart && m_running) {
            m_running = false;
            emit defaultPlayerFinished(false, QStringLiteral("Could not start xdg-mime."));
        }
    });
}

void DesktopIntegration::setAsDefaultVideoPlayer()
{
    if (m_running)
        return;

    bool installed = false;
    for (const QString &dataPath : QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation)) {
        if (QFileInfo::exists(dataPath + QStringLiteral("/applications/") + QLatin1String(desktopId))) {
            installed = true;
            break;
        }
    }
    if (!installed) {
        emit defaultPlayerFinished(false, QStringLiteral("Install LinuxPlayer first to make it the default player."));
        return;
    }
    if (QStandardPaths::findExecutable(QStringLiteral("xdg-mime")).isEmpty()) {
        emit defaultPlayerFinished(false, QStringLiteral("xdg-mime is unavailable on this desktop."));
        return;
    }

    m_index = 0;
    m_failures = 0;
    m_verifying = false;
    m_running = true;
    advance();
}

void DesktopIntegration::advance()
{
    if (m_index == m_mimeTypes.size()) {
        m_running = false;
        emit defaultPlayerFinished(m_failures == 0,
            m_failures == 0 ? QStringLiteral("LinuxPlayer is now your default video player.")
                            : QStringLiteral("Could not set all video associations. Check desktop settings."));
        return;
    }
    m_process.start(QStringLiteral("xdg-mime"),
                    {QStringLiteral("default"), QLatin1String(desktopId), m_mimeTypes.at(m_index)});
}

void DesktopIntegration::processFinished(int exitCode, QProcess::ExitStatus status)
{
    if (!m_running)
        return;
    if (!m_verifying) {
        if (status != QProcess::NormalExit || exitCode != 0) {
            ++m_failures;
            ++m_index;
            QTimer::singleShot(0, this, &DesktopIntegration::advance);
            return;
        }
        m_verifying = true;
        QTimer::singleShot(0, this, [this] {
            m_process.start(QStringLiteral("xdg-mime"), {QStringLiteral("query"), QStringLiteral("default"), m_mimeTypes.at(m_index)});
        });
        return;
    }
    if (status != QProcess::NormalExit || exitCode != 0
        || QString::fromUtf8(m_process.readAllStandardOutput()).trimmed() != QLatin1String(desktopId))
        ++m_failures;
    m_verifying = false;
    ++m_index;
    QTimer::singleShot(0, this, &DesktopIntegration::advance);
}
