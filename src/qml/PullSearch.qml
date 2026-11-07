import QtQuick 1.1
import com.nokia.meego 1.0

// Search field opened by pulling a list down at its top, the MeeGo Touch
// way (MListFilter, as in exNote). Put it above the list and give it the
// list; the page filters again in onQueryChanged.
//
// Opening: the field takes the gap the pull opened at once (no jump of
// the list) and its content fades in rising from the bottom. Closing:
// the content fades out, then the space closes and the list glides up.
// An empty field closes by itself after 5 s without use.
Item {
    id: bar
    property variant list            // the ListView or Flickable below
    property bool searching: false
    property string query: ""        // the text, settled 400 ms after typing

    property bool animated: true
    height: searching ? 76 : 0
    clip: true
    Behavior on height {
        enabled: bar.animated
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    function open() {
        if (searching)
            return;
        closeAnim.stop();
        animated = false;
        searching = true;
        animated = true;
        openAnim.restart();
        search.forceActiveFocus();
        search.platformOpenSoftwareInputPanel();
        idle.restart();
    }
    function close() {
        if (!searching)
            return;
        idle.stop();
        search.platformCloseSoftwareInputPanel();
        openAnim.stop();
        closeAnim.restart();
    }
    function toggle() { searching ? close() : open(); }

    // wildcard pattern for JavaScript: * = any text, ? = one character,
    // found anywhere in the text, letter case ignored
    function regExp(pattern) {
        var p = pattern.replace(/^\s+|\s+$/g, "");
        if (p == "")
            return null;
        p = p.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
        return new RegExp(p, "i");
    }

    Item {
        id: searchContent
        width: parent.width
        height: 76
        Rectangle {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
            radius: 12
            color: "#0c0c0c"
            border.width: 1
            border.color: search.activeFocus ? Qt.lighter(appWindow.tintBorder, 1.6) : appWindow.tintBorder
        }
        Image {
            id: lens
            anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
            source: "image://theme/icon-m-common-search-inverse"
            opacity: 0.7
        }
        TextField {
            id: search
            anchors { left: lens.right; right: clearIcon.left; verticalCenter: parent.verticalCenter }
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            platformStyle: TextFieldStyle {
                background: ""; backgroundSelected: ""; backgroundDisabled: ""; backgroundError: ""
                textColor: "#ffffff"
                paddingLeft: 8
            }
            onTextChanged: { searchDelay.restart(); idle.restart(); }
            Keys.onReturnPressed: { searchDelay.stop(); bar.settle(); search.platformCloseSoftwareInputPanel(); }
        }
        // small cross inside the field, only when there is text
        Image {
            id: clearIcon
            anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
            source: "image://theme/icon-m-input-clear"
            visible: search.text != ""
            width: visible ? implicitWidth : 0
            MouseArea {
                anchors { fill: parent; margins: -12 }
                onClicked: { search.text = ""; search.forceActiveFocus(); }
            }
        }
    }
    function settle() { query = search.text; }
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: searchContent; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad }
        NumberAnimation { target: searchContent; property: "y"; from: 30; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: searchContent; property: "opacity"; to: 0; duration: 200 }
        ScriptAction { script: { search.text = ""; bar.searching = false; searchDelay.stop(); bar.settle(); } }
    }
    Timer {
        id: idle
        interval: 5000
        onTriggered: if (search.text == "") bar.close()
    }
    Timer { id: searchDelay; interval: 400; onTriggered: bar.settle() }

    // A pull that starts at the top of the list opens the field as soon as
    // it has gone far enough, while the finger is still down. The list
    // follows the finger at half speed past its top, so 50 px is already
    // a long pull.
    property real pullStart: 0
    property bool pulling: false
    Connections {
        target: bar.list
        onMovementStarted: {
            bar.pullStart = bar.list.contentY;
            bar.pulling = !bar.searching && bar.list.contentY <= 0;
            if (bar.searching)
                idle.restart();
        }
        onMovementEnded: bar.pulling = false
        onContentYChanged: {
            if (!bar.pulling)
                return;
            var distance = bar.pullStart - bar.list.contentY;
            if (distance >= 50) {
                bar.pulling = false;
                bar.open();
                bar.list.contentY += 76;
            } else if (distance < 0) {
                bar.pulling = false;          // wrong direction
            }
        }
    }
}
