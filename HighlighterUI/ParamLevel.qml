import QtQuick
import "ParamMath.js" as PM

/// A read-only vertical level in segments, with a peak mark that falls back
/// slowly: a sound's loudness, a channel's signal. Sit several side by
/// side (a Row) for a mix. Segments past warnAt light red.
Item {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    //! Where segments turn red; NaN for never.
    property real warnAt: NaN
    property int segments: 16
    property int barWidth: Theme.s(14)
    property int barHeight: Theme.s(110)

    implicitWidth: Math.max(barWidth, name.implicitWidth)
    implicitHeight: barHeight + Theme.s(6) + name.implicitHeight

    function fraction(v) { return to === from ? 0 : PM.clamp((v - from) / (to - from), 0, 1) }

    property real peak: 0
    onValueChanged: if (fraction(value) >= peak) { decay.stop(); peak = fraction(value); hold.restart() }
    Timer { id: hold; interval: 700; onTriggered: decay.start() }
    NumberAnimation { id: decay; target: root; property: "peak"; to: 0; duration: 1200; easing.type: Easing.InQuad }

    Column {
        id: bar
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.barWidth
        height: root.barHeight
        spacing: Theme.s(2)
        readonly property real cell: (height - (root.segments - 1) * spacing) / root.segments
        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                // drawn top down: the top cell is the loudest
                readonly property real level: (root.segments - index) / root.segments
                readonly property bool lit: root.fraction(root.value) >= level - 0.5 / root.segments
                readonly property bool hot: !isNaN(root.warnAt) && level > root.fraction(root.warnAt)
                readonly property bool isPeak: Math.abs(root.peak - level) < 0.5 / root.segments
                width: bar.width
                height: bar.cell
                color: lit || isPeak ? Theme.litOf(hot ? Theme.danger : root.tint) : Theme.sunken
                opacity: isPeak && !lit ? 0.7 : 1
                ParamGlow { anchors.fill: parent; z: -1; color: parent.hot ? Theme.danger : root.tint; strength: parent.lit ? 0.5 : 0 }
            }
        }
    }
    Text {
        id: name
        anchors.horizontalCenter: parent.horizontalCenter
        y: bar.height + Theme.s(6)
        text: root.label
        color: Theme.textDim
        font.family: Theme.family
        font.pixelSize: Theme.smallSize
    }
}
