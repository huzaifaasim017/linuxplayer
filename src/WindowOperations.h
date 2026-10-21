// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QObject>
#include <QQuickWindow>

// Keep window-system operations out of QML; Wayland cannot move windows by x/y.
class WindowOperations : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;

    Q_INVOKABLE bool startMove(QQuickWindow *window) const
    {
        return window && window->startSystemMove();
    }

    Q_INVOKABLE bool startResize(QQuickWindow *window) const
    {
        return window && window->startSystemResize(Qt::RightEdge | Qt::BottomEdge);
    }
};
