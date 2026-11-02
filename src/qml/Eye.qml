import QtQuick 1.1

// The eye: layered images (ring, red glow, hot core, glass reflections).
// level 0..1 drives the glow; it is computed by one timer from the mode:
//   idle - slow breathing, thinking - fast pulse, speaking - follows the voice
//   (random envelope until the audio level is known), listening - mic level.
// progress 0..1 draws a red arc inside the ring, from 12 o'clock clockwise.
Item {
    id: eye
    property real size: 440
    property string mode: "idle"
    property real level: 0.5
    property real progress: 0
    property real inputLevel: 0      // for "listening" (microphone, later)
    property bool active: true
    property string color: "red"         // red, green, blue, amber, violet
    signal clicked
    signal pressAndHold

    width: size
    height: size

    property real phase: 0
    property real target: 0.6

    Timer {
        interval: 40
        repeat: true
        running: eye.active && eye.visible
        onTriggered: {
            var l;
            if (eye.mode == "thinking") {
                eye.phase += 0.36;
                l = 0.70 + 0.28 * Math.sin(eye.phase);
            } else if (eye.mode == "speaking") {
                if (Math.random() < 0.35)
                    eye.target = 0.45 + Math.random() * 0.55;
                l = eye.level + (eye.target - eye.level) * 0.45;
            } else if (eye.mode == "listening") {
                l = eye.level + (0.35 + 0.65 * eye.inputLevel - eye.level) * 0.5;
            } else {
                eye.phase += 0.063;          // ~4 s per breath
                l = 0.50 + 0.17 * Math.sin(eye.phase);
            }
            eye.level = l;
        }
    }

    // All layers are drawn at the full 440 px and scaled together, so the
    // progress ring stays in place while the eye grows or shrinks.
    Item {
        id: layers
        width: 440
        height: 440
        scale: eye.size / 440
        transformOrigin: Item.TopLeft

    Image {
        anchors.fill: parent
        source: "img/pierscien.png"
        smooth: true
    }
    Image {
        id: glow
        anchors.fill: parent
        source: "img/poswiata-" + eye.color + ".png"
        smooth: true
        opacity: 0.25 + 0.75 * eye.level
        scale: 0.88 + 0.14 * eye.level
    }
    Image {
        anchors.fill: parent
        source: "img/rdzen-" + eye.color + ".png"
        smooth: true
        opacity: 0.55 + 0.45 * eye.level
        scale: 0.95 + 0.1 * eye.level
    }

    // progress arc: two clipped halves of a rotated half ring
    Item {
        id: arc
        anchors.fill: parent
        visible: eye.progress > 0.001
        Item {          // right half: 0 .. 50%
            x: 220
            width: 220
            height: 440
            clip: true
            Image {
                x: -220
                width: 440
                height: 440
                source: "img/postep-" + eye.color + ".png"
                smooth: true
                rotation: -180 + 360 * Math.min(eye.progress, 0.5)
            }
        }
        Item {          // left half: 50 .. 100%
            width: 220
            height: 440
            clip: true
            Image {
                width: 440
                height: 440
                source: "img/postep-" + eye.color + ".png"
                smooth: true
                rotation: 360 * Math.max(eye.progress - 0.5, 0)
            }
        }
    }

    Image {
        anchors.fill: parent
        source: "img/odblaski.png"
        smooth: true
    }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: eye.clicked()
        onPressAndHold: eye.pressAndHold()
    }
}
