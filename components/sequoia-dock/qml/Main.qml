import QtQuick
import QtQuick.Window
import org.kde.taskmanager as TaskManager

Window {
    id: win
    // --- user-facing settings (Settings app will write ~/.config/sequoia/dock.conf later) ---
    property int  baseSize: 52
    property real maxZoom: 1.7
    property bool autoHide: false
    // --- geometry ---
    readonly property int pad: 8
    readonly property int headroom: Math.round(baseSize * (maxZoom - 1)) + 24
    width: Math.max(dock.width + 32, 120)
    height: baseSize + pad * 2 + headroom + 12
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

    property bool hovering: hover.containsMouse
    readonly property int shelfH: baseSize + pad * 2 + 6
    // Clickable region: shelf (+ zoom headroom while hovering). When auto-hidden, only a 3px reveal strip.
    property rect dockRect: (autoHide && !hovering) ? Qt.rect(0, height - 3, width, 3)
                          : Qt.rect(dock.x, height - shelfH - (hovering ? headroom : 0), dock.width, shelfH + (hovering ? headroom : 0))
    property int exclusiveZone: autoHide ? 0 : shelfH + 6
    function pushGeometry() { bridge.apply(dockRect, exclusiveZone) }
    onDockRectChanged: pushGeometry()
    onExclusiveZoneChanged: pushGeometry()

    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupApplications
        groupInline: false
        sortMode: TaskManager.TasksModel.SortManual
        launchInPlace: true
        separateLaunchers: false
        launcherList: ["applications:org.kde.dolphin.desktop", "applications:systemsettings.desktop",
                       "applications:org.kde.plasma-systemmonitor.desktop", "applications:org.kde.konsole.desktop",
                       "applications:org.kde.kate.desktop", "applications:org.kde.discover.desktop"]
    }

    Rectangle {                      // floating translucent Dock shelf
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: win.autoHide && !win.hovering ? -(height + 20) : 6
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        height: win.baseSize + win.pad * 2
        width: row.width + win.pad * 2
        radius: 20
        color: "#66F2F2F2"
        border.color: "#80FFFFFF"; border.width: 1
        Behavior on width { NumberAnimation { duration: 120 } }

        MouseArea {
            id: hover
            anchors.fill: parent; anchors.margins: -6
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
        }
        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: win.pad
            spacing: 4
            Repeater {
                model: tasks
                DockItem {
                    baseSize: win.baseSize
                    maxZoom: win.maxZoom
                    mouseX: hover.containsMouse ? hover.mouseX - 6 - row.x : -10000
                    tasksModel: tasks
                }
            }
        }
    }
}
