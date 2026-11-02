import QtQuick 1.1
import QtMultimediaKit 1.1
import "strings.js" as S

// Reads text aloud: main.py downloads Google speech as MP3 pieces, this
// plays them one after another (the first starts while the rest download).
Item {
    id: player
    property bool busy: false
    property variant files: []
    property int index: 0

    function speak(text, lang, engine) {
        stop();
        busy = true;
        speech.speakWith(text, lang, engine || "google");
    }
    function stop() {
        speech.stop();
        audio.stop();
        busy = false;
        files = [];
        index = 0;
    }
    function playIndex(i) {
        files = JSON.parse(speech.allFiles());
        if (i >= files.length) {
            if (speech.downloading())
                waitTimer.start();      // next piece is still on its way
            else
                busy = false;
            return;
        }
        index = i;
        audio.source = "";
        audio.source = "file://" + files[i];
        audio.play();
    }

    Timer {
        id: waitTimer
        interval: 300
        onTriggered: player.playIndex(player.index + 1)
    }

    Audio {
        id: audio
        onStatusChanged: {
            if (status == Audio.EndOfMedia)
                player.playIndex(player.index + 1);
            else if (status == Audio.InvalidMedia) {
                player.busy = false;
                appWindow.showBanner(S.t(uiLang, "speakError"));
            }
        }
    }

    Connections {
        target: speech
        onReady: {
            if (player.busy && !audio.playing && player.index == 0)
                player.playIndex(0);
        }
        onFailed: {
            if (player.index == 0 && !audio.playing) {
                player.busy = false;
                appWindow.showBanner(S.t(uiLang, "speakError"));
            }
        }
    }
}
