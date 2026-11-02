import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S

// All saved conversations, laid out like the N9 Messages list: the first
// question (two lines), date | time | service, and the white service
// mark. Tap opens it on the main screen, hold for save / delete.
Page {
    id: page
    orientationLock: PageOrientation.LockPortrait
    property int selected: 0

    function reload() {
        var n = {};
        var provs = JSON.parse(store.providers());
        for (var k = 0; k < provs.length; ++k)
            n[provs[k].id] = provs[k].short || provs[k].name;
        model.clear();
        var rows = JSON.parse(history.list());
        for (var i = 0; i < rows.length; ++i) {
            var d = new Date(rows[i].updated * 1000);
            model.append({ "cid": rows[i].id, "title": rows[i].title,
                           "pid": rows[i].provider,
                           "info": Qt.formatDateTime(d, "dd.MM.yyyy | hh:mm") + " | " + (n[rows[i].provider] || rows[i].provider) });
        }
    }
    Component.onCompleted: reload()

    Image { source: "img/tlo.png"; y: -36; smooth: false }
    ListModel { id: model }
    Header { id: header; title: S.t(uiLang, "history") }

    ListView {
        id: list
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: model
        delegate: Item {
            width: list.width
            height: 112
            Rectangle {
                anchors.fill: parent
                color: "#ffffff"
                opacity: mouse.pressed ? 0.12 : 0
            }
            Column {
                anchors { left: parent.left; right: icon.left; leftMargin: 16; rightMargin: 14; verticalCenter: parent.verticalCenter }
                Label {
                    width: parent.width
                    text: model.title
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font.pixelSize: 24
                    color: "white"
                }
                Label {
                    text: model.info
                    font.pixelSize: 20
                    color: "#a0a0a0"
                }
            }
            // white mark of the service
            Image {
                id: icon
                width: 64
                height: 64
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                smooth: true
                source: "img/usluga-" + model.pid + ".png"
                // a service added in the config file has no mark of its own
                onStatusChanged: if (status == Image.Error) source = "image://theme/icon-m-toolbar-new-chat-white"
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                onClicked: { appWindow.openConversation(model.cid); pageStack.pop(); }
                onPressAndHold: { page.selected = model.cid; menu.open(); }
            }
        }
    }
    ScrollDecorator { flickableItem: list }

    Label {
        anchors.centerIn: parent
        visible: model.count == 0
        text: S.t(uiLang, "noHistory")
        color: "#a0a0a0"
    }

    ContextMenu {
        id: menu
        MenuLayout {
            MenuItem {
                text: S.t(uiLang, "saveChat")
                onClicked: {
                    var path = history.export(page.selected);
                    appWindow.showBanner(path ? S.t(uiLang, "saved", path.replace(/^.*MyDocs\//, "")) : S.t(uiLang, "saveFailed"));
                }
            }
            MenuItem {
                text: S.t(uiLang, "remove")
                onClicked: {
                    if (page.selected == chat.conversation())
                        appWindow.newConversation();
                    history.remove(page.selected);
                    page.reload();
                }
            }
        }
    }

    tools: ToolBarLayout {
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
