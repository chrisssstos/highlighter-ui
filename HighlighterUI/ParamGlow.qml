import QtQuick

/// The glow round something lit in the hardware skin, as on a backlit
/// display: a few soft halos in its colour, fading out. Put it behind the
/// lit thing (z below it), the same size. Cheap: no blur, no layer.
Item {
    id: glow
    property color color: Theme.accent
    //! 0..1: how bright.
    property real strength: 1
    //! The lit thing's corner radius.
    property real radius: Theme.radius
    visible: Theme.hardware && strength > 0

    Repeater {
        model: [{ out: 2, a: 0.32 }, { out: 5, a: 0.14 }, { out: 9, a: 0.06 }]
        Rectangle {
            required property var modelData
            anchors.fill: parent
            anchors.margins: -Theme.s(modelData.out)
            radius: glow.radius + Theme.s(modelData.out)
            antialiasing: true
            color: glow.color
            opacity: modelData.a * glow.strength
        }
    }
}
