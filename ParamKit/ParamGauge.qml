import QtQuick
import QtQuick.Shapes
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

    // Drawn as shapes, so Theme.smooth can turn the antialiasing off.
    Shape {
        id: dial
        anchors.horizontalCenter: parent.horizontalCenter
        y: title.height + Theme.rowGap
        width: root.diameter + Theme.s(16)
        height: root.diameter / 2 + Theme.s(10)
        preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
        antialiasing: Theme.smooth
        readonly property real cx: width / 2
        readonly property real cy: height - Theme.s(4)
        readonly property real outer: root.diameter / 2
        readonly property real ring: Theme.s(7)
        readonly property real f: root.fraction(root.shown)
        readonly property real fw: isNaN(root.warnAt) ? 1 : root.fraction(root.warnAt)
        function rad(f) { return Math.PI + Math.PI * f }
        readonly property var tickLines: {
            const out = []
            for (let i = 0; i < root.ticks && root.ticks > 1; ++i) {
                const a = rad(i / (root.ticks - 1))
                const r1 = outer - ring - Theme.s(2), r2 = outer - ring - Theme.s(6)
                out.push([Qt.point(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1),
                          Qt.point(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)])
            }
            return out
        }
        readonly property real needle: outer - ring - Theme.s(4)

        ShapePath {   // the track
            strokeColor: Theme.sunken; strokeWidth: dial.ring; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: dial.cx; centerY: dial.cy; radiusX: dial.outer - dial.ring / 2; radiusY: radiusX; startAngle: 180; sweepAngle: 180 }
        }
        ShapePath {   // the warning stretch, faintly, so you can see it coming
            strokeColor: isNaN(root.warnAt) ? "transparent" : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.3)
            strokeWidth: dial.ring; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: dial.cx; centerY: dial.cy; radiusX: dial.outer - dial.ring / 2; radiusY: radiusX
                           startAngle: 180 + 180 * dial.fw; sweepAngle: 180 * (1 - dial.fw) }
        }
        ShapePath {   // the value
            strokeColor: dial.f <= 0 ? "transparent" : root.warning ? Theme.danger : Theme.accent
            strokeWidth: dial.ring; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc { centerX: dial.cx; centerY: dial.cy; radiusX: dial.outer - dial.ring / 2; radiusY: radiusX; startAngle: 180; sweepAngle: 180 * dial.f }
        }
        ShapePath {   // ticks
            strokeColor: Theme.textFaint; strokeWidth: 1; fillColor: "transparent"
            PathMultiline { paths: dial.tickLines }
        }
        ShapePath {   // the needle
            strokeColor: Theme.text; strokeWidth: Theme.s(2); fillColor: "transparent"
            startX: dial.cx; startY: dial.cy
            PathLine { x: dial.cx + Math.cos(dial.rad(dial.f)) * dial.needle; y: dial.cy + Math.sin(dial.rad(dial.f)) * dial.needle }
        }
        ShapePath {   // its hub
            strokeColor: "transparent"; fillColor: Theme.text
            PathAngleArc { centerX: dial.cx; centerY: dial.cy; radiusX: Theme.s(4); radiusY: Theme.s(4); startAngle: 0; sweepAngle: 360 }
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
