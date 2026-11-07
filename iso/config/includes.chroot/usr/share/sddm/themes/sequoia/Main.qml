import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1280; height: 720
    color: "#000000"
    readonly property string fontFamily: "SF Pro Display"
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Image {
        anchors.fill: parent
        source: "file:///usr/share/sequoia/wallpaper-still.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: "#33000000" }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.10
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd, MMMM d")
            color: "white"; font.family: root.fontFamily; font.pixelSize: root.height * 0.032; font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "h:mm")
            color: "white"; font.family: root.fontFamily; font.pixelSize: root.height * 0.15; font.weight: Font.DemiBold
        }
    }

    // Login block
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.12
        spacing: 12
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1) || ""
            color: "white"; font.family: root.fontFamily; font.pixelSize: 17; font.weight: Font.DemiBold
        }
        TextField {
            id: pw
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240; Layout.preferredHeight: 32
            echoMode: TextInput.Password
            placeholderText: "Enter Password"
            color: "white"; placeholderTextColor: "#B3FFFFFF"
            font.pixelSize: 13; font.family: "SF Pro Text"
            horizontalAlignment: TextInput.AlignHCenter
            focus: true
            background: Rectangle { radius: 16; color: "#40FFFFFF"; border.color: "#59FFFFFF" }
            onAccepted: sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), Qt.UserRole + 1),
                                   text, sessionModel.lastIndex)
            SequentialAnimation on x { id: shake; running: false
                NumberAnimation { to: -10; duration: 40 } NumberAnimation { to: 10; duration: 80 } NumberAnimation { to: 0; duration: 40 } }
        }
        Text { id: msg; Layout.alignment: Qt.AlignHCenter; color: "#FFFFFF"; opacity: 0.8; font.pixelSize: 12; text: "" }
    }
    Connections {
        target: sddm
        function onLoginFailed() { pw.text = ""; msg.text = "Incorrect password"; shake.start() }
    }

    Row {
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 14
        Text { text: "Restart"; color: "white"; font.pixelSize: 12; visible: sddm.canReboot
               MouseArea { anchors.fill: parent; onClicked: sddm.reboot() } }
        Text { text: "Shut Down"; color: "white"; font.pixelSize: 12; visible: sddm.canPowerOff
               MouseArea { anchors.fill: parent; onClicked: sddm.powerOff() } }
    }
    Component.onCompleted: pw.forceActiveFocus()
}
