import QtQuick 1.1
import com.nokia.meego 1.0

// Page title bar: dark red gradient like the eye.
Rectangle {
    property string title: ""
    width: parent.width
    height: 72
    gradient: Gradient {
        GradientStop { position: 0.0; color: appWindow.tintHeader }
        GradientStop { position: 1.0; color: "#000000" }
    }
    Label {
        text: parent.title
        color: "white"
        font.pixelSize: 32
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
    }
}
