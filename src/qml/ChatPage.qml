import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S

// The whole current conversation as message bubbles (like Messages).
Page {
    id: page
    orientationLock: PageOrientation.LockPortrait
    property string selected: ""

    function reload() {
        model.clear();
        var id = chat.conversation();
        if (!id)
            return;
        var msgs = JSON.parse(history.load(id));
        for (var i = 0; i < msgs.length; ++i)
            model.append({ "role": msgs[i].role, "text": msgs[i].text });
        list.positionViewAtEnd();
    }
    Component.onCompleted: reload()

    Image { source: "img/background.png"; y: -36; smooth: false }

    ListModel { id: model }

    Header { id: header; title: S.t(uiLang, "conversation") }

    ListView {
        id: list
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
        clip: true
        model: model
        spacing: 6
        delegate: Bubble {
            role: model.role
            text: model.text
            maxWidth: list.width
            onPressAndHold: { page.selected = model.text; menu.open(); }
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
                text: S.t(uiLang, "copy")
                onClicked: { clipboard.setText(page.selected); appWindow.showBanner(S.t(uiLang, "copied")); }
            }
            MenuItem {
                text: appWindow.speaking ? S.t(uiLang, "stop") : S.t(uiLang, "speak")
                onClicked: appWindow.speaking ? appWindow.stopSpeaking() : appWindow.speak(page.selected)
            }
        }
    }

    tools: ToolBarLayout {
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
