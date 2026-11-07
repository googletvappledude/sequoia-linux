import QtQuick
import QtQuick.Controls
import org.kde.taskmanager as TaskManager

Item {
    id: item
    required property var model
    required property int index
    property int baseSize: 52
    property real maxZoom: 1.7
    property real mouseX: -10000
    property var tasksModel

    // Gaussian magnification around the pointer
    readonly property real centerX: x + width / 2
    readonly property real dist: Math.abs(mouseX - centerX)
    readonly property real zoom: mouseX < -5000 ? 1.0 : 1.0 + (maxZoom - 1.0) * Math.exp(-(dist * dist) / (2 * 60 * 60))
    readonly property bool running: model.IsWindow === true
    readonly property bool active: model.IsActive === true

    width: baseSize * zoom
    height: baseSize
    Behavior on zoom { enabled: mouseX < -5000; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Image {
        id: icon
        width: parent.width; height: width
        anchors.bottom: parent.bottom
        source: "image://icon/" + (model.decoration ? model.decoration : "application-x-executable")
        sourceSize: Qt.size(256, 256)
        smooth: true; mipmap: true
    }
    SequentialAnimation {   // launch bounce
        id: bounce
        NumberAnimation { target: icon; property: "anchors.bottomMargin"; to: 18; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: icon; property: "anchors.bottomMargin"; to: 0;  duration: 160; easing.type: Easing.InQuad }
    }
    Rectangle {             // running indicator
        visible: item.running
        width: 4; height: 4; radius: 2; color: "#262626"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom; anchors.topMargin: 0
    }
    ToolTip { visible: ma.containsMouse && !menu.visible; text: model.display || ""; delay: 300 }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (m) => {
            const mi = tasksModel.makeModelIndex(index);
            if (m.button === Qt.RightButton) { menu.popup(); return; }
            if (!item.running) { bounce.start(); tasksModel.requestNewInstance(mi); }
            else if (item.active) tasksModel.requestToggleMinimized(mi);   // minimise active window
            else tasksModel.requestActivate(mi);                           // restore / focus
        }
    }
    Menu {
        id: menu
        popupType: Popup.Window
        MenuItem { text: item.running ? "Show" : "Open"; onTriggered: item.running ? tasksModel.requestActivate(tasksModel.makeModelIndex(index)) : tasksModel.requestNewInstance(tasksModel.makeModelIndex(index)) }
        MenuItem { text: "New Window"; visible: item.running; height: visible ? implicitHeight : 0; onTriggered: tasksModel.requestNewInstance(tasksModel.makeModelIndex(index)) }
        MenuSeparator {}
        MenuItem { text: model.IsLauncher ? "Remove from Dock" : "Keep in Dock"
                   onTriggered: model.IsLauncher ? tasksModel.requestRemoveLauncher(model.LauncherUrlWithoutIcon)
                                                 : tasksModel.requestAddLauncher(model.LauncherUrlWithoutIcon) }
        MenuSeparator {}
        MenuItem { text: "Quit"; enabled: item.running; onTriggered: tasksModel.requestClose(tasksModel.makeModelIndex(index)) }
    }
}
