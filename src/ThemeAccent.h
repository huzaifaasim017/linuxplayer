// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QColor>
#include <QObject>
#include <QProcess>

class ThemeAccent : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QColor color READ color NOTIFY colorChanged)
public:
    explicit ThemeAccent(QObject *parent = nullptr);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    QColor color() const { return m_color; }
    Q_INVOKABLE void refresh();

signals:
    void enabledChanged();
    void colorChanged();

private:
    void queryGnomeAccent();
    void setColor(QColor color);
    void finish(QColor color);

    QProcess m_process;
    QColor m_color;
    bool m_enabled = false;
    bool m_running = false;
    bool m_pending = false;
    bool m_queryingGnomeAccent = false;
};
