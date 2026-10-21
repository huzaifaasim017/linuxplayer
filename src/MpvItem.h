// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <QQuickFramebufferObject>
#include <QUrl>
#include <QVariantList>
#include <QTimer>
#include <atomic>

struct mpv_handle;
struct mpv_render_context;

class MpvItem : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl sourceUrl READ sourceUrl NOTIFY sourceUrlChanged)
    Q_PROPERTY(double duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(double position READ position NOTIFY positionChanged)
    Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(bool ended READ ended NOTIFY endedChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool buffering READ buffering NOTIFY bufferingChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(double speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaTitleChanged)
    Q_PROPERTY(QVariantList audioTracks READ audioTracks NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList subtitleTracks READ subtitleTracks NOTIFY tracksChanged)
    Q_PROPERTY(int audioTrackId READ audioTrackId WRITE setAudioTrackId NOTIFY tracksChanged)
    Q_PROPERTY(int subtitleTrackId READ subtitleTrackId WRITE setSubtitleTrackId NOTIFY tracksChanged)
    Q_PROPERTY(bool looping READ looping WRITE setLooping NOTIFY loopingChanged)
    Q_PROPERTY(bool videoFill READ videoFill WRITE setVideoFill NOTIFY videoFillChanged)

public:
    explicit MpvItem(QQuickItem *parent = nullptr);
    ~MpvItem() override;

    Renderer *createRenderer() const override;
    QUrl sourceUrl() const { return m_sourceUrl; }
    double duration() const { return m_duration; }
    double position() const { return m_position; }
    bool paused() const { return m_paused; }
    bool ended() const { return m_ended; }
    bool loading() const { return m_loading; }
    bool buffering() const { return m_buffering; }
    double volume() const { return m_volume; }
    double speed() const { return m_speed; }
    QString mediaTitle() const { return m_mediaTitle; }
    QVariantList audioTracks() const { return m_audioTracks; }
    QVariantList subtitleTracks() const { return m_subtitleTracks; }
    int audioTrackId() const { return m_audioTrackId; }
    int subtitleTrackId() const { return m_subtitleTrackId; }
    bool looping() const { return m_looping; }
    bool videoFill() const { return m_videoFill; }

    Q_INVOKABLE void openFile(const QUrl &url);
    Q_INVOKABLE void seek(double seconds);
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void loadSubtitle(const QUrl &url);
    Q_INVOKABLE void saveScreenshot(const QUrl &url);
    void setPaused(bool paused);
    void setVolume(double volume);
    void setSpeed(double speed);
    void setAudioTrackId(int id);
    void setSubtitleTrackId(int id);
    void setLooping(bool looping);
    void setVideoFill(bool fill);

signals:
    void sourceUrlChanged();
    void durationChanged();
    void positionChanged();
    void pausedChanged();
    void endedChanged();
    void loadingChanged();
    void bufferingChanged();
    void volumeChanged();
    void speedChanged();
    void mediaTitleChanged();
    void tracksChanged();
    void loopingChanged();
    void videoFillChanged();
    void errorOccurred(const QString &message);
    void resumeSuggested(double seconds);
    void frameReady();

private slots:
    void processEvents();
    void playPending();

private:
    friend class MpvRenderer;
    static void wakeup(void *context);
    static void redraw(void *context);
    void refreshTracks();
    void refreshTrackSelection();
    void savePosition();
    QString resumeKey() const;

    mpv_handle *m_mpv = nullptr;
    mpv_render_context *m_renderContext = nullptr;
    std::atomic<bool> m_renderReady{false};
    QUrl m_pendingUrl;
    QString m_currentPath;
    QTimer m_saveTimer;
    bool m_loaded = false;
    QUrl m_sourceUrl;
    double m_duration = 0;
    double m_position = 0;
    bool m_paused = true;
    bool m_ended = false;
    bool m_loading = false;
    bool m_buffering = false;
    double m_volume = 100;
    double m_speed = 1;
    QString m_mediaTitle;
    QVariantList m_audioTracks;
    QVariantList m_subtitleTracks;
    int m_audioTrackId = 0;
    int m_subtitleTrackId = 0;
    bool m_looping = false;
    bool m_videoFill = false;
};
