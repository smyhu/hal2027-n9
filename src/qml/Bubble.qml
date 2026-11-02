import QtQuick 1.1
import com.nokia.meego 1.0

// One message: user on the right (grey), HAL on the left (dark red).
Item {
    id: bubble
    property string role: "user"
    property string text: ""
    property bool streaming: false
    property real maxWidth: parent ? parent.width : 400
    signal pressAndHold

    width: maxWidth
    height: box.height + 8

    Rectangle {
        id: box
        width: Math.min(label.paintedWidth + 32, bubble.maxWidth - 40)
        height: label.paintedHeight + 24
        radius: 14
        anchors.right: bubble.role == "user" ? parent.right : undefined
        anchors.left: bubble.role == "user" ? undefined : parent.left
        color: bubble.role == "user" ? "#3a3a3c" : appWindow.tintFill
        border.color: bubble.role == "user" ? "#555558" : appWindow.tintBorder
        border.width: 1
        Text {
            id: label
            x: 16
            y: 12
            width: bubble.maxWidth - 40 - 32
            wrapMode: Text.Wrap
            textFormat: Text.RichText
            text: (bubble.role == "user" ? bubble.text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/\n/g, "<br>")
                                         : chat.toHtml(bubble.text)) + (bubble.streaming ? " <font color='#e0281e'>▍</font>" : "")
            color: "#f2f2f2"
            font.pixelSize: 24
        }
        MouseArea {
            anchors.fill: parent
            onPressAndHold: bubble.pressAndHold()
        }
    }
}
