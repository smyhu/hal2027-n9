import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S

// The service's model list. Pull the list down to search:
// * = any text, ? = one character (e.g. "free" or "gemini*flash").
Page {
    id: page
    orientationLock: PageOrientation.LockPortrait
    property variant models: []
    property string current: ""
    signal picked(string name)

    function fill() {
        names.clear();
        var rx = searchBar.searching ? searchBar.regExp(searchBar.query) : null;
        for (var i = 0; i < models.length; ++i)
            if (!rx || rx.test(models[i]))
                names.append({ "name": models[i] });
    }
    Component.onCompleted: {
        fill();
        for (var i = 0; i < names.count; ++i)
            if (names.get(i).name == current) {
                list.positionViewAtIndex(i, ListView.Center);
                break;
            }
    }

    ListModel { id: names }
    Image { source: "img/background.png"; y: -36; smooth: false }
    Header { id: header; title: S.t(uiLang, "modelPick") }

    PullSearch {
        id: searchBar
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        list: list
        onQueryChanged: page.fill()
        onSearchingChanged: if (!searching) page.fill()
    }

    ListView {
        id: list
        anchors { top: searchBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: names
        delegate: Item {
            width: list.width
            height: 80
            Rectangle {
                anchors.fill: parent
                color: "#ffffff"
                opacity: mouse.pressed ? 0.12 : 0
            }
            Label {
                anchors { left: parent.left; right: tick.left; leftMargin: 16; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: model.name
                elide: Text.ElideMiddle
                font.pixelSize: 24
                color: model.name == page.current ? appWindow.accent : "white"
            }
            Image {
                id: tick
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                source: "image://theme/icon-m-toolbar-done-white"
                visible: model.name == page.current
                width: visible ? implicitWidth : 0
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                onClicked: { page.picked(model.name); pageStack.pop(); }
            }
        }
    }
    ScrollDecorator { flickableItem: list }

    Label {
        anchors.centerIn: parent
        visible: names.count == 0
        text: S.t(uiLang, "noResults")
        color: "#a0a0a0"
    }

    tools: ToolBarLayout {
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ToolIcon { iconId: "toolbar-search"; onClicked: searchBar.toggle() }
    }
}
