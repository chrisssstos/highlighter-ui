import QtQuick
import "ParamMath.js" as PM

/// A read-only bar for a live value (a level, fps, the guess right now),
/// with a peak mark that falls back slowly.
Item {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property int decimals: 2
    property string unit: ""
    property bool showPeak: true

    implicitWidth: Theme.s(280)
    implicitHeight: head.implicitHeight + Theme.rowGap + bar.height

    function fraction(v) { return to === from ? 0 : PM.clamp((v - from) / (to - from), 0, 1) }

    property real peak: 0
    onValueChanged: if (fraction(value) >= peak) { peak = fraction(value); fall.restart() }
    Timer { id: fall; interval: 700; onTriggered: decay.start() }
    NumberAnimation { id: decay; target: root; property: "peak"; to: 0; duration: 1200; easing.type: Easing.InQuad }

    Item {
        id: head
        width: parent.width
        implicitHeight: name.implicitHeight
        Text {
            id: name
            width: parent.width - reading.width - Theme.s(8)
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
        }
        Text {
            id: reading
            anchors.right: parent.right
            text: PM.format(root.value, root.decimals) + root.unit
            color: root.tint
            font.family: Theme.family
            font.pixelSize: Theme.valueSize
            font.features: { "tnum": 1 }
        }
    }
    Rectangle {
        id: bar
        y: head.height + Theme.rowGap
        width: parent.width
        height: Theme.s(6)
        color: Theme.sunken
        Rectangle {
            width: parent.width * root.fraction(root.value); height: parent.height
            color: Theme.litOf(root.tint)
            ParamGlow { anchors.fill: parent; z: -1; color: root.tint; strength: parent.width > 0 && root.enabled ? 0.6 : 0 }
        }
        Rectangle {
            visible: root.showPeak && root.peak > 0
            x: Math.min(parent.width - width, parent.width * root.peak)
            width: Theme.s(2); height: parent.height
            color: Theme.text
        }
    }
}
