// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

class DesktopIntegration : public QObject
{
    Q_OBJECT
public:
    explicit DesktopIntegration(QObject *parent = nullptr);

    Q_INVOKABLE void setAsDefaultVideoPlayer();

signals:
    void defaultPlayerFinished(bool success, const QString &message);

private:
    void advance();
    void processFinished(int exitCode, QProcess::ExitStatus status);

    QProcess m_process;
    QStringList m_mimeTypes;
    int m_index = 0;
    int m_failures = 0;
    bool m_verifying = false;
    bool m_running = false;
};
