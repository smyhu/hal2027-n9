import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S
import "translator.js" as T

// Google Translate with the dictionary and reading aloud (from MeeTranslate).
Page {
    id: page
    orientationLock: PageOrientation.LockPortrait

    property string from: store.get("tr.from", "auto")
    property string to: store.get("tr.to", uiLang)
    property string result: ""
    property string detected: ""
    property variant dictionary: []
    property bool busy: false
    property int job: 0
    property string pickFor: ""

    function translate() {
        var text = input.text;
        if (!text.replace(/\s/g, "").length)
            return;
        if (!net.online()) {
            appWindow.showBanner(S.t(uiLang, "noInternet"));
            return;
        }
        input.platformCloseSoftwareInputPanel();
        busy = true;
        job++;
        net.request("tr:" + job + ":s", T.googleUrl(true, from, to, uiLang), T.googleBody(text));
    }

    function finished(tag, ok, body) {
        var parts = tag.split(":");
        if (parts[1] != String(job))
            return;
        var res = ok ? T.parseGoogle(body) : null;
        if (!res && parts[2] == "s" && net.online()) {
            // HTTPS failed: Google also answers over plain HTTP
            net.request("tr:" + job + ":p", T.googleUrl(false, from, to, uiLang), T.googleBody(input.text));
            return;
        }
        busy = false;
        if (!res) {
            appWindow.showBanner(S.t(uiLang, "netError", body.substring(0, 80)));
            return;
        }
        result = res.text;
        detected = (from == "auto" && res.detected) ? res.detected : "";
        dictionary = res.dictionary;
    }

    Connections {
        target: net
        onFinished: {
            var r;
            while ((r = net.take()) != "") {
                var j = JSON.parse(r);
                if (j.tag.indexOf("tr:") == 0)
                    page.finished(j.tag, j.ok, j.body);
            }
        }
    }

    Image { source: "img/background.png"; y: -36; smooth: false }
    Header { id: header; title: S.t(uiLang, "translate") }

    Flickable {
        id: flick
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: column.height + 32
        clip: true

        Column {
            id: column
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 12

            Row {
                spacing: 8
                Button {
                    width: (column.width - 72) / 2
                    text: T.languageName(uiLang, page.from)
                    onClicked: page.pickLanguage(true)
                }
                Button {
                    width: 56
                    iconSource: "image://theme/icon-m-toolbar-refresh-white"
                    enabled: page.from != "auto"
                    onClicked: {
                        var f = page.from;
                        page.from = page.to; page.to = f;
                        store.set("tr.from", page.from); store.set("tr.to", page.to);
                        if (page.result) { input.text = page.result; page.translate(); }
                    }
                }
                Button {
                    width: (column.width - 72) / 2
                    text: T.languageName(uiLang, page.to)
                    onClicked: page.pickLanguage(false)
                }
            }

            TextArea {
                id: input
                width: column.width
                height: Math.max(130, implicitHeight)
                placeholderText: S.t(uiLang, "textToTranslate")
            }
            Row {
                spacing: 10
                Button {
                    width: (column.width - 10) * 0.35
                    text: S.t(uiLang, "paste")
                    onClicked: input.text = clipboard.text()
                }
                Button {
                    width: (column.width - 10) * 0.65
                    text: page.busy ? "…" : S.t(uiLang, "translate")
                    enabled: !page.busy
                    onClicked: page.translate()
                }
            }

            Label {
                visible: page.detected != ""
                text: S.t(uiLang, "detected", T.languageName(uiLang, page.detected))
                font.pixelSize: 20
                color: "#a8a8a8"
            }
            Rectangle {
                visible: page.result != ""
                width: column.width
                height: resultText.paintedHeight + 28
                radius: 12
                color: appWindow.tintFill
                border.color: appWindow.tintBorder
                Text {
                    id: resultText
                    x: 14; y: 14
                    width: parent.width - 28
                    wrapMode: Text.Wrap
                    text: page.result
                    color: "white"
                    font.pixelSize: 26
                }
                MouseArea {
                    anchors.fill: parent
                    onPressAndHold: { clipboard.setText(page.result); appWindow.showBanner(S.t(uiLang, "copied")); }
                }
            }
            Row {
                visible: page.result != ""
                spacing: 10
                Button {
                    width: (column.width - 10) / 2
                    text: appWindow.speaking ? S.t(uiLang, "stop") : S.t(uiLang, "speak")
                    onClicked: {
                        if (appWindow.speaking)
                            appWindow.stopSpeaking();
                        else if (appWindow.canSpeak)
                            playerSpeak(page.result, page.to);
                    }
                }
                Button {
                    width: (column.width - 10) / 2
                    text: S.t(uiLang, "copy")
                    onClicked: { clipboard.setText(page.result); appWindow.showBanner(S.t(uiLang, "copied")); }
                }
            }

            SectionLabel { text: S.t(uiLang, "dictionary"); visible: page.dictionary.length > 0 }
            Repeater {
                model: page.dictionary.length
                delegate: Column {
                    width: column.width
                    property variant sec: page.dictionary[index]
                    Label { text: sec.pos; font.pixelSize: 20; font.italic: true; color: "#e05a50"; visible: sec.pos != "" }
                    Repeater {
                        model: sec.entries.length
                        delegate: Label {
                            width: column.width
                            wrapMode: Text.Wrap
                            font.pixelSize: 22
                            color: "#e8e8e8"
                            text: "<b>" + sec.entries[index].word + "</b>" + (sec.entries[index].reverse ? "  <font color='#a0a0a0'>" + sec.entries[index].reverse + "</font>" : "")
                        }
                    }
                }
            }
        }
    }
    ScrollDecorator { flickableItem: flick }

    function playerSpeak(text, lang) {
        if (!net.online()) {
            appWindow.showBanner(S.t(uiLang, "noInternet"));
            return;
        }
        playerLoader().speak(text, lang);
    }
    function playerLoader() { return appWindow.player(); }

    function pickLanguage(source) {
        var p = pageStack.push(Qt.resolvedUrl("LanguagePage.qml"),
                               { "service": "google", "isSource": source, "current": source ? page.from : page.to });
        p.picked.connect(function(code) {
            if (source) { page.from = code; store.set("tr.from", code); }
            else { page.to = code; store.set("tr.to", code); }
        });
    }

    tools: ToolBarLayout {
        ToolIcon { iconId: "toolbar-back"; onClicked: pageStack.pop() }
    }
}
