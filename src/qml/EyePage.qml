import QtQuick 1.1
import com.nokia.meego 1.0
import "strings.js" as S

// Main screen. At rest the eye fills the width and the question field sits
// just below it. When an answer comes, the eye shrinks to half and moves up,
// and the area with the question and the answer grows.
Page {
    id: page
    orientationLock: PageOrientation.LockPortrait

    property bool talking: false        // layout with the answer area
    property bool busy: false           // waiting for / receiving an answer
    property string question: ""
    property string answer: ""
    property bool streaming: false
    property bool mobile: false
    // while the keyboard is open: small eye at the top and the field right
    // under it, so the keyboard never covers what is being typed
    property bool typing: false
    property bool small: talking || typing
    property string listening: ""       // "", "rec" (recording), "stt" (writing it down)
    // lowest point free for the question field: the page itself already
    // shrinks above the open keyboard (Window.qml heightDelta), so its bottom
    // is the keyboard top; without the keyboard it is the toolbar top
    property real bottomLimit: height

    function send() {
        var text = input.text;
        if (!text.replace(/\s/g, "").length || busy)
            return;
        if (!net.online()) {
            appWindow.showBanner(S.t(uiLang, "noInternet"));
            return;
        }
        appWindow.stopSpeaking();
        mobile = net.link() == "mobile";
        question = text;
        answer = "";
        follow = true;
        msgs.append({ "role": "user", "text": text, "live": false });
        msgs.append({ "role": "assistant", "text": S.t(uiLang, "thinking"), "live": false });
        input.text = "";
        input.platformCloseSoftwareInputPanel();
        typing = false;
        talking = true;
        busy = true;
        streaming = false;
        eye.mode = "thinking";
        waitAnim.restart();
        chat.send(text, mobile);
        scrollToEnd();
    }

    // the answer being written is the last item of the list
    function showAnswer(text, live) {
        if (msgs.count && msgs.get(msgs.count - 1).role == "assistant") {
            msgs.setProperty(msgs.count - 1, "text", text);
            msgs.setProperty(msgs.count - 1, "live", live);
        }
        scrollToEnd();
    }
    function scrollToEnd() {
        if (!follow)
            return;
        zone.positionViewAtEnd();
    }
    property bool follow: true

    // microphone: first tap records, second tap ends and the speech is
    // written into the field (check it, then ENTER sends)
    function listen() {
        if (listening == "rec") {
            finishRecording();
            return;
        }
        if (listening == "stt") {
            endListening();
            return;
        }
        if (!net.online()) {
            appWindow.showBanner(S.t(uiLang, "noInternet"));
            return;
        }
        appWindow.stopSpeaking();
        listening = "rec";
        eye.inputLevel = 0;
        eye.mode = "listening";
        listener.record(uiLang);
    }
    // show at once that the recording is over, even before the recorder ends
    function finishRecording() {
        listener.finish();
        listening = "stt";
        eye.inputLevel = 0;
        eye.mode = "thinking";
        rewind.restart();
    }
    function endListening() {
        listener.drop();
        listening = "";
        rewind.restart();
        eye.inputLevel = 0;
        if (!busy)
            eye.mode = "idle";
    }
    function handleListener(ev) {
        if (ev.type == "level") {
            if (listening != "rec")
                return;
            eye.inputLevel = Math.min(1, ev.value * 1.6);
            eye.progress = Math.min(1, ev.seconds / listener.maxSeconds());
        } else if (ev.type == "transcribing") {
            listening = "stt";
            eye.inputLevel = 0;
            eye.mode = "thinking";
            rewind.restart();
        } else if (ev.type == "fallback") {
            appWindow.showBanner(S.t(uiLang, "sttFallback", ev.service));
        } else if (ev.type == "text") {
            listening = "";
            eye.mode = "idle";
            input.text = input.text.replace(/\s+$/, "") + (input.text.replace(/\s/g, "").length ? " " : "") + ev.text;
            input.forceActiveFocus();
            input.cursorPosition = input.text.length;
            input.platformOpenSoftwareInputPanel();
        } else if (ev.type == "error") {
            var key = { "mic": "micError", "nokey": "sttNoKey", "short": "sttShort", "empty": "sttEmpty" }[ev.code] || "sttError";
            appWindow.showBanner(S.t(uiLang, key, ev.message || ""));
            listening = "";
            rewind.restart();
            eye.inputLevel = 0;
            if (!busy)
                eye.mode = "idle";
        }
    }
    Connections {
        target: listener
        onNews: {
            var r;
            while ((r = listener.take()) != "")
                page.handleListener(JSON.parse(r));
        }
    }

    function stopAll() {
        if (listening != "")
            endListening();
        if (busy && msgs.count && msgs.get(msgs.count - 1).role == "assistant") {
            if (answer == "")
                msgs.remove(msgs.count - 1);
            else
                msgs.setProperty(msgs.count - 1, "live", false);
        }
        chat.stop();
        appWindow.stopSpeaking();
        finishWaiting();
        busy = false;
        streaming = false;
        eye.mode = "idle";
    }

    function finishWaiting() {
        waitAnim.stop();
        rewind.restart();
    }

    function newConversation() {
        stopAll();
        chat.newConversation();
        question = "";
        answer = "";
        msgs.clear();
        talking = false;
    }

    function openConversation(id) {
        stopAll();
        chat.open(id);
        var rows = JSON.parse(history.load(id));
        question = "";
        answer = "";
        msgs.clear();
        for (var i = 0; i < rows.length; ++i) {
            msgs.append({ "role": rows[i].role, "text": rows[i].text, "live": false });
            if (rows[i].role == "user")
                question = rows[i].text;
            else
                answer = rows[i].text;
        }
        talking = question != "";
        follow = true;
        zone.positionViewAtEnd();
    }

    function handleEvent(ev) {
        if (ev.type == "delta") {
            if (!streaming) {
                streaming = true;
                finishWaiting();
                eye.mode = "speaking";
            }
            answer += ev.text;
            showAnswer(answer, true);
        } else if (ev.type == "fallback") {
            appWindow.showBanner(S.t(uiLang, "fallback", ev.model));
        } else if (ev.type == "done") {
            busy = false;
            streaming = false;
            answer = ev.text;
            showAnswer(answer, false);
            finishWaiting();
            if (ev.note == "refusal")
                appWindow.showBanner(S.t(uiLang, "refusal"));
            if (appWindow.autoSpeakAllowed()) {
                appWindow.speak(answer);
            } else {
                eye.mode = "idle";
            }
        } else if (ev.type == "error") {
            busy = false;
            streaming = false;
            finishWaiting();
            eye.mode = "idle";
            var msg;
            if (ev.code == "nokey")
                msg = S.t(uiLang, "noKey", ev.message);
            else if (ev.code == "nomodel")
                msg = S.t(uiLang, "noModel", ev.message);
            else if (ev.message == "refusal")
                msg = S.t(uiLang, "refusal");
            else
                msg = S.t(uiLang, "apiError", ev.message);
            if (answer == "")
                answer = msg;
            showAnswer(answer, false);
            appWindow.showBanner(msg);
        }
    }

    Connections {
        target: chat
        onEvent: {
            var r;
            while ((r = chat.take()) != "") {
                var ev = JSON.parse(r);
                if (ev.type != "models")
                    page.handleEvent(ev);
                else
                    appWindow.modelsArrived(ev);
            }
        }
    }

    // keyboard closed by the user: back to the normal layout
    Connections {
        target: typeof(inputContext) != "undefined" ? inputContext : null
        ignoreUnknownSignals: true
        onSoftwareInputPanelVisibleChanged: {
            if (!inputContext.softwareInputPanelVisible)
                page.typing = false;
            else if (input.activeFocus)
                page.typing = true;
        }
    }

    // eye follows reading aloud
    Connections {
        target: appWindow
        onSpeakingChanged: {
            if (appWindow.speaking)
                eye.mode = "speaking";
            else if (!page.busy)
                eye.mode = "idle";
        }
    }

    Image {
        source: "img/background.png"
        y: -36
        smooth: false
    }

    Eye {
        id: eye
        size: page.small ? 220 : 440
        x: (page.width - size) / 2
        y: page.small ? 6 : 20
        active: platformWindow.active
        color: appWindow.eyeColor
        Behavior on size { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        onClicked: {
            if (page.listening == "rec") {
                page.finishRecording();
                return;
            }
            if (page.typing) {
                page.typing = false;
                input.platformCloseSoftwareInputPanel();
                return;
            }
            if (page.question != "")
                page.talking = !page.talking;
        }
    }
    NumberAnimation {
            id: waitAnim
            target: eye; property: "progress"
            from: 0; to: 0.97
            duration: 25000
            easing.type: Easing.OutQuad
        }
    NumberAnimation {
            id: rewind
            target: eye; property: "progress"
            to: 0
            duration: 450
            easing.type: Easing.InOutQuad
    }

    // the whole conversation, newest at the bottom
    ListModel { id: msgs }
    property string selectedText: ""
    ListView {
        id: zone
        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
        y: eye.y + eye.size + 12
        height: Math.max(0, inputRow.y - y - 10)
        clip: true
        spacing: 6
        model: msgs
        opacity: page.talking && !page.typing ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        // reading older messages stops the automatic scrolling to the end
        onMovementEnded: page.follow = atYEnd
        delegate: Bubble {
            role: model.role
            text: model.text
            streaming: model.live
            maxWidth: zone.width
            onPressAndHold: { page.selectedText = model.text; answerMenu.open(); }
        }
    }
    ScrollDecorator { flickableItem: zone }

    // question field
    Item {
        id: inputRow
        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
        // grows with the text (several lines of dictation fit)
        height: Math.max(56, input.height + 4)
        // centred between the eye and the keyboard top (or the screen bottom);
        // with a conversation on screen (no keyboard) it sits at the bottom
        property real eyeBottom: eye.y + eye.size
        y: page.talking && !page.typing ? page.bottomLimit - height - 10
           : Math.max(eyeBottom + 12, eyeBottom + (page.bottomLimit - eyeBottom - height) / 2)
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 150 } }

        // one dark frame: text on the left, microphone (or stop) on the right
        Rectangle {
            id: inputFrame
            anchors.fill: parent
            radius: 12
            color: "#0c0c0c"
            border.width: 1
            border.color: input.activeFocus || page.listening != "" ? Qt.lighter(appWindow.tintBorder, 1.6) : appWindow.tintBorder
        }
        TextArea {
            id: input
            anchors { left: parent.left; right: micButton.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            wrapMode: TextEdit.Wrap
            placeholderText: page.listening == "rec" ? S.t(uiLang, "listening") :
                             page.listening == "stt" ? S.t(uiLang, "transcribing") : S.t(uiLang, "ask")
            platformStyle: TextAreaStyle {
                background: ""; backgroundSelected: ""; backgroundDisabled: ""; backgroundError: ""
                textColor: "#ffffff"
                paddingLeft: 12
            }
            platformSipAttributes: SipAttributes {
                actionKeyLabel: S.t(uiLang, "send")
                actionKeyEnabled: input.text.length > 0
            }
            // ENTER / "Send" on the keyboard: the text area's inner editor takes
            // the key itself and adds a new line, so a new line means "send"
            onTextChanged: {
                if (text.indexOf("\n") >= 0)
                    enterTimer.restart();     // not inside the editor's own change
            }
            Timer {
                id: enterTimer
                interval: 0
                onTriggered: {
                    input.text = input.text.replace(/\n/g, " ").replace(/\s+$/, "");
                    page.send();
                }
            }
            onActiveFocusChanged: if (activeFocus) page.typing = true
            // the stock text area only ever grows; follow the text both ways
            onImplicitHeightChanged: { __originalHeight = 0; height = implicitHeight; }
        }
        Item {
            id: micButton
            width: 60
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            Image {
                anchors.centerIn: parent
                visible: page.listening != "stt"
                source: page.busy && page.listening == "" ? "image://theme/icon-m-toolbar-stop-white" : "img/microphone.png"
                opacity: micArea.pressed ? 0.5 : 0.9
                scale: page.listening == "rec" ? 1.0 + 0.35 * eye.inputLevel : 1.0
                Behavior on scale { NumberAnimation { duration: 90 } }
            }
            BusyIndicator {
                anchors.centerIn: parent
                visible: page.listening == "stt"
                running: visible
                platformStyle: BusyIndicatorStyle { inverted: true }
            }
            MouseArea {
                id: micArea
                anchors.fill: parent
                onClicked: page.busy && page.listening == "" ? page.stopAll() : page.listen()
            }
        }
    }

    // while recording, a tap anywhere ends it ("tap to finish")
    MouseArea {
        anchors.fill: parent
        z: 50
        enabled: page.listening == "rec"
        visible: enabled
        onClicked: page.finishRecording()
    }

    Label {
        id: status
        anchors { horizontalCenter: parent.horizontalCenter; top: inputRow.bottom; topMargin: 14 }
        width: parent.width - 32
        horizontalAlignment: Text.AlignHCenter
        opacity: page.small ? 0 : 0.6
        Behavior on opacity { NumberAnimation { duration: 300 } }
        font.pixelSize: 20
        color: "#c8c8c8"
        text: appWindow.providerLine
    }

    ContextMenu {
        id: answerMenu
        MenuLayout {
            MenuItem {
                text: S.t(uiLang, "copy")
                onClicked: { clipboard.setText(page.selectedText); appWindow.showBanner(S.t(uiLang, "copied")); }
            }
            MenuItem {
                text: appWindow.speaking ? S.t(uiLang, "stop") : S.t(uiLang, "speak")
                onClicked: appWindow.speaking ? appWindow.stopSpeaking() : appWindow.speak(page.selectedText)
            }
            MenuItem {
                text: S.t(uiLang, "clearChat")
                onClicked: clearDialog.open()
            }
        }
    }

    Menu {
        id: mainMenu
        MenuLayout {
            MenuItem { text: S.t(uiLang, "translate"); onClicked: pageStack.push(Qt.resolvedUrl("TranslatePage.qml")) }
            MenuItem {
                text: S.t(uiLang, "saveChat")
                enabled: page.question != ""
                onClicked: {
                    var path = history.export(chat.conversation());
                    appWindow.showBanner(path ? S.t(uiLang, "saved", path.replace(/^.*MyDocs\//, "")) : S.t(uiLang, "saveFailed"));
                }
            }
            MenuItem { text: S.t(uiLang, "settings"); onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml")) }
            MenuItem { text: S.t(uiLang, "about"); onClicked: aboutDialog.open() }
        }
    }

    // deletes the whole conversation, also from the conversation list
    QueryDialog {
        id: clearDialog
        titleText: S.t(uiLang, "clearChat")
        message: S.t(uiLang, "clearChatAsk")
        acceptButtonText: S.t(uiLang, "remove")
        rejectButtonText: S.t(uiLang, "cancel")
        onAccepted: {
            var id = chat.conversation();
            page.newConversation();
            if (id)
                history.remove(id);
        }
    }

    QueryDialog {
        id: aboutDialog
        titleText: "HAL 2027 " + appVersion
        message: S.t(uiLang, "aboutText") + "<br><br>" + S.t(uiLang, "credit") +
                 "<br><br>MIT · <a href=\"https://github.com/smyhu/hal2027-n9\" style=\"color:" + appWindow.accent +
                 "; text-decoration:underline\">github.com/smyhu/hal2027-n9</a>"
        acceptButtonText: S.t(uiLang, "close")
        onLinkActivated: Qt.openUrlExternally(link)
    }

    tools: ToolBarLayout {
        ToolIcon {
            iconId: "toolbar-add"
            onClicked: page.newConversation()
        }
        ToolIcon {
            iconId: appWindow.muted ? "toolbar-volume-off" : "toolbar-volume"
            onClicked: {
                appWindow.muted = !appWindow.muted;
                store.set("muted", appWindow.muted ? "1" : "0");
                if (appWindow.muted)
                    appWindow.stopSpeaking();
                appWindow.showBanner(S.t(uiLang, appWindow.muted ? "mutedOn" : "mutedOff"));
            }
        }
        ToolIcon {
            iconId: "toolbar-list"
            onClicked: pageStack.push(Qt.resolvedUrl("HistoryPage.qml"))
        }
        ToolIcon {
            iconId: "toolbar-view-menu"
            onClicked: mainMenu.status == DialogStatus.Closed ? mainMenu.open() : mainMenu.close()
        }
    }
}
