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
    // search: pull the list down at its top to show the field
    property bool searching: false

    // Opening: the field takes the gap the pull opened at once (no jump of
    // the list) and its content fades in rising from the bottom. Closing:
    // the content fades out, then the space closes and the list glides up.
    // An empty field closes by itself after 5 s without use (as in exNote).
    function openSearch() {
        if (searching)
            return;
        closeAnim.stop();
        barAnimated = false;
        searching = true;
        barAnimated = true;
        openAnim.restart();
        search.forceActiveFocus();
        search.platformOpenSoftwareInputPanel();
        idle.restart();
    }
    function closeSearch() {
        if (!searching)
            return;
        idle.stop();
        search.platformCloseSoftwareInputPanel();
        openAnim.stop();
        closeAnim.restart();
    }
    property bool barAnimated: true

    function reload() {
        var n = {};
        var provs = JSON.parse(store.providers());
        for (var k = 0; k < provs.length; ++k)
            n[provs[k].id] = provs[k].short || provs[k].name;
        model.clear();
        var rows = JSON.parse(searching ? history.search(search.text) : history.list());
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

    // search field, shown by pulling the list down
    Item {
        id: searchBar
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height: page.searching ? 76 : 0
        clip: true
        Behavior on height {
            enabled: page.barAnimated
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
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
                Keys.onReturnPressed: { searchDelay.stop(); page.reload(); search.platformCloseSoftwareInputPanel(); }
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
    }
    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: searchContent; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutQuad }
        NumberAnimation { target: searchContent; property: "y"; from: 30; to: 0; duration: 300; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: searchContent; property: "opacity"; to: 0; duration: 200 }
        ScriptAction { script: { search.text = ""; page.searching = false; page.reload(); } }
    }
    // an empty field goes away after 5 s without use
    Timer {
        id: idle
        interval: 5000
        onTriggered: if (search.text == "") page.closeSearch()
    }
    Timer { id: searchDelay; interval: 400; onTriggered: page.reload() }

    ListView {
        id: list
        anchors { top: searchBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: true
        model: model
        // MeeGo Touch list filtering (MListFilter, as in exNote): a pull that
        // starts at the top of the list opens the search field as soon as it
        // has gone far enough, while the finger is still down. The field
        // takes the gap the pull opened, so the list does not jump.
        property real pullStart: 0
        property bool pulling: false
        onMovementStarted: {
            pullStart = contentY;
            pulling = !page.searching && contentY <= 0;
            if (page.searching)
                idle.restart();
        }
        onMovementEnded: pulling = false
        onContentYChanged: {
            if (!pulling)
                return;
            var distance = pullStart - contentY;
            // the list follows the finger at half speed past its top, so
            // about two thirds of the field's height already needs a long pull
            if (distance >= 50) {
                pulling = false;
                page.openSearch();
                contentY += 76;
            } else if (distance < 0) {
                pulling = false;          // wrong direction
            }
        }
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
        text: page.searching && search.text != "" ? S.t(uiLang, "noResults") : S.t(uiLang, "noHistory")
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
        ToolIcon {
            iconId: "toolbar-search"
            onClicked: page.searching ? page.closeSearch() : page.openSearch()
        }
    }
}
