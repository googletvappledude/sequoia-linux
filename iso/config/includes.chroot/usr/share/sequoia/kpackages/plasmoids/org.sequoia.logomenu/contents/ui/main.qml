import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source) => disconnectSource(source)
        function run(cmd) { root.expanded = false; connectSource(cmd) }
    }

    // logo.svg, the single shared asset, tinted with the panel text colour
    compactRepresentation: MouseArea {
        id: area
        Layout.minimumWidth: Kirigami.Units.gridUnit * 2
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 5
                    color: area.containsMouse || root.expanded ? Qt.rgba(0, 0, 0, 0.12) : "transparent" }
        Kirigami.Icon {
            anchors.centerIn: parent
            height: parent.height * 0.62; width: height
            source: "file:///usr/share/sequoia/logo.svg"
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    fullRepresentation: ColumnLayout {
        id: menu
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        spacing: 0
        component Item_ : QQC2.ItemDelegate {
            property string cmd
            Layout.fillWidth: true
            onClicked: exec.run(cmd)
        }
        component Sep : Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: 3; Layout.bottomMargin: 3 }
        Item_ { text: "About This Computer";   cmd: "kinfocenter" }
        Sep {}
        Item_ { text: "System Settings…";      cmd: "systemsettings" }
        Item_ { text: "Software Manager…";     cmd: "plasma-discover" }
        Sep {}
        Item_ { text: "Force Quit…";           cmd: "qdbus6 org.kde.KWin /KWin org.kde.KWin.killWindow" }
        Sep {}
        Item_ { text: "Sleep";                 cmd: "systemctl suspend" }
        Item_ { text: "Restart…";              cmd: "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptReboot" }
        Item_ { text: "Shut Down…";            cmd: "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptShutDown" }
        Sep {}
        Item_ { text: "Lock Screen";           cmd: "loginctl lock-session" }
        Item_ { text: "Log Out…";              cmd: "qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout" }
    }
}
