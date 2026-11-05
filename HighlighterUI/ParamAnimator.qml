import QtQuick
import QtQuick.Shapes
import "ParamMath.js" as PM

/// Animates a value between two ends, as a clip's parameter in a VJ app
/// does: a strip lined up with the control's bar, with a handle at each
/// end of the range it sweeps (drag one, or the range between them) and a
/// white playhead at the value, as on the bar above. The pencil opens a
/// graph under it of the envelope: time across, the value up, its top and
/// bottom the range's two values (labelled), a white line at the time it's
/// at. With `editing` on, the graph takes clicks: add a point, drag one,
/// double-click one to drop it (no button for it yet). Under it, back / pause / play, how long one pass
/// takes (type it, or Up / Down), and the mode: loop, bounce (the pass
/// forward, then back), play once and hold. A ParamSlider opens one from its animate mark; it sets the value
/// through swept(v), as the user would, so the app sees moved(). It sweeps
/// smoothly, between steps too (23.4 px, not 23 then 24); only the range's
/// ends snap to the control's step.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    //! The control's scale, for lining the strip up with its bar.
    property real from: 0
    property real to: 1
    property real stepSize: 0
    //! The control's value now (where "once" goes back to).
    property real value: 0
    //! The strip's width: the control's bar, so the range lines up under it.
    property real stripWidth: width
    //! The graph is open under the strip (the pencil flips it); on its own,
    //! not tied to the control being minimised or maximised.
    property bool expanded: false

    //! The range it sweeps, in the control's units.
    property real rangeFrom: from + (to - from) * 0.25
    property real rangeTo: from + (to - from) * 0.75
    //! The envelope: points { t, v }, t the time through a pass (0..1) and
    //! v how far from rangeFrom to rangeTo (0..1). The first point is at
    //! t 0 and the last at t 1; straight lines between them.
    property var points: [{ t: 0, v: 0 }, { t: 1, v: 1 }]
    //! "loop", "bounce", "hold" (plays once, stays at the end); "once" (plays
    //! once, then back to the start) still plays but has no button.
    property string mode: "loop"
    readonly property var modes: ["loop", "bounce", "hold"]
    //! Seconds for one pass.
    property real duration: 2
    property bool playing: false
    //! 1 forward, -1 back.
    property int direction: 1
    //! Where in the pass it is, 0..1.
    property real phase: 0
    //! The graph takes clicks, to edit the envelope (no button for it yet).
    property bool editing: false

    signal swept(real v)

    function span() { return root.to - root.from }
    function frac(v) { return root.to === root.from ? 0 : PM.clamp((v - root.from) / root.span(), 0, 1) }
    function snap(v) { return root.stepSize > 0 ? PM.snap(v, root.stepSize, root.from) : v }
    //! How far through the range the envelope is at time t, 0..1.
    function envelope(t) {
        const p = root.points
        if (!p.length) return t
        if (t <= p[0].t) return p[0].v
        for (let i = 1; i < p.length; i++) {
            if (t <= p[i].t) {
                const a = p[i - 1], b = p[i]
                return b.t === a.t ? b.v : a.v + (b.v - a.v) * (t - a.t) / (b.t - a.t)
            }
        }
        return p[p.length - 1].v
    }
    function valueAt(t) { return root.rangeFrom + root.envelope(t) * (root.rangeTo - root.rangeFrom) }

    property real startValue: 0
    // a bounce's way through the pass: 1 forward, -1 back
    property int bounceWay: 1
    //! Plays in a direction, from the start again if a "once" had finished.
    function play(dir) {
        const once = root.mode === "once" || root.mode === "hold"
        if (!root.playing) {
            root.startValue = root.value
            if (once && ((dir > 0 && root.phase >= 1) || (dir < 0 && root.phase <= 0))) root.phase = dir > 0 ? 0 : 1
        }
        root.direction = dir
        root.playing = true
    }
    function pause() { root.playing = false }

    FrameAnimation {
        running: root.playing && root.visible
        onTriggered: {
            const d = frameTime / Math.max(0.05, root.duration)
            let p = root.phase
            if (root.mode === "loop") {
                p += root.direction * d
                p -= Math.floor(p)
            } else if (root.mode === "bounce") {
                p += root.direction * root.bounceWay * d
                if (p > 1) { p = 2 - p; root.bounceWay = -root.bounceWay }
                else if (p < 0) { p = -p; root.bounceWay = -root.bounceWay }
            } else {
                p += root.direction * d
                if (p >= 1 || p <= 0) {
                    // a single pass is done: hold the end, or go back to where it started
                    p = PM.clamp(p, 0, 1)
                    root.phase = p
                    root.playing = false
                    root.swept(root.mode === "hold" ? root.valueAt(p) : root.startValue)
                    return
                }
            }
            root.phase = p
            root.swept(root.valueAt(p))
        }
    }

    readonly property int buttonH: Theme.c(24, 20)
    //! The control's decimals and unit, for the graph's value labels.
    property int decimals: 0
    property string unit: ""
    //! The graph shows under the strip.
    readonly property bool graphed: root.expanded || root.editing
    implicitWidth: Theme.s(320)
    implicitHeight: strip.height + (graph.visible ? Theme.s(4) + graph.height : 0) + Theme.s(6) + controls.height

    // --- the strip: the range under the bar ------------------------------------------
    Rectangle {
        id: strip
        width: root.stripWidth
        height: Theme.s(12)
        radius: Theme.radius
        color: Theme.well

        readonly property real ax: Math.round(strip.width * root.frac(Math.min(root.rangeFrom, root.rangeTo)))
        readonly property real bx: Math.round(strip.width * root.frac(Math.max(root.rangeFrom, root.rangeTo)))
        readonly property real handleW: Theme.s(4)

        Rectangle {
            id: box
            x: strip.ax; width: Math.max(1, strip.bx - strip.ax); height: strip.height
            radius: Theme.radius
            color: Theme.screenMarked(root.tint)
            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }
            Repeater {
                model: 3
                Rectangle { required property int index; x: Math.round((index + 1) * box.width / 4); width: 1; height: box.height; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.12) }
            }
            // the playhead: at the value, so it stays under the bar's edge
            Rectangle {
                readonly property real vx: strip.width * root.frac(root.value) - box.x
                visible: root.value >= Math.min(root.rangeFrom, root.rangeTo) - root.stepSize / 2
                         && root.value <= Math.max(root.rangeFrom, root.rangeTo) + root.stepSize / 2
                // kept clear of the handles at the ends
                x: Math.round(PM.clamp(vx - width / 2, strip.handleW, box.width - strip.handleW - width))
                width: Theme.s(2); height: box.height
                color: Theme.screenText
            }
        }
        // drag the range itself to move it
        MouseArea {
            x: box.x + strip.handleW; width: Math.max(0, box.width - 2 * strip.handleW); height: strip.height
            enabled: root.enabled
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            property real startX: 0
            property real a: 0
            property real b: 0
            onPressed: m => { startX = mapToItem(strip, m.x, 0).x; a = root.rangeFrom; b = root.rangeTo }
            onPositionChanged: m => {
                let d = (mapToItem(strip, m.x, 0).x - startX) / strip.width * root.span()
                const lo = Math.min(a, b), hi = Math.max(a, b)
                d = PM.clamp(d, root.from - lo, root.to - hi)
                root.rangeFrom = root.snap(a + d); root.rangeTo = root.snap(b + d)
            }
        }
        // a handle at each end: drag to move that end
        Repeater {
            model: 2
            Rectangle {
                id: handle
                required property int index
                readonly property bool isFrom: index === 0
                readonly property real at: Math.round(strip.width * root.frac(isFrom ? root.rangeFrom : root.rangeTo))
                // sits just inside the range at either end
                readonly property bool leftEnd: (isFrom ? root.rangeFrom : root.rangeTo) <= (isFrom ? root.rangeTo : root.rangeFrom)
                x: leftEnd ? at : at - width
                width: strip.handleW; height: strip.height
                color: drag.pressed || drag.containsMouse ? root.tint : Theme.edgeOf(root.tint)
                MouseArea {
                    id: drag
                    anchors.fill: parent; anchors.margins: -Theme.s(4)
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor
                    onPositionChanged: m => {
                        if (!pressed) return
                        const x = mapToItem(strip, m.x, 0).x
                        const v = root.snap(PM.clamp(root.from + x / strip.width * root.span(), root.from, root.to))
                        if (handle.isFrom) root.rangeFrom = v; else root.rangeTo = v
                    }
                }
            }
        }
    }

    // --- the graph: time across, the value up (the pencil opens it) ----------------------------
    Item {
        id: graph
        visible: root.graphed
        y: strip.height + Theme.s(4)
        width: root.stripWidth
        height: Theme.s(120)

        readonly property real lo: Math.min(root.rangeFrom, root.rangeTo)
        readonly property real hi: Math.max(root.rangeFrom, root.rangeTo)
        function label(v) { return PM.format(v, root.decimals) + root.unit }

        // the range's two values, at the top and bottom of the graph
        Item {
            id: scale
            width: Math.max(topLabel.implicitWidth, bottomLabel.implicitWidth)
            height: plot.height
            Text { id: topLabel; anchors.right: parent.right; y: plot.pad - implicitHeight / 2; text: graph.label(graph.hi); color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize; font.features: { "tnum": 1 } }
            Text { id: bottomLabel; anchors.right: parent.right; y: plot.height - plot.pad - implicitHeight / 2; text: graph.label(graph.lo); color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize; font.features: { "tnum": 1 } }
        }

        Rectangle {
            id: plot
            x: scale.width + Theme.s(6)
            width: graph.width - x; height: graph.height
            color: Theme.screenFill
            radius: Theme.radius
            clip: true
            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }

            readonly property real pad: Theme.s(5)
            // where a time is (across) and a value (up, the range's top at the top)
            function xOf(t) { return t * plot.width }
            function yOf(val) { return graph.hi === graph.lo ? plot.height / 2 : plot.pad + (graph.hi - val) / (graph.hi - graph.lo) * (plot.height - 2 * plot.pad) }
            function tAt(x) { return PM.clamp(x / Math.max(1, plot.width), 0, 1) }
            // the envelope's v (0 at rangeFrom, 1 at rangeTo) at a height
            function vAt(y) {
                const r = root.rangeTo - root.rangeFrom
                const val = graph.hi - (y - plot.pad) / Math.max(1, plot.height - 2 * plot.pad) * (graph.hi - graph.lo)
                return r === 0 ? 0 : PM.clamp((val - root.rangeFrom) / r, 0, 1)
            }
            function at(p) { return Qt.point(plot.xOf(p.t), plot.yOf(root.rangeFrom + p.v * (root.rangeTo - root.rangeFrom))) }

            // the range's top and bottom: the lines its peaks reach
            Rectangle { y: Math.round(plot.pad); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.35) }
            Rectangle { y: Math.round(plot.height - plot.pad); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.35) }
            // a fine grid between
            Repeater {
                model: 3
                Rectangle { required property int index; y: Math.round(plot.pad + (index + 1) * (plot.height - 2 * plot.pad) / 4); width: plot.width; height: 1; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.1) }
            }
            Repeater {
                model: 7
                Rectangle { required property int index; x: Math.round((index + 1) * plot.width / 8); width: 1; height: plot.height; color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.1) }
            }
            // the envelope
            Shape {
                id: curve
                anchors.fill: parent
                layer.enabled: Theme.glow && root.enabled
                layer.effect: ParamGlow { w: curve.width; h: curve.height; thick: Theme.s(1.5); glowColor: root.tint }
                preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
                antialiasing: Theme.smooth
                ShapePath {
                    strokeColor: Theme.litOf(root.tint); strokeWidth: Theme.s(1.5)
                    fillColor: "transparent"; joinStyle: ShapePath.MiterJoin
                    PathPolyline { path: root.points.map(p => plot.at(p)) }
                }
            }
            // now: a white line at the time it's at, and a dot at its value
            Rectangle {
                x: Math.round(PM.clamp(plot.xOf(root.phase) - width / 2, 0, plot.width - width))
                width: Theme.s(2); height: plot.height
                color: Theme.screenText
            }
            Rectangle {
                readonly property real size: Theme.s(6)
                x: Math.round(plot.xOf(PM.clamp(root.phase, 0, 1)) - size / 2)
                y: Math.round(plot.yOf(root.valueAt(PM.clamp(root.phase, 0, 1))) - size / 2)
                width: size; height: size
                color: Theme.screenText
                border.width: 1; border.color: Theme.screenFill
            }
            // the envelope's points, while editing
            Repeater {
                model: root.editing ? root.points.length : 0
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
            // editing: click to add a point, drag one, double-click one to drop it
            MouseArea {
                id: edit
                anchors.fill: parent
                enabled: root.enabled && root.editing
                hoverEnabled: true
                // a drag here moves the point, never the page under it
                preventStealing: true
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
                    // the ends stay at the pass's start and end; the others between their neighbours
                    if (i === 0) t = 0
                    else if (i === last) t = 1
                    else t = PM.clamp(t, p[i - 1].t + gap, p[i + 1].t - gap)
                    p[i] = { t: t, v: plot.vAt(my) }
                    root.points = p
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
                    if (i > 0 && i < p.length - 1) { p.splice(i, 1); root.points = p }
                }
            }
        }
    }

    // --- the controls ------------------------------------------------------------
    Flow {
        id: controls
        y: (graph.visible ? graph.y + graph.height : strip.height) + Theme.s(6)
        width: root.width
        spacing: Theme.s(10)

        // back / pause / play
        Row {
            spacing: 1
            ParamButton {
                icon: "back"; accent: root.playing && root.direction < 0
                implicitHeight: root.buttonH; horizontalPadding: Theme.s(9)
                onClicked: root.play(-1)
            }
            ParamButton {
                icon: "pause"
                implicitHeight: root.buttonH; horizontalPadding: Theme.s(9)
                onClicked: root.pause()
            }
            ParamButton {
                icon: "play"; accent: root.playing && root.direction > 0
                implicitHeight: root.buttonH; horizontalPadding: Theme.s(9)
                onClicked: root.play(1)
            }
        }

        // how long one pass takes (centred on the buttons' row)
        Row {
            height: root.buttonH
            ParamValueBox {
                anchors.verticalCenter: parent.verticalCenter
                value: root.duration
                decimals: root.duration < 1 ? 2 : root.duration < 10 ? 1 : 0
                unit: " s"
                interactive: root.enabled
                onSubmitted: v => root.duration = PM.clamp(v, 0.05, 3600)
                onStepped: (d, big) => root.duration = PM.clamp(root.duration * Math.pow(big ? 2 : 1.1, d), 0.05, 3600)
            }
        }

        // the mode
        Row {
            spacing: 1
            Repeater {
                model: root.modes
                ParamButton {
                    required property string modelData
                    icon: modelData
                    accent: root.mode === modelData
                    implicitHeight: root.buttonH; horizontalPadding: Theme.s(9)
                    onClicked: root.mode = modelData
                }
            }
        }

        // the pencil: opens the graph
        ParamButton {
            icon: "pencil"
            accent: root.expanded
            implicitHeight: root.buttonH; horizontalPadding: Theme.s(9)
            onClicked: root.expanded = !root.expanded
        }
    }
}
