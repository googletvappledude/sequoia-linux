// Sequoia Dock: Qt Quick window pinned to the bottom edge via wlr-layer-shell (LayerShellQt).
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QRegion>
#include <LayerShellQt/Window>

// QML calls bridge.apply(...) on the GUI thread whenever the dock geometry changes.
class Bridge : public QObject
{
    Q_OBJECT
public:
    QQuickWindow *window = nullptr;
    LayerShellQt::Window *ls = nullptr;
    Q_INVOKABLE void apply(const QRect &clickable, int exclusiveZone)
    {
        if (!window || !ls)
            return;
        window->setMask(QRegion(clickable)); // everything outside is click-through
        ls->setExclusiveZone(exclusiveZone);
    }
};

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "wayland");
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("sequoia-dock"));
    app.setDesktopFileName(QStringLiteral("sequoia-dock"));

    Bridge bridge;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("bridge"), &bridge);
    engine.loadFromModule("SequoiaDock", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;
    auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!win)
        return 2;
    win->setColor(Qt::transparent);

    auto *ls = LayerShellQt::Window::get(win);
    ls->setScope(QStringLiteral("sequoia-dock"));
    ls->setLayer(LayerShellQt::Window::LayerTop);
    ls->setAnchors(LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorBottom));
    ls->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
    bridge.window = win;
    bridge.ls = ls;
    win->show();
    QMetaObject::invokeMethod(win, "pushGeometry"); // initial mask + exclusive zone
    return app.exec();
}

#include "main.moc"
