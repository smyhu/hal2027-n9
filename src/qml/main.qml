import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1
import "strings.js" as S

PageStackWindow {
    id: appWindow

    showStatusBar: true
    initialPage: EyePage { id: eyePage }

    property color accent: "#e0281e"
    property string providerLine: ""
    property bool muted: store.get("muted", "0") == "1"
    property string eyeColor: "red"
    // dark tints of the eye colour for answer bubbles and title bars
    property variant tints: { "red": ["#3d0d0b", "#7a1a14", "#5a120d"], "green": ["#0c2e12", "#1d6a2a", "#12441b"],
                              "blue": ["#0b1a3d", "#1c3f86", "#10275a"], "amber": ["#3a2205", "#7d4a0a", "#5a3408"],
                              "violet": ["#270c3d", "#55228a", "#3a125a"] }
    property color tintFill: tints[eyeColor][0]
    property color tintBorder: tints[eyeColor][1]
    property color tintHeader: tints[eyeColor][2]
    // eye colour: one chosen colour, or by service
    property variant serviceColors: { "gemini": "blue", "claude": "amber", "openai": "green",
                                      "openrouter": "violet", "groq": "red", "mistral": "amber", "xai": "violet" }
    signal modelsArrived(variant ev)

    function openConversation(id) { eyePage.openConversation(id); }
    function newConversation() { eyePage.newConversation(); }

    function refreshProvider() {
        var pid = store.get("provider", "gemini");
        var m = chat.model(pid);
        var c = store.get("eyeColor", "red");
        eyeColor = c == "service" ? (serviceColors[pid] || "red") : c;
        // Qt Components accent colour closest to the eye (no pure red exists)
        theme.colorScheme = { "red": 14, "green": 3, "blue": 7, "amber": 17, "violet": 10 }[eyeColor] || 14;
        providerLine = chat.providerName() + (m ? " · " + m : "") + (store.hasKey(pid) ? "" : " · " + S.t(uiLang, "keyNone"));
    }

    function showBanner(text) {
        banner.text = text;
        banner.show();
    }

    InfoBanner {
        id: banner
        y: 36 + 8
    }

    // Audio player and battery probe in their own files: if a Qt Mobility
    // module is missing, only that feature is lost, not the whole app.
    Loader {
        id: playerLoader
        source: "Player.qml"
    }
    Loader {
        id: batteryLoader
        source: "BatteryProbe.qml"
    }
    property bool canSpeak: playerLoader.status == Loader.Ready
    property bool speaking: canSpeak && playerLoader.item.busy

    // voice engine for now: google needs internet, offline is espeak-ng.
    // auto: Google over Wi-Fi, offline on 2G/3G or without a connection.
    function voiceEngine() {
        var e = store.get("voiceEngine", "auto");
        if (!speech.offlineAvailable())
            return "google";
        if (e == "auto")
            return net.link() == "wifi" ? "google" : "offline";
        return e;
    }
    function speak(text) {
        var engine = voiceEngine();
        if (engine == "google" && !net.online())
            showBanner(S.t(uiLang, "noInternet"));
        else if (canSpeak)
            playerLoader.item.speak(text, guessLanguage(text), engine);
    }
    function player() { return playerLoader.item; }
    function stopSpeaking() {
        if (canSpeak)
            playerLoader.item.stop();
    }

    // Auto speaking rule: Wi-Fi and battery above 40% (or charging).
    // Below 40% the N9 battery gauge (BME) gets unreliable under load.
    function autoSpeakAllowed() {
        var mode = store.get("speakMode", "auto");
        if (muted || mode != "auto")
            return false;
        // Google speech only over Wi-Fi; offline speech costs no data
        if (net.link() != "wifi" && voiceEngine() != "offline")
            return false;
        if (batteryLoader.status == Loader.Ready) {
            var b = batteryLoader.item;
            if (!b.charging && b.level >= 0 && b.level <= 40)
                return false;
        }
        return true;
    }

    // language of a text for Google speech: Polish letters -> pl, else UI language
    function guessLanguage(text) {
        if (/[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]/.test(text))
            return "pl";
        if (/[äöüßÄÖÜ]/.test(text))
            return "de";
        if (/[а-яА-Я]/.test(text))
            return "ru";
        if (/[a-zA-Z]/.test(text) && uiLang == "pl" && !/\b(się|jest|nie|to|że)\b/.test(text))
            return "en";
        return uiLang;
    }

    Component.onCompleted: {
        theme.inverted = true;
        refreshProvider();
    }
}
