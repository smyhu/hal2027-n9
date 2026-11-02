import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S

Page {
    id: page
    orientationLock: PageOrientation.LockPortrait

    property variant providers: JSON.parse(store.providers())
    property string pid: store.get("provider", "gemini")
    property variant prov: findProvider(pid)
    property int keyVersion: 0
    property int colorVersion: 0

    function findProvider(id) {
        for (var i = 0; i < providers.length; ++i)
            if (providers[i].id == id)
                return providers[i];
        return providers[0];
    }
    function choose(id) {
        pid = id;
        store.set("provider", id);
        modelField.text = chat.model(id);
        keyField.text = "";
        appWindow.refreshProvider();
    }

    Connections {
        target: appWindow
        onModelsArrived: {
            modelButton.busy = false;
            if (ev.error) {
                appWindow.showBanner(ev.error == "nokey" ? S.t(uiLang, "noKey", page.prov.name) : S.t(uiLang, "apiError", ev.error));
                return;
            }
            if (!ev.models.length) {
                appWindow.showBanner(S.t(uiLang, "modelEmpty"));
                return;
            }
            modelsModel.clear();
            var list = ev.models.slice(0).sort();
            for (var i = 0; i < list.length; ++i)
                modelsModel.append({ "name": list[i] });
            modelDialog.open();
        }
    }

    Image { source: "img/tlo.png"; y: -36; smooth: false }
    Header {
        id: header
        title: S.t(uiLang, "settings") + " · " + (tabs.currentTab == aiTab ? "AI" : (tabs.currentTab == uiTab ? S.t(uiLang, "tabLook") : S.t(uiLang, "voiceEngine")))
    }

    // three tabs, chosen with icons on the toolbar (no words, so any
    // language fits): AI service, look, voice
    TabGroup {
        id: tabs
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        currentTab: aiTab

        Item {
            id: aiTab
            anchors.fill: parent
            Flickable {
                id: flickai
                anchors.fill: parent
                contentHeight: colai.height + 32
                clip: true
                Column {
                    id: colai
                    x: 16
                    y: 16
                    width: parent.width - 32
                    spacing: 14

                SectionLabel { text: S.t(uiLang, "service") }
                Repeater {
                    model: page.providers.length
                    delegate: Item {
                        property variant p: page.providers[index]
                        width: colai.width
                        height: 60
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: page.pid == p.id ? appWindow.tintFill : "#000000"
                            opacity: page.pid == p.id ? 0.9 : (ma.pressed ? 0.5 : 0.25)
                            border.color: page.pid == p.id ? Qt.lighter(appWindow.tintBorder, 1.6) : "transparent"
                        }
                        Label {
                            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                            text: p.name
                            font.pixelSize: 26
                            color: "white"
                        }
                        Label {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            text: (page.keyVersion >= 0 && store.hasKey(p.id) ? "● " : "") + (p.free ? S.t(uiLang, "free") : S.t(uiLang, "paid"))
                            font.pixelSize: 20
                            color: p.free ? "#9fd39f" : "#b0b0b0"
                        }
                        MouseArea { id: ma; anchors.fill: parent; onClicked: page.choose(p.id) }
                    }
                }

                SectionLabel { text: S.t(uiLang, "apiKey") + ": " + page.prov.name }
                Label {
                    width: colai.width
                    font.pixelSize: 22
                    color: "#d0d0d0"
                    text: page.keyVersion >= 0 && store.hasKey(page.pid) ? S.t(uiLang, "keyStored", store.keyHint(page.pid)) : S.t(uiLang, "keyNone")
                }
                TextField {
                    id: keyField
                    width: colai.width
                    echoMode: TextInput.Password
                    placeholderText: S.t(uiLang, "apiKey")
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                }
                Row {
                    spacing: 10
                    Button {
                        width: (colai.width - 20) / 3
                        text: S.t(uiLang, "paste")
                        onClicked: keyField.text = clipboard.text()
                    }
                    Button {
                        width: (colai.width - 20) / 3
                        text: S.t(uiLang, "keySave")
                        enabled: keyField.text.length > 8
                        onClicked: {
                            store.setKey(page.pid, keyField.text);
                            keyField.text = "";
                            page.keyVersion++;
                            appWindow.refreshProvider();
                        }
                    }
                    Button {
                        width: (colai.width - 20) / 3
                        text: S.t(uiLang, "keyDelete")
                        enabled: page.keyVersion >= 0 && store.hasKey(page.pid)
                        onClicked: {
                            store.setKey(page.pid, "");
                            page.keyVersion++;
                            appWindow.refreshProvider();
                        }
                    }
                }
                Label {
                    width: colai.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    color: "#a8a8a8"
                    text: S.t(uiLang, "keyWhere") + "\n" + page.prov.signup
                }
                Button {
                    width: colai.width
                    text: S.t(uiLang, "keyImport")
                    onClicked: {
                        var r = JSON.parse(store.importKeys());
                        if (r.error)
                            appWindow.showBanner(r.error == "nofile" ? S.t(uiLang, "keyNoFile") : r.error);
                        else
                            appWindow.showBanner(S.t(uiLang, "keyImported", r.imported.join(", ")));
                        page.keyVersion++;
                        appWindow.refreshProvider();
                    }
                }
                Label {
                    width: colai.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    color: "#a8a8a8"
                    text: S.t(uiLang, "keyImportHelp")
                }

                SectionLabel { text: S.t(uiLang, "model") }
                TextField {
                    id: modelField
                    width: colai.width
                    text: chat.model(page.pid)
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    onTextChanged: {
                        chat.setModel(page.pid, text);
                        appWindow.refreshProvider();
                    }
                }
                Button {
                    id: modelButton
                    property bool busy: false
                    width: colai.width
                    text: busy ? "…" : S.t(uiLang, "modelList")
                    enabled: !busy
                    onClicked: {
                        if (!net.online()) {
                            appWindow.showBanner(S.t(uiLang, "noInternet"));
                            return;
                        }
                        busy = true;
                        chat.fetchModels(page.pid);
                    }
                }

                SectionLabel { text: S.t(uiLang, "effort"); visible: page.pid == "claude" }
                ButtonRow {
                    width: colai.width
                    visible: page.pid == "claude"
                    Button {
                        text: S.t(uiLang, "low")
                        checked: store.get("effort", "low") == "low"
                        onClicked: store.set("effort", "low")
                    }
                    Button {
                        text: S.t(uiLang, "medium")
                        checked: store.get("effort", "low") == "medium"
                        onClicked: store.set("effort", "medium")
                    }
                    Button {
                        text: S.t(uiLang, "high")
                        checked: store.get("effort", "low") == "high"
                        onClicked: store.set("effort", "high")
                    }
                }
                Label {
                    width: colai.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    color: "#a8a8a8"
                    visible: page.pid == "claude"
                    text: S.t(uiLang, "effortHelp")
                }
                }
            }
            ScrollDecorator { flickableItem: flickai }
        }
        Item {
            id: uiTab
            anchors.fill: parent
            Flickable {
                id: flickui
                anchors.fill: parent
                contentHeight: colui.height + 32
                clip: true
                Column {
                    id: colui
                    x: 16
                    y: 16
                    width: parent.width - 32
                    spacing: 14

                SectionLabel { text: S.t(uiLang, "eyeColor") }
                Row {
                    spacing: (colui.width - 5 * 72) / 4
                    Repeater {
                        model: ["red", "green", "blue", "amber", "violet"]
                        delegate: Item {
                            width: 72; height: 72
                            Rectangle {
                                anchors.fill: parent
                                radius: 36
                                color: "transparent"
                                border.width: 3
                                border.color: page.colorVersion >= 0 && store.get("eyeColor", "red") == modelData ? "white" : "transparent"
                            }
                            Image {
                                anchors.centerIn: parent
                                width: 60; height: 60
                                smooth: true
                                source: "img/poswiata-" + modelData + ".png"
                                Image { anchors.fill: parent; smooth: true; source: "img/rdzen-" + modelData + ".png" }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { store.set("eyeColor", modelData); page.colorVersion++; appWindow.refreshProvider(); }
                            }
                        }
                    }
                }
                Item {
                    width: colui.width
                    height: 64
                    Label {
                        anchors { left: parent.left; right: colorSwitch.left; verticalCenter: parent.verticalCenter }
                        wrapMode: Text.Wrap
                        text: S.t(uiLang, "eyeByService")
                        font.pixelSize: 24
                    }
                    Switch {
                        id: colorSwitch
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        checked: store.get("eyeColor", "red") == "service"
                        onCheckedChanged: {
                            var cur = store.get("eyeColor", "red");
                            if (checked && cur != "service") { store.set("eyeColorFixed", cur); store.set("eyeColor", "service"); }
                            else if (!checked && cur == "service") store.set("eyeColor", store.get("eyeColorFixed", "red"));
                            page.colorVersion++;
                            appWindow.refreshProvider();
                        }
                    }
                }
                }
            }
            ScrollDecorator { flickableItem: flickui }
        }
        Item {
            id: voiceTab
            anchors.fill: parent
            Flickable {
                id: flickvoice
                anchors.fill: parent
                contentHeight: colvoice.height + 32
                clip: true
                Column {
                    id: colvoice
                    x: 16
                    y: 16
                    width: parent.width - 32
                    spacing: 14

                SectionLabel { text: S.t(uiLang, "speakMode") }
                ButtonRow {
                    width: colvoice.width
                    Button {
                        text: S.t(uiLang, "speakAuto")
                        checked: store.get("speakMode", "auto") == "auto"
                        onClicked: store.set("speakMode", "auto")
                    }
                    Button {
                        text: S.t(uiLang, "speakAsk")
                        checked: store.get("speakMode", "auto") == "ask"
                        onClicked: store.set("speakMode", "ask")
                    }
                    Button {
                        text: S.t(uiLang, "speakOff")
                        checked: store.get("speakMode", "auto") == "off"
                        onClicked: store.set("speakMode", "off")
                    }
                }
                Label {
                    width: colvoice.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    color: "#a8a8a8"
                    text: S.t(uiLang, "speakAutoHelp")
                }

                SectionLabel { text: S.t(uiLang, "voiceEngine"); visible: speech.offlineAvailable() }
                ButtonRow {
                    width: colvoice.width
                    visible: speech.offlineAvailable()
                    Button {
                        text: S.t(uiLang, "speakAuto")
                        checked: store.get("voiceEngine", "auto") == "auto"
                        onClicked: store.set("voiceEngine", "auto")
                    }
                    Button {
                        text: "Google"
                        checked: store.get("voiceEngine", "auto") == "google"
                        onClicked: store.set("voiceEngine", "google")
                    }
                    Button {
                        text: S.t(uiLang, "voiceOffline")
                        checked: store.get("voiceEngine", "auto") == "offline"
                        onClicked: store.set("voiceEngine", "offline")
                    }
                }
                Label {
                    width: colvoice.width
                    wrapMode: Text.Wrap
                    font.pixelSize: 20
                    color: "#a8a8a8"
                    visible: speech.offlineAvailable()
                    text: S.t(uiLang, "voiceEngineHelp")
                }
                Label {
                    visible: speech.offlineAvailable()
                    font.pixelSize: 22
                    text: S.t(uiLang, "voiceSpeed") + ": " + speedSlider.value
                }
                Slider {
                    id: speedSlider
                    width: colvoice.width
                    visible: speech.offlineAvailable()
                    minimumValue: 80
                    maximumValue: 200
                    stepSize: 5
                    valueIndicatorVisible: true
                    value: parseInt(store.get("voiceSpeed", "130"))
                    onPressedChanged: if (!pressed) store.set("voiceSpeed", "" + value)
                }
                Label {
                    visible: speech.offlineAvailable()
                    font.pixelSize: 22
                    text: S.t(uiLang, "voicePitch") + ": " + pitchSlider.value
                }
                Slider {
                    id: pitchSlider
                    width: colvoice.width
                    visible: speech.offlineAvailable()
                    minimumValue: 0
                    maximumValue: 99
                    stepSize: 5
                    valueIndicatorVisible: true
                    value: parseInt(store.get("voicePitch", "25"))
                    onPressedChanged: if (!pressed) store.set("voicePitch", "" + value)
                }
                Button {
                    width: colvoice.width
                    text: S.t(uiLang, "voiceTest")
                    onClicked: {
                        store.set("voiceSpeed", "" + speedSlider.value);
                        store.set("voicePitch", "" + pitchSlider.value);
                        var engine = appWindow.voiceEngine();
                        if (engine == "google" && !net.online())
                            appWindow.showBanner(S.t(uiLang, "noInternet"));
                        else
                            appWindow.player().speak(S.t(uiLang, "voiceSample"), uiLang, engine);
                    }
                }
                }
            }
            ScrollDecorator { flickableItem: flickvoice }
        }
    }

    ListModel { id: modelsModel }
    SelectionDialog {
        id: modelDialog
        titleText: S.t(uiLang, "modelPick")
        model: modelsModel
        onAccepted: modelField.text = modelsModel.get(selectedIndex).name
    }

    tools: ToolBarLayout {
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
        ButtonRow {
            style: TabButtonStyle { }
            TabButton { iconSource: "image://theme/icon-m-toolbar-new-chat-white"; tab: aiTab }
            TabButton { iconSource: "image://theme/icon-m-toolbar-image-edit-white"; tab: uiTab }
            TabButton { iconSource: "image://theme/icon-m-toolbar-headphones-white"; tab: voiceTab }
        }
    }
}
