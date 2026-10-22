// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

class DesktopIntegration : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool defaultVideoPlayer READ defaultVideoPlayer NOTIFY defaultVideoPlayerChanged)
    Q_PROPERTY(bool defaultStatusReady READ defaultStatusReady NOTIFY defaultStatusReadyChanged)
public:
    explicit DesktopIntegration(QObject *parent = nullptr);

    bool defaultVideoPlayer() const { return m_defaultVideoPlayer; }
    bool defaultStatusReady() const { return m_statusReady; }
    Q_INVOKABLE void refreshDefaultStatus();
    Q_INVOKABLE void setAsDefaultVideoPlayer();

signals:
    void defaultPlayerFinished(bool success, const QString &message);
    void defaultVideoPlayerChanged();
    void defaultStatusReadyChanged();

private:
    void advance();
    void processFinished(int exitCode, QProcess::ExitStatus status);
    void advanceStatus();
    void statusProcessFinished(int exitCode, QProcess::ExitStatus status);
    void setDefaultStatus(bool value);
    void finishStatus(bool value);

    QProcess m_process;
    QProcess m_statusProcess;
    QStringList m_mimeTypes;
    int m_index = 0;
    int m_failures = 0;
    bool m_verifying = false;
    bool m_running = false;
    int m_statusIndex = 0;
    bool m_statusRunning = false;
    bool m_statusRefreshPending = false;
    bool m_defaultVideoPlayer = false;
    bool m_statusReady = false;
};
