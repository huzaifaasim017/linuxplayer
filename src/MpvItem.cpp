// SPDX-License-Identifier: GPL-3.0-or-later
#include "MpvItem.h"

#include <QMetaObject>
#include <QCryptographicHash>
#include <QOpenGLContext>
#include <QOpenGLFramebufferObject>
#include <QQuickWindow>
#include <QSettings>
#include <QVariantMap>

#include <mpv/client.h>
#include <mpv/render.h>
#include <mpv/render_gl.h>

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace {

void *getProcAddress(void *, const char *name)
{
    auto *context = QOpenGLContext::currentContext();
    return context ? reinterpret_cast<void *>(context->getProcAddress(name)) : nullptr;
}

QString nodeString(const mpv_node &node)
{
    return node.format == MPV_FORMAT_STRING && node.u.string
        ? QString::fromUtf8(node.u.string) : QString();
}

const mpv_node *mapValue(const mpv_node &node, const char *key)
{
    if (node.format != MPV_FORMAT_NODE_MAP || !node.u.list)
        return nullptr;
    for (int i = 0; i < node.u.list->num; ++i) {
        if (qstrcmp(node.u.list->keys[i], key) == 0)
            return &node.u.list->values[i];
    }
    return nullptr;
}

int nodeInt(const mpv_node *node)
{
    return node && node->format == MPV_FORMAT_INT64 ? int(node->u.int64) : 0;
}

} // namespace

