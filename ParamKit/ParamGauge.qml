import QtQuick
import "ParamMath.js" as PM

/// A read-only half-dial for one live value that has a safe range and a too
/// much: load, temperature, speed. Past warnAt the arc turns red. For a
/// value the user sets, use a slider or knob instead.
Item {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property int decimals: 2
    property string unit: ""
    //! Where the arc turns red; NaN for never.
    property real warnAt: NaN
    property int ticks: 6
    property int diameter: Theme.s(110)

    implicitWidth: Math.max(diameter + Theme.s(16), title.implicitWidth)
    implicitHeight: title.height + Theme.rowGap + dial.height + reading.implicitHeight

    function fraction(v) { return to === from ? 0 : PM.clamp((v - from) / (to - from), 0, 1) }
    readonly property bool warning: !isNaN(warnAt) && value >= warnAt

    property real shown: value
    Behavior on shown { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
    onShownChanged: dial.requestPaint()
    onWarningChanged: dial.requestPaint()
    Connections { target: Theme; function onScaleChanged() { dial.requestPaint() } function onAccentChanged() { dial.requestPaint() } }

    Text {
        id: title
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.titleSize
        height: text.length ? implicitHeight : 0
    }

    Canvas {
        id: dial
        anchors.horizontalCenter: parent.horizontalCenter
        y: title.height + Theme.rowGap
        width: root.diameter + Theme.s(16)
        height: root.diameter / 2 + Theme.s(10)
        antialiasing: true
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height - Theme.s(4)
            const R = root.diameter / 2, ring = Theme.s(7)
            const at = f => Math.PI + Math.PI * f
            ctx.lineWidth = ring
            ctx.strokeStyle = Theme.sunken
            ctx.beginPath(); ctx.arc(cx, cy, R - ring / 2, Math.PI, 2 * Math.PI); ctx.stroke()
            // the warning stretch, faintly, so you can see it coming
            if (!isNaN(root.warnAt)) {
                ctx.strokeStyle = Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.3)
                ctx.beginPath(); ctx.arc(cx, cy, R - ring / 2, at(root.fraction(root.warnAt)), 2 * Math.PI); ctx.stroke()
            }
            const f = root.fraction(root.shown)
            ctx.strokeStyle = root.warning ? Theme.danger : Theme.accent
            if (f > 0) { ctx.beginPath(); ctx.arc(cx, cy, R - ring / 2, Math.PI, at(f)); ctx.stroke() }
            // ticks
            ctx.strokeStyle = Theme.textFaint
            ctx.lineWidth = 1
            for (let i = 0; i < root.ticks; ++i) {
                const a = at(i / (root.ticks - 1))
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * (R - ring - Theme.s(2)), cy + Math.sin(a) * (R - ring - Theme.s(2)))
                ctx.lineTo(cx + Math.cos(a) * (R - ring - Theme.s(6)), cy + Math.sin(a) * (R - ring - Theme.s(6)))
                ctx.stroke()
            }
            // the needle
            const a = at(f)
            ctx.strokeStyle = Theme.text
            ctx.lineWidth = Theme.s(2)
            ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(a) * (R - ring - Theme.s(4)), cy + Math.sin(a) * (R - ring - Theme.s(4))); ctx.stroke()
            ctx.fillStyle = Theme.text
            ctx.beginPath(); ctx.arc(cx, cy, Theme.s(4), 0, 2 * Math.PI); ctx.fill()
        }
    }

    Text {
        id: reading
        anchors.horizontalCenter: parent.horizontalCenter
        y: dial.y + dial.height + Theme.s(2)
        text: PM.format(root.value, root.decimals) + root.unit
        color: root.warning ? Theme.danger : Theme.accent
        font.family: Theme.family
        font.pixelSize: Theme.valueSize
    }
}
