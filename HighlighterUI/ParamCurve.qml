import QtQuick
import QtQuick.Shapes
import "ParamMath.js" as PM

/// A curve the user shapes: how a value goes from start to end over a move
/// (an easing, a motor's run). A raised panel like ParamGraph's, the name in
/// a grey title bar, then a plot of `points` ({ t, v }, both 0..1): time
/// across, the value up. Click to add a point, drag one, double-click one to
/// drop it; the first stays at t 0 and the last at t 1. Double-click an empty
/// spot to go back to `defaultPoints`, if given. `smooth` bends it through
/// the points without overshooting them (valueAt() and ParamMath curveAt()
/// work it out the same way); off, straight lines. `position` (0..1, NaN for
/// none) puts a white line and dot where something following the curve is
/// now. The labels name the ends: `fromLabel` / `toLabel` the value's (bottom,
/// top), `startLabel` / `endLabel` the time's. As a slider, it changes
/// itself and tells you with moved(points); bind `points` to your setting
/// and write it back there.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property string label: ""
    //! The curve: { t, v } each 0..1, t rising; the first at t 0, the last at t 1.
    property var points: [{ t: 0, v: 0 }, { t: 1, v: 1 }]
    //! What a double-click on an empty spot goes back to; [] for nothing.
    property var defaultPoints: []
    property bool smooth: true
    //! Where something following the curve is now, 0..1, or NaN for nothing.
    property real position: NaN
    property string fromLabel: "0"
    property string toLabel: "1"
    property string startLabel: "start"
    property string endLabel: "end"
    //! What the readout shows (a duration, the value now); none if empty.
    property string valueText: ""
    property real plotHeight: Theme.s(120)

    signal moved(var points)

    //! The curve's value at t (0..1).
    function valueAt(t) { return PM.curveAt(root.points, t, root.smooth) }

    function setPoints(p) { root.points = p; root.moved(p) }

    implicitWidth: Theme.s(320)
    implicitHeight: bar.height + plot.height + axis.height + Theme.s(22)

    ParamPlate { anchors.fill: parent }

    // --- the title bar: the name and the readout ----------------------------
    Rectangle {
        id: bar
        width: parent.width
        height: head.height + Theme.s(8)
        radius: Theme.radius * 1.5
        color: Theme.panelBar
        // square under, so only the panel's top corners round
        Rectangle { y: parent.height - Theme.radius * 1.5; width: parent.width; height: Theme.radius * 1.5; visible: Theme.radius > 0; color: Theme.panelBar }
        gradient: Theme.classic ? classicBar : null
        Gradient {
            id: classicBar
            GradientStop { position: 0; color: Qt.lighter(Theme.titleBar, 1.12) }
            GradientStop { position: 0.5; color: Theme.titleBar }
            GradientStop { position: 1; color: Theme.titleBarEnd }
        }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.3) }
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius * 1.5
        color: "transparent"
        border.width: 1
        border.color: Theme.panelEdge
        visible: !Theme.classic
    }

    Item {
        id: head
        x: Theme.s(10); y: Theme.s(4)
        width: parent.width - x - Theme.s(4)
        height: Math.max(name.implicitHeight, readout.height)
        Text {
            id: name
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (readout.visible ? readout.width : 0) - Theme.s(8)
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: Theme.titleSize
            style: Theme.titleStyle; styleColor: Theme.titleStyleColor
        }
        Rectangle {
            id: readout
            visible: root.valueText !== ""
            anchors.right: parent.right
            width: Math.max(Theme.s(72), reading.implicitWidth + Theme.s(12))
            height: reading.implicitHeight + Theme.s(4)
            radius: Theme.radius
            color: Theme.hardware ? Theme.screenFill : Theme.sunken
            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.12; dark: 0.45 }
            Text {
                id: reading
                anchors.right: parent.right; anchors.rightMargin: Theme.s(6)
                anchors.verticalCenter: parent.verticalCenter
                text: root.valueText
                color: root.tint
                font.family: Theme.family
                font.pixelSize: Theme.valueSize
                font.features: { "tnum": 1 }
            }
        }
    }

    // --- the value's ends, left of the plot ---------------------------------
    Item {
        id: scale
        x: Theme.s(10); y: plot.y
        width: Math.max(top.implicitWidth, bottom.implicitWidth)
        height: plot.height
        Text { id: top; anchors.right: parent.right; y: plot.pad - implicitHeight / 2; text: root.toLabel; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { id: bottom; anchors.right: parent.right; y: parent.height - plot.pad - implicitHeight / 2; text: root.fromLabel; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
    }

    // --- the plot ------------------------------------------------------------
    Rectangle {
        id: plot
        x: scale.x + scale.width + Theme.s(6)
        y: bar.height + Theme.s(12)
        width: parent.width - x - Theme.s(10)
        height: root.plotHeight
        color: Theme.screenFill
        radius: Theme.radius
        clip: true
        ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }

        readonly property real pad: Theme.s(6)
        function xOf(t) { return t * plot.width }
        function yOf(v) { return plot.pad + (1 - v) * (plot.height - 2 * plot.pad) }
        function tAt(x) { return PM.clamp(x / Math.max(1, plot.width), 0, 1) }
        function vAt(y) { return PM.clamp(1 - (y - plot.pad) / Math.max(1, plot.height - 2 * plot.pad), 0, 1) }
        function at(p) { return Qt.point(plot.xOf(p.t), plot.yOf(p.v)) }

        // the value's ends, and a fine grid between
        Rectangle { y: Math.round(plot.pad); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.35) }
        Rectangle { y: Math.round(plot.height - plot.pad); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.35) }
        Repeater {
            model: 3
            Rectangle { required property int index; y: Math.round(plot.pad + (index + 1) * (plot.height - 2 * plot.pad) / 4); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, index === 1 ? 0.2 : 0.1) }
        }
        Repeater {
            model: 9
            Rectangle { required property int index; x: Math.round((index + 1) * plot.width / 10); width: 1; height: plot.height; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.1) }
        }

        // the curve, sampled across the plot
        Shape {
            id: curve
            anchors.fill: parent
            layer.enabled: Theme.glow && root.enabled
            layer.effect: ParamGlow { w: curve.width; h: curve.height; thick: Theme.s(1.5); glowColor: root.tint }
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeColor: Theme.litOf(root.tint); strokeWidth: Theme.s(1.5)
                fillColor: "transparent"; joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    path: {
                        const out = [], n = Math.max(2, Math.round(plot.width / 3))
                        for (let i = 0; i <= n; i++) {
                            const t = i / n
                            out.push(Qt.point(plot.xOf(t), plot.yOf(PM.curveAt(root.points, t, root.smooth))))
                        }
                        return out
                    }
                }
            }
        }

        // now: a white line at the position, and a dot on the curve
        Rectangle {
            visible: !isNaN(root.position)
            x: Math.round(PM.clamp(plot.xOf(root.position) - width / 2, 0, plot.width - width))
            width: Theme.s(2); height: plot.height
            color: Theme.screenText
        }
        Rectangle {
            readonly property real size: Theme.s(6)
            visible: !isNaN(root.position)
            x: Math.round(plot.xOf(PM.clamp(root.position, 0, 1)) - size / 2)
            y: Math.round(plot.yOf(root.valueAt(PM.clamp(root.position, 0, 1))) - size / 2)
            width: size; height: size
            color: Theme.screenText
            border.width: 1; border.color: Theme.screenFill
        }

        // the points
        Repeater {
            model: root.points.length
            Rectangle {
                required property int index
                readonly property real size: Theme.s(7)
                readonly property bool hot: edit.dragging === index || edit.hover === index
                x: Math.round(plot.at(root.points[index]).x - size / 2)
                y: Math.round(plot.at(root.points[index]).y - size / 2)
                width: size; height: size
                color: hot ? root.tint : Theme.sunken
                border.width: Theme.s(1.5); border.color: root.tint
            }
        }

        // click to add a point, drag one, double-click one to drop it, or an
        // empty spot to go back to the defaults
        MouseArea {
            id: edit
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            cursorShape: dragging >= 0 ? Qt.ClosedHandCursor : hover >= 0 ? Qt.OpenHandCursor : Qt.CrossCursor
            property int dragging: -1
            readonly property int hover: containsMouse && dragging < 0 ? nearest(mouseX, mouseY) : -1
            function nearest(mx, my) {
                const p = root.points, reach = Theme.s(8)
                let best = -1, bestD = reach * reach
                for (let i = 0; i < p.length; i++) {
                    const q = plot.at(p[i]), dx = q.x - mx, dy = q.y - my, d = dx * dx + dy * dy
                    if (d <= bestD) { best = i; bestD = d }
                }
                return best
            }
            function place(i, mx, my) {
                const p = root.points.slice(), last = p.length - 1, gap = 0.01
                let t = plot.tAt(mx)
                if (i === 0) t = 0
                else if (i === last) t = 1
                else t = PM.clamp(t, p[i - 1].t + gap, p[i + 1].t - gap)
                p[i] = { t: t, v: plot.vAt(my) }
                root.setPoints(p)
            }
            onPressed: m => {
                let i = nearest(m.x, m.y)
                if (i < 0) {
                    const t = plot.tAt(m.x), p = root.points.slice()
                    i = p.findIndex(q => q.t > t)
                    if (i <= 0) i = p.length - 1
                    p.splice(i, 0, { t: t, v: plot.vAt(m.y) })
                    root.points = p
                }
                dragging = i
                place(i, m.x, m.y)
            }
            onPositionChanged: m => { if (dragging >= 0) place(dragging, m.x, m.y) }
            onReleased: dragging = -1
            onDoubleClicked: m => {
                const i = nearest(m.x, m.y), p = root.points.slice()
                if (i > 0 && i < p.length - 1) { p.splice(i, 1); root.setPoints(p) }
                else if (i < 0 && root.defaultPoints.length >= 2) root.setPoints(root.defaultPoints.slice())
            }
        }
    }

    // --- the time's ends, under the plot -----------------------------------
    Item {
        id: axis
        x: plot.x; y: plot.y + plot.height + Theme.s(3)
        width: plot.width
        height: startText.implicitHeight
        Text { id: startText; text: root.startLabel; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
        Text { anchors.right: parent.right; text: root.endLabel; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize }
    }
}