class MpvRenderer final : public QQuickFramebufferObject::Renderer
{
public:
    explicit MpvRenderer(MpvItem *item) : m_item(item) {}

    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override
    {
        if (!m_item->m_renderContext) {
            mpv_opengl_init_params glParams{getProcAddress, nullptr};
            mpv_render_param params[] = {
                {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
                {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &glParams},
                {MPV_RENDER_PARAM_INVALID, nullptr},
            };
            if (mpv_render_context_create(&m_item->m_renderContext, m_item->m_mpv, params) < 0)
                throw std::runtime_error("Unable to initialize libmpv OpenGL renderer");
            mpv_render_context_set_update_callback(m_item->m_renderContext, MpvItem::redraw, m_item);
            m_item->m_renderReady.store(true);
            QMetaObject::invokeMethod(m_item, "playPending", Qt::QueuedConnection);
        }
        return new QOpenGLFramebufferObject(size);
    }

    void render() override
    {
        if (!m_item->m_renderContext)
            return;
        auto *fbo = framebufferObject();
        mpv_opengl_fbo mpvFbo{int(fbo->handle()), fbo->width(), fbo->height(), 0};
        int flipY = 0;
        mpv_render_param params[] = {
            {MPV_RENDER_PARAM_OPENGL_FBO, &mpvFbo},
            {MPV_RENDER_PARAM_FLIP_Y, &flipY},
            {MPV_RENDER_PARAM_INVALID, nullptr},
        };
        m_item->window()->beginExternalCommands();
        mpv_render_context_render(m_item->m_renderContext, params);
        m_item->window()->endExternalCommands();
    }

private:
    MpvItem *m_item;
};

MpvItem::MpvItem(QQuickItem *parent) : QQuickFramebufferObject(parent)
{
    m_mpv = mpv_create();
    if (!m_mpv)
        throw std::runtime_error("Unable to create libmpv instance");

    mpv_set_option_string(m_mpv, "vo", "libmpv");
    mpv_set_option_string(m_mpv, "keep-open", "yes");
    mpv_set_option_string(m_mpv, "idle", "yes");
    mpv_set_option_string(m_mpv, "hwdec", "auto-safe");
    if (mpv_initialize(m_mpv) < 0)
        throw std::runtime_error("Unable to initialize libmpv");

    mpv_observe_property(m_mpv, 1, "duration", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 2, "time-pos", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 3, "pause", MPV_FORMAT_FLAG);
    mpv_observe_property(m_mpv, 4, "volume", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 5, "speed", MPV_FORMAT_DOUBLE);
    mpv_observe_property(m_mpv, 6, "media-title", MPV_FORMAT_STRING);
    mpv_observe_property(m_mpv, 7, "track-list", MPV_FORMAT_NONE);
    mpv_observe_property(m_mpv, 8, "aid", MPV_FORMAT_NONE);
    mpv_observe_property(m_mpv, 9, "sid", MPV_FORMAT_NONE);
    mpv_set_wakeup_callback(m_mpv, wakeup, this);
    connect(this, &MpvItem::frameReady, this, &MpvItem::update, Qt::QueuedConnection);
    m_saveTimer.setInterval(5000);
    connect(&m_saveTimer, &QTimer::timeout, this, &MpvItem::savePosition);
    m_saveTimer.start();
}

MpvItem::~MpvItem()
{
    savePosition();
    mpv_set_wakeup_callback(m_mpv, nullptr, nullptr);
    if (m_renderContext) {
        mpv_render_context_set_update_callback(m_renderContext, nullptr, nullptr);
        mpv_render_context_free(m_renderContext);
    }
    mpv_terminate_destroy(m_mpv);
}

QQuickFramebufferObject::Renderer *MpvItem::createRenderer() const
{
    window()->setPersistentSceneGraph(true);
    return new MpvRenderer(const_cast<MpvItem *>(this));
}

void MpvItem::wakeup(void *context)
{
    auto *self = static_cast<MpvItem *>(context);
    QMetaObject::invokeMethod(self, "processEvents", Qt::QueuedConnection);
}

void MpvItem::redraw(void *context)
{
    auto *self = static_cast<MpvItem *>(context);
    emit self->frameReady();
}

void MpvItem::processEvents()
{
    while (true) {
        mpv_event *event = mpv_wait_event(m_mpv, 0);
        if (event->event_id == MPV_EVENT_NONE)
            break;
        if (event->event_id == MPV_EVENT_PROPERTY_CHANGE) {
            auto *property = static_cast<mpv_event_property *>(event->data);
            if (!property->data) {
                if (event->reply_userdata == 7) refreshTracks();
                if (event->reply_userdata == 8 || event->reply_userdata == 9) refreshTrackSelection();
                continue;
            }
            switch (event->reply_userdata) {
            case 1: m_duration = *static_cast<double *>(property->data); emit durationChanged(); break;
            case 2: m_position = *static_cast<double *>(property->data); emit positionChanged(); break;
            case 3: m_paused = *static_cast<int *>(property->data) != 0; emit pausedChanged(); break;
            case 4: m_volume = *static_cast<double *>(property->data); emit volumeChanged(); break;
            case 5: m_speed = *static_cast<double *>(property->data); emit speedChanged(); break;
            case 6: {
                const char *title = *static_cast<char **>(property->data);
                m_mediaTitle = title ? QString::fromUtf8(title) : QString();
                emit mediaTitleChanged();
                break;
            }
            case 7: refreshTracks(); break;
            case 8: case 9: refreshTrackSelection(); break;
            default: break;
            }
        } else if (event->event_id == MPV_EVENT_END_FILE) {
            auto *end = static_cast<mpv_event_end_file *>(event->data);
            if (end->reason == MPV_END_FILE_REASON_EOF) {
                QSettings settings;
                settings.remove(resumeKey());
                m_loaded = false;
            }
            if (end->reason == MPV_END_FILE_REASON_ERROR) {
                m_loaded = false;
                m_sourceUrl = QUrl();
                emit sourceUrlChanged();
                emit errorOccurred(QString::fromUtf8(mpv_error_string(end->error)));
            }
        } else if (event->event_id == MPV_EVENT_FILE_LOADED) {
            m_loaded = true;
            double fileDuration = 0;
            mpv_get_property(m_mpv, "duration", MPV_FORMAT_DOUBLE, &fileDuration);
            const double saved = QSettings().value(resumeKey(), 0).toDouble();
            if (saved >= 10 && fileDuration > 0 && saved < fileDuration - 15) {
                setPaused(true);
                emit resumeSuggested(saved);
            }
        }
    }
}

void MpvItem::refreshTracks()
{
    mpv_node root{};
    if (mpv_get_property(m_mpv, "track-list", MPV_FORMAT_NODE, &root) < 0)
        return;
    QVariantList audio;
    QVariantList subtitles;
    if (root.format == MPV_FORMAT_NODE_ARRAY && root.u.list) {
        for (int i = 0; i < root.u.list->num; ++i) {
            const mpv_node &track = root.u.list->values[i];
            const mpv_node *type = mapValue(track, "type");
            const mpv_node *id = mapValue(track, "id");
            const mpv_node *title = mapValue(track, "title");
            const mpv_node *language = mapValue(track, "lang");
            const QString typeName = type ? nodeString(*type) : QString();
            if (typeName != QStringLiteral("audio") && typeName != QStringLiteral("sub"))
                continue;
            const int trackId = nodeInt(id);
            const QString trackTitle = title ? nodeString(*title) : QString();
            const QString lang = language ? nodeString(*language) : QString();
            const QString label = trackTitle.isEmpty()
                ? (lang.isEmpty() ? QStringLiteral("Track %1").arg(trackId) : lang)
                : trackTitle;
            QVariantMap row{{QStringLiteral("id"), trackId}, {QStringLiteral("title"), label}};
            (typeName == QStringLiteral("audio") ? audio : subtitles).append(row);
        }
    }
    mpv_free_node_contents(&root);
    m_audioTracks = audio;
    m_subtitleTracks = subtitles;
    refreshTrackSelection();
    emit tracksChanged();
}

void MpvItem::refreshTrackSelection()
{
    int64_t aid = 0;
    int64_t sid = 0;
    mpv_get_property(m_mpv, "aid", MPV_FORMAT_INT64, &aid);
    mpv_get_property(m_mpv, "sid", MPV_FORMAT_INT64, &sid);
    m_audioTrackId = int(aid);
    m_subtitleTrackId = int(sid);
    emit tracksChanged();
}

void MpvItem::openFile(const QUrl &url)
{
    if (!url.isLocalFile()) {
        emit errorOccurred(QStringLiteral("Choose a video file from your computer."));
        return;
    }
    // mpv requires its render context before the first loadfile command.
    if (!m_renderReady.load()) {
        m_pendingUrl = url;
        m_sourceUrl = url;
        emit sourceUrlChanged();
        update();
        return;
    }
    savePosition();
    m_loaded = false;
    m_currentPath = url.toLocalFile();
    m_duration = 0;
    m_position = 0;
    emit durationChanged();
    emit positionChanged();
    const QByteArray path = url.toLocalFile().toUtf8();
    const char *args[] = {"loadfile", path.constData(), "replace", nullptr};
    const int result = mpv_command(m_mpv, args);
    if (result < 0) {
        m_sourceUrl = QUrl();
        emit sourceUrlChanged();
        emit errorOccurred(QString::fromUtf8(mpv_error_string(result)));
        return;
    }
    if (m_sourceUrl != url) {
        m_sourceUrl = url;
        emit sourceUrlChanged();
    }
}

QString MpvItem::resumeKey() const
{
    const QByteArray digest = QCryptographicHash::hash(m_currentPath.toUtf8(), QCryptographicHash::Sha256).toHex();
    return QStringLiteral("resume/") + QString::fromLatin1(digest);
}

void MpvItem::savePosition()
{
    if (!m_loaded || m_currentPath.isEmpty() || m_duration <= 0)
        return;
    QSettings settings;
    if (m_position >= 10 && m_position < m_duration - 15)
        settings.setValue(resumeKey(), m_position);
    else if (m_position >= m_duration - 15)
        settings.remove(resumeKey());
}

void MpvItem::playPending()
{
    if (m_pendingUrl.isEmpty()) return;
    const QUrl url = m_pendingUrl;
    m_pendingUrl = QUrl();
    openFile(url);
}

void MpvItem::seek(double seconds)
{
    if (!std::isfinite(seconds) || seconds < 0)
        return;
    const QByteArray value = QByteArray::number(seconds, 'f', 3);
    const char *args[] = {"seek", value.constData(), "absolute", nullptr};
    mpv_command(m_mpv, args);
}

void MpvItem::togglePause()
{
    setPaused(!m_paused);
}

void MpvItem::loadSubtitle(const QUrl &url)
{
    if (!url.isLocalFile()) {
        emit errorOccurred(QStringLiteral("Choose a subtitle file from your computer."));
        return;
    }
    const QByteArray path = url.toLocalFile().toUtf8();
    const char *args[] = {"sub-add", path.constData(), "select", nullptr};
    const int result = mpv_command(m_mpv, args);
    if (result < 0)
        emit errorOccurred(QString::fromUtf8(mpv_error_string(result)));
}

void MpvItem::setPaused(bool paused)
{
    int flag = paused ? 1 : 0;
    mpv_set_property(m_mpv, "pause", MPV_FORMAT_FLAG, &flag);
}

void MpvItem::setVolume(double volume)
{
    if (!std::isfinite(volume)) return;
    volume = std::clamp(volume, 0.0, 100.0);
    mpv_set_property(m_mpv, "volume", MPV_FORMAT_DOUBLE, &volume);
}

void MpvItem::setSpeed(double speed)
{
    if (!std::isfinite(speed)) return;
    speed = std::clamp(speed, 0.25, 3.0);
    mpv_set_property(m_mpv, "speed", MPV_FORMAT_DOUBLE, &speed);
}

void MpvItem::setAudioTrackId(int id)
{
    int64_t value = id;
    mpv_set_property(m_mpv, "aid", MPV_FORMAT_INT64, &value);
}

void MpvItem::setSubtitleTrackId(int id)
{
    if (id <= 0) {
        mpv_set_property_string(m_mpv, "sid", "no");
        return;
    }
    int64_t value = id;
    mpv_set_property(m_mpv, "sid", MPV_FORMAT_INT64, &value);
}
