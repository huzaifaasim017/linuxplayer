// SPDX-License-Identifier: GPL-3.0-or-later
#include "ThemeAccent.h"

#include <QGuiApplication>
#include <QPalette>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>

#include <cmath>

namespace {
QColor contrastSafe(QColor color)
{
    if (!color.isValid())
        color = QColor(QStringLiteral("#64d5c6"));
    // Keep user-selected hues readable against the dark controls.
    const auto linear = [](double channel) {
        return channel <= 0.04045 ? channel / 12.92 : std::pow((channel + 0.055) / 1.055, 2.4);
    };
    const auto luminance = [&](const QColor &sample) {
        return 0.2126 * linear(sample.redF())
             + 0.7152 * linear(sample.greenF())
             + 0.0722 * linear(sample.blueF());
    };
    const double background = luminance(QColor(QStringLiteral("#152b36")));
    for (int i = 0; i < 16 && (luminance(color) + 0.05) / (background + 0.05) < 4.5; ++i)
        color = color.lighter(112);
    return color;
}

QColor yaruColor(const QString &theme)
{
    const QString name = theme.trimmed().remove(QLatin1Char('\''));
    if (!name.startsWith(QLatin1String("Yaru"), Qt::CaseInsensitive))
        return {};
    QString variant = name.mid(4).toLower();
    if (variant.endsWith(QLatin1String("-dark")))
        variant.chop(5);
    if (variant.startsWith(QLatin1Char('-')))
        variant.remove(0, 1);
    if (variant.isEmpty() || variant == QLatin1String("light")) return QColor(QStringLiteral("#e95420"));
    if (variant == QLatin1String("bark")) return QColor(QStringLiteral("#787859"));
    if (variant == QLatin1String("sage")) return QColor(QStringLiteral("#657b69"));
    if (variant == QLatin1String("olive")) return QColor(QStringLiteral("#4b8501"));
    if (variant == QLatin1String("viridian")) return QColor(QStringLiteral("#03875b"));
    if (variant == QLatin1String("prussiangreen")) return QColor(QStringLiteral("#308280"));
    if (variant == QLatin1String("blue")) return QColor(QStringLiteral("#0073e5"));
    if (variant == QLatin1String("purple")) return QColor(QStringLiteral("#7764d8"));
    if (variant == QLatin1String("magenta")) return QColor(QStringLiteral("#b34cb3"));
    if (variant == QLatin1String("mate")) return QColor(QStringLiteral("#87a556"));
    if (variant == QLatin1String("red")) return QColor(QStringLiteral("#da3450"));
    if (variant == QLatin1String("yellow")) return QColor(QStringLiteral("#c88800"));
    if (variant == QLatin1String("wartybrown")) return QColor(QStringLiteral("#b39169"));
    return {};
}

QColor gnomeColor(const QString &value)
{
    const QString name = value.trimmed().remove(QLatin1Char('\''));
    if (name == QLatin1String("blue")) return QColor(QStringLiteral("#3584e4"));
    if (name == QLatin1String("teal")) return QColor(QStringLiteral("#2190a4"));
    if (name == QLatin1String("green")) return QColor(QStringLiteral("#3a944a"));
    if (name == QLatin1String("yellow")) return QColor(QStringLiteral("#c88800"));
    if (name == QLatin1String("orange")) return QColor(QStringLiteral("#ed5b00"));
    if (name == QLatin1String("red")) return QColor(QStringLiteral("#e62d42"));
    if (name == QLatin1String("pink")) return QColor(QStringLiteral("#d56199"));
    if (name == QLatin1String("purple")) return QColor(QStringLiteral("#9141ac"));
    if (name == QLatin1String("slate")) return QColor(QStringLiteral("#6f8396"));
    return {};
}
}

ThemeAccent::ThemeAccent(QObject *parent) : QObject(parent),
    m_color(contrastSafe(QGuiApplication::palette().color(QPalette::Highlight))),
    m_enabled(QSettings().value(QStringLiteral("theme/useSystemAccent"), false).toBool())
{
    connect(&m_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int exitCode, QProcess::ExitStatus status) {
        const QString value = QString::fromUtf8(m_process.readAllStandardOutput());
        if (!m_queryingGnomeAccent) {
            const QColor yaru = status == QProcess::NormalExit && exitCode == 0 ? yaruColor(value) : QColor();
            if (yaru.isValid()) finish(yaru);
            else queryGnomeAccent();
            return;
        }
        const QColor gnome = status == QProcess::NormalExit && exitCode == 0 ? gnomeColor(value) : QColor();
        finish(gnome.isValid() ? gnome : QGuiApplication::palette().color(QPalette::Highlight));
    });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart || !m_running) return;
        if (m_queryingGnomeAccent) finish(QGuiApplication::palette().color(QPalette::Highlight));
        else queryGnomeAccent();
    });
    connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
        if (state == Qt::ApplicationActive && m_enabled) refresh();
    });
    QTimer::singleShot(0, this, &ThemeAccent::refresh);
}

void ThemeAccent::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    QSettings().setValue(QStringLiteral("theme/useSystemAccent"), enabled);
    emit enabledChanged();
    if (enabled) refresh();
}

void ThemeAccent::setColor(QColor color)
{
    color = contrastSafe(color);
    if (m_color == color) return;
    m_color = color;
    emit colorChanged();
}

void ThemeAccent::finish(QColor color)
{
    m_running = false;
    setColor(color);
    if (m_pending) {
        m_pending = false;
        QTimer::singleShot(0, this, &ThemeAccent::refresh);
    }
}

void ThemeAccent::refresh()
{
    if (m_running) {
        m_pending = true;
        return;
    }
    if (QStandardPaths::findExecutable(QStringLiteral("gsettings")).isEmpty()) {
        setColor(QGuiApplication::palette().color(QPalette::Highlight));
        return;
    }
    m_running = true;
    m_queryingGnomeAccent = false;
    m_process.start(QStringLiteral("gsettings"),
                    {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("gtk-theme")});
}

void ThemeAccent::queryGnomeAccent()
{
    m_queryingGnomeAccent = true;
    m_process.start(QStringLiteral("gsettings"),
                    {QStringLiteral("get"), QStringLiteral("org.gnome.desktop.interface"), QStringLiteral("accent-color")});
}
